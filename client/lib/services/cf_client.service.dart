import 'package:cloud_functions/cloud_functions.dart';

class CfClientService {
  final CloudFunctions cf;
  final HttpsCallable evaluatePoll;
  final HttpsCallable deletePoll;

  CfClientService({this.cf})
      : evaluatePoll = cf.getHttpsCallable(functionName: 'evaluatePoll'),
        deletePoll = cf.getHttpsCallable(functionName: 'deletePoll');
}
