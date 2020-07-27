import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExpandingProgressIndicator extends StatelessWidget {
  final String text;

  ExpandingProgressIndicator({this.text}): super();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(190),
      ),
      child: Theme(
        data: ThemeData(
          cupertinoOverrideTheme: CupertinoThemeData(brightness: Brightness.dark),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (text != null)
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: Text(
                  text,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }
}
