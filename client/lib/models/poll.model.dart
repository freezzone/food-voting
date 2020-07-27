import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_voting_app/models/poll_option.model.dart';
import 'package:food_voting_app/models/poll_in_list.model.dart';
import 'package:food_voting_app/models/vote.model.dart';

class Poll extends PollInList {
  List<PollOption> options;
  List<Vote> votes;

  Poll(): super() {
    options = [];
    votes = [];
  }

  Poll.fromSnapshots({
    @required DocumentSnapshot pollSnapshot,
    @required QuerySnapshot optionsSnapshot,
    @required QuerySnapshot votesSnapshot,
  }) : super.fromSnapshot(pollSnapshot) {
    options = optionsSnapshot.documents.map((option) => PollOption.fromSnapshot(option)).toList();
    votes = votesSnapshot.documents.map((vote) => Vote.fromSnapshot(vote)).toList();
  }
}
