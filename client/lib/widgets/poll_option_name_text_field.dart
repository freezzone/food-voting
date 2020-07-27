import 'dart:async';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/models/poll_option.model.dart';
import 'package:food_voting_app/services/poll.service.dart';
import 'package:provider/provider.dart';

class PollOptionNameTextField extends StatefulWidget {
  final void Function(String optionaName) onNameChanged;
  final void Function(String optionaName) onSubmitted;
  final InputDecoration decoration;

  PollOptionNameTextField({Key key, this.onNameChanged, this.onSubmitted, this.decoration = const InputDecoration()}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PollOptionNameTextField();
  }
}

class _PollOptionNameTextField extends State<PollOptionNameTextField> {
  GlobalKey<AutoCompleteTextFieldState<String>> _inputKey = new GlobalKey();
  StreamSubscription _subscription;
  List<String> _suggestions;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final pollService = context.read<PollService>();
    _subscription = pollService.getGlobalOptions().listen(this._updateSuggestions);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // we have to address 2 issues here with the [SimpleAutoCompleteTextField] widget:
    // 1) it doesn't propagate changes of [decoration] value, therefore it is needed to update it manually
    // 2) If the [decoration] is updated manually, it unfortunately recreates whole input field without preserving its
    //    value, therefore it is needed to set the value back after decoration update
    var currentTex = _inputKey?.currentState?.textField?.controller?.value;
    _inputKey?.currentState?.updateDecoration(widget.decoration, null, null, null, null, null);
    _inputKey?.currentState?.textField?.controller?.value = currentTex;

    return SimpleAutoCompleteTextField(
      key: _inputKey,
      suggestionsAmount: 10,
      suggestions: _suggestions ?? [],
      submitOnSuggestionTap: true,
      textChanged: widget.onNameChanged,
      clearOnSubmit: false,
      decoration: widget.decoration,
      focusNode: _focusNode,
      textSubmitted: widget.onSubmitted ?? (_) {}, // the function must be given, otherwise there is exception
    );
  }

  void _updateSuggestions(List<PollOption> options) {
    _suggestions = options.map((option) => option.name).toList();
    _inputKey?.currentState?.updateSuggestions(_suggestions);
  }
}
