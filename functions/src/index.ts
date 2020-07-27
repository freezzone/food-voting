import {https, logger, region} from 'firebase-functions';
import * as admin from 'firebase-admin';
import {Poll, PollOption, PollResult, Vote} from "./model";
import {deleteCollection} from "./delete-collection";

const { HttpsError } = https;
admin.initializeApp();
const inRegion = region('europe-west3');
const db = admin.firestore();

function ensureLoggedUser(context: https.CallableContext) {
  if (!context.auth || !context.auth.uid) {
    throw new HttpsError(
      'unauthenticated',
      'User is not logged'
    );
  }
}

function ensureValidPollId(pollId: any) {
  if (typeof pollId !== 'string' || pollId.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'Argument [pollId] is required',
    );
  }
}

async function getPoll(pollId: string) {
  const pollRef = db.collection('polls').doc(pollId);
  const pollDoc = await pollRef.get();

  if (!pollDoc.exists) {
    throw new HttpsError(
      'not-found',
      'Poll with the given id does not exist'
    );
  }

  const poll = pollDoc.data() as Poll;

  return { poll, pollRef, pollDoc };
}

function isPollOwner(poll: Poll, context: https.CallableContext) {
  return poll.creatorId && poll.creatorId === context?.auth?.uid;
}

function ensurePollOwnership(poll: Poll, context: https.CallableContext) {
  if (!isPollOwner(poll, context)) {
    throw new HttpsError(
      'permission-denied',
      'Access to the poll denied',
    );
  }
}

export const deletePoll = inRegion.https.onCall(async (data, context): Promise<void> => {
  ensureLoggedUser(context);
  const {pollId} = data;
  ensureValidPollId(pollId);
  const { poll, pollRef } = await getPoll(pollId);
  ensurePollOwnership(poll, context);

  // ensure poll is closed, so no data are changing during delete operation
  if (!poll.closed) {
    // closing OUTSIDE of transaction to ensure no more votes will be added during the transaction
    await pollRef.update({
      closed: true,
    });
  }

  await deleteCollection(db, pollRef.collection('options'));
  await deleteCollection(db, pollRef.collection('votes'));
  await pollRef.delete();
});

export const evaluatePoll = inRegion.https.onCall(
  async (data, context): Promise<PollResult | null> => {
    ensureLoggedUser(context);
    const {pollId} = data;
    ensureValidPollId(pollId);
    const { poll, pollRef } = await getPoll(pollId);

    // owner can evaluate poll anytime, other users only if the poll is already ended
    if (!isPollOwner(poll, context) && (!poll.endAt || poll.endAt.toDate().getTime() > Date.now())) {
      throw new HttpsError(
        'failed-precondition',
        'Poll is not ready to be closed yet'
      );
    }

    // evaluation was already done
    if (poll.result) {
      // evaluation was already done
      return poll.result;
    }

    if (!poll.closed) {
      // closing OUTSIDE of transaction to ensure no more votes will be added during the transaction
      await pollRef.update({
        closed: true,
      });
    }

    // no the poll is closed, we can safely load all votes and options
    const optionsById = new Map<String, PollOption>();
    const optionsRef = await pollRef.collection('options').get();
    optionsRef.forEach(optionRef => {
      const option = optionRef.data() as PollOption;
      optionsById.set(optionRef.id, option);
    });

    const validatedVotes: Vote[] = [];
    const votesRef = await pollRef.collection('votes').get();
    votesRef.forEach(voteRef => {
      const vote = voteRef.data() as Vote;

      if (optionsById.has(vote.optionId)) {
        validatedVotes.push(vote);
      }
    });

    try {
      // poll evaluation; transaction return Result object if the poll was already evaluated before, otherwise null
      const previousResult = await db.runTransaction(async (t) => {
        // lock the poll so no other result can be written concurrently
        const pollInTransaction = (await t.get(pollRef)).data() as Poll;

        // evaluation was already done (some concurrent transaction)
        if (pollInTransaction.result) {
          // evaluation was already done
          return pollInTransaction.result;
        }

        const update: any = {
          'result.evaluatedAt': admin.firestore.FieldValue.serverTimestamp(),
        };

        if (validatedVotes.length > 0) {
          const randomIndex = Math.floor(Math.random() * validatedVotes.length);
          const {optionId} = validatedVotes[randomIndex];
          update['result.option.name'] = optionsById.get(optionId)!.name;
        } else {
          update['result.option'] = null;
        }

        t.update(pollRef, update);
        return null;
      });

      if (!previousResult) {
        const updatedPollDoc = await pollRef.get();
        const updatedPoll = updatedPollDoc.data() as Poll;
        return updatedPoll.result || null;
      } else {
        return previousResult;
      }
    } catch (e) {
      logger.error('Evaluate poll unexpected error', e);

      throw new HttpsError(
        'internal',
        'Unexpected error'
      );
    }
  });
