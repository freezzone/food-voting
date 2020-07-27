import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_voting_app/models/poll.model.dart';
import 'package:food_voting_app/models/poll_in_list.model.dart';
import 'package:food_voting_app/models/poll_option.model.dart';
import 'package:food_voting_app/models/poll_result.model.dart';
import 'package:food_voting_app/services/cf_client.service.dart';
import 'package:stream_transform/stream_transform.dart';

class PollService {
  final Firestore _db;
  final CfClientService cfClient;

  PollService({this.cfClient}) : _db = Firestore.instance;

  Stream<List<PollInList>> getRecentPolls() {
    var opened =
        _db.collection("polls").where('closed', isEqualTo: false).orderBy('endAt', descending: false).snapshots();

    // closed up to 1 day
    var closedRecently = _db
        .collection("polls")
        .where('result.evaluatedAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))))
        .where('closed', isEqualTo: true)
        .orderBy('result.evaluatedAt', descending: true)
        .limit(20)
        .snapshots();

    return opened
        .combineLatest(closedRecently, (QuerySnapshot a, QuerySnapshot b) => a.documents + b.documents)
        .map((List<DocumentSnapshot> documents) {
      return documents.map((doc) => PollInList.fromSnapshot(doc)).toList();
    });
  }

  Stream<List<PollInList>> getArchivedPolls() {
    var archived = _db
        .collection("polls")
        .where('closed', isEqualTo: true)
        .orderBy('result.evaluatedAt', descending: true)
        .limit(100)
        .snapshots();

    return archived.map((QuerySnapshot snapshot) {
      return snapshot.documents.map((doc) => PollInList.fromSnapshot(doc)).toList();
    });
  }

  Stream<List<PollInList>> getPollsWithNoResult() {
    var missingResult = _db.collection("polls").where('result', isNull: true).snapshots();

    return missingResult.map((QuerySnapshot snapshot) {
      return snapshot.documents.map((doc) => PollInList.fromSnapshot(doc)).toList();
    });
  }

  Stream<Poll> getPoll(String id) {
    var pollStream = _db.collection("polls").document(id).snapshots();
    var votesStream = _db.collection("polls").document(id).collection('votes').snapshots();
    var optionsStream = _db.collection("polls").document(id).collection('options').orderBy('name').snapshots();

    return pollStream.combineLatest(
        optionsStream.combineLatest(
            votesStream, (QuerySnapshot options, QuerySnapshot votes) => {'votes': votes, 'options': options}),
        (poll, childData) {
      if (!poll.exists) {
        return null;
      }
      return Poll.fromSnapshots(
          pollSnapshot: poll, optionsSnapshot: childData['options'], votesSnapshot: childData['votes']);
    });
  }

  Future<Poll> upsertPoll({
    Poll poll,
  }) async {
    var pollRef = _db.collection('polls').document(poll.id);
    await pollRef.setData({
      'name': poll.name,
      'closed': false,
      'result': null,
      'creatorId': poll.creatorId,
      'creatorName': poll.creatorName,
      'endAt': poll.endAt,
    });

    for (var option in poll.options ?? <PollOption>[]) {
      await upsertPollOption(pollId: pollRef.documentID, optionName: option.name);
    }

    return getPoll(pollRef.documentID).first;
  }

  Stream<List<PollOption>> getGlobalOptions() {
    var options = _db.collection("options").orderBy('name').limit(100).snapshots();

    return options.map((QuerySnapshot snapshot) {
      return snapshot.documents.map((doc) => PollOption.fromSnapshot(doc)).toList();
    });
  }

  Future<void> vote({
    String pollId,
    String optionId,
    FirebaseUser user,
  }) {
    return _db.collection("polls").document(pollId).collection('votes').document(user.uid).setData({
      'optionId': optionId,
      'creatorName': user.displayName,
      'creatorId': user.uid,
    });
  }

  Future<void> upsertGlobalOption({
    String optionName,
  }) {
    return _db.collection('options').document(optionName).setData({'name': optionName});
  }

  Future<void> upsertPollOption({
    String pollId,
    String optionName,
  }) {
    return _db
        .collection("polls")
        .document(pollId)
        .collection('options')
        .document(optionName)
        .setData({'name': optionName});
  }

  Future<PollResult> evaluatePoll(String pollId) async {
    var result = await cfClient.evaluatePoll.call({
      'pollId': pollId,
    });
    PollResult pollResult = result.data != null ? PollResult.fromCloudFunctionResult(result.data) : null;
    return pollResult;
  }

  Future<void> deletePoll(String pollId) async {
    await cfClient.deletePoll.call({
      'pollId': pollId,
    });
  }
}
