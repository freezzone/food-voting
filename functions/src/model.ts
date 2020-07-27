import * as admin from "firebase-admin";
import Timestamp = admin.firestore.Timestamp;

export interface Poll extends WithCreator {
  closed: boolean,
  endAt: Timestamp,
  result?: PollResult;
}

interface WithCreator {
  creatorName: String;
  creatorId: String;
}

export interface PollOption {
  name: String;
}

export interface Vote extends WithCreator {
  optionId: String;
}

export interface PollResult {
  option: PollOption | null;
  evaluatedAt: Timestamp;
}