import 'package:cloud_firestore/cloud_firestore.dart';

class PollOption {
  String id;
  String name;

  PollOption();

  PollOption.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
  }

  factory PollOption.fromSnapshot(DocumentSnapshot snapshot) {
    return PollOption.fromMap(snapshot.data)..id = snapshot.documentID;
  }

  PollOption clone() {
    return PollOption()
      ..id = id
      ..name = name;
  }
}
