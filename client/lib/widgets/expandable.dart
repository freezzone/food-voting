import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Expandable extends StatefulWidget {
  final Widget header;
  final Widget body;

  Expandable({
    @required this.header,
    @required this.body,
  });

  @override
  State<StatefulWidget> createState() {
    return _ExpandableState();
  }
}

class _ExpandableState extends State<Expandable> {
  var expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: widget.body != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.header,
                if (widget.body != null) Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
          ),
        ),
        if (widget.body != null && expanded) widget.body,
      ],
    );
  }
}
