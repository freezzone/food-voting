import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/widgets/food_voting_app.dart';
import 'package:food_voting_app/widgets/with_providers.dart';

void main() async {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    bool inDebug = false;
    assert(() {
      inDebug = true;
      return true;
    }());
    // In debug mode, use the normal error widget which shows
    // the error message:
    if (inDebug) return ErrorWidget(details.exception);
    // In release builds, show a yellow-on-blue message instead:
    return Container(
      alignment: Alignment.center,
      child: Text(
        'Error!',
        style: TextStyle(color: Colors.yellow),
      ),
    );
  };

  runApp(WithProviders(child: FoodVotingApp()));
}
