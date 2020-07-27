import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_voting_app/models/poll_result.model.dart';

class PollInList {
  String id;
  String creatorId;
  String creatorName;
  String name;
  Timestamp endAt;
  bool closed;
  PollResult result;

  PollInList();

  PollInList.fromSnapshot(DocumentSnapshot snapshot) {
    var map = snapshot.data;
    id = snapshot.documentID;
    creatorId = map['creatorId'];
    creatorName = map['creatorName'];
    name = map['name'];
    endAt = map['endAt'];
    closed = map['closed'];
    result = map['result'] != null
        ? PollResult.fromMap(map['result'])
        : null;
  }
}
