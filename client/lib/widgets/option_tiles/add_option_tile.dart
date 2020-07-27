import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddOptionTile extends StatelessWidget {
  final bool wouldBeFirstOption;
  final void Function() onAddOption;

  AddOptionTile({
    this.onAddOption,
    this.wouldBeFirstOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(height: double.infinity, child: Icon(Icons.add, size: 40, color: Colors.green)),
      title: Text(wouldBeFirstOption ? 'Add option' : 'Add another option'),
      onTap: onAddOption,
    );
  }
}