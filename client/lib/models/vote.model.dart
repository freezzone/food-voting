import 'package:cloud_firestore/cloud_firestore.dart';

class Vote {
  String id;
  String creatorId;
  String creatorName;
  String optionId;

  Vote.fromSnapshot(DocumentSnapshot snapshot) {
    var map = snapshot.data;
    id = snapshot.documentID;
    creatorId = map['creatorId'];
    creatorName = map['creatorName'];
    optionId = map['optionId'];
  }
}