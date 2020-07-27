import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_voting_app/models/poll_option.model.dart';

class PollResult {
  PollOption option;
  Timestamp evaluatedAt;

  PollResult();

  PollResult.fromMap(Map<String, dynamic> map) {
    option = map['option'] != null ? PollOption.fromMap(map['option']) : null;
    evaluatedAt = map['evaluatedAt'];
  }

  PollResult.fromCloudFunctionResult(Map<String, dynamic> map) {
    option = map['option'] != null ? PollOption.fromMap(map['option']) : null;
    // Cloud functions send timestamp serialized into json, so need to recreate proper format
    evaluatedAt = map['evaluatedAt'] == null
        ? null
        : Timestamp(
            map['evaluatedAt']['_seconds'],
            map['evaluatedAt']['_nanoseconds'],
          );
  }
}
