import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_voting_app/models/poll_in_list.model.dart';
import 'package:food_voting_app/services/poll.service.dart';

/// Wait [cyclePauseSeconds] after every check
const cyclePauseSeconds = 10;

/// this task is workaround for missing cron operations on free firebase plan
class PollEvaluationTaskService {
  final PollService pollService;

  Future<void> _task;
  bool _shouldStop = false;

  PollEvaluationTaskService({@required this.pollService});

  void start() {
    if (_task == null) {
      _task = _run();
    }
  }

  Future<void> stop() async {
    if (_task != null) {
      if (_shouldStop != true) {
        _shouldStop = true;
        await _task;
        _shouldStop = false;
        _task = null;
      } else {
        // stop functions was already called elsewhere so just wait until the task is finished
        await _task;
      }
    }
  }

  Future<void> _run() async {
    var pollsStream = pollService.getPollsWithNoResult();
    List<PollInList> polls;
    Iterable<PollInList> endedPolls;
    Timer closestEndingTimer;

    /// We have 2 sources of events on which depend polls which are currently ended and needs to be evaluated:
    /// 1) the passage of time: even if there is no change in database, some polls may ended because rge [Poll.endDate]
    /// was reached
    /// 2) database changes: new polls may be added or some poll may be changed so it ends sooner
    var subscription = pollsStream.listen((_polls) {
      closestEndingTimer?.cancel();
      closestEndingTimer = null;
      polls = _polls;

      /// function which will keep updated [endedPolls] based on the passage of time until new update comes from database.
      Function() updateEndedPolls;
      updateEndedPolls = () {
        try {
          // subtracting 5 seconds in case local time is ahead of server time
          var now = Timestamp.fromDate(DateTime.now().add(Duration(seconds: -5)));
          endedPolls = polls.where((PollInList poll) => poll.endAt.compareTo(now) <= 0);

          // determine when is the nearest date when some poll be ready to evaluate, but is not ready now
          var closestEndingPolls = polls.where((PollInList poll) => poll.endAt.compareTo(now) > 0);
          if (closestEndingPolls.length > 0) {
            var closestEndingPoll = closestEndingPolls.reduce((a, b) => a.endAt.compareTo(b.endAt) < 0 ? a : b);
            var timeout = closestEndingPoll.endAt.toDate().difference(now.toDate());
            assert(timeout.isNegative == false);
            closestEndingTimer?.cancel();
            closestEndingTimer = Timer(timeout, updateEndedPolls);
          }
        } catch (e) {
          print('Automatic poll evaluation service warning: unexpected error.');
          print(e);
        }
      };

      updateEndedPolls();
    });

    /// handle current [endedPolls]
    var handled = Set<String>();
    try {
      while (_shouldStop != true) {
        var endedPollsLocal = endedPolls;
        endedPolls = null; // ensures that we will for new update once this batch of polls is processed

        if (endedPollsLocal != null) {
          for (var poll in endedPollsLocal) {
            if (_shouldStop) {
              break;
            }

            // in case there would some issue (eg on backend) and the evaluation would be failing, to ensure that
            // we will try the evaluation only once
            if (handled.contains(poll.id)) {
              continue;
            }

            handled.add(poll.id);
            await pollService.evaluatePoll(poll.id).catchError((e) {
              print('Automatic poll evaluation service warning: error during evaluation of poll id=${poll.id}');
              print(e);
            });
          }
        }

        // to not generate to much load
        await Future.delayed(const Duration(seconds: cyclePauseSeconds));
      }
    } finally {
      if (subscription != null) {
        subscription.cancel();
      }
    }
  }
}
