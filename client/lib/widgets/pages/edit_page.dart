import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/models/poll_option.model.dart';
import 'package:food_voting_app/services/poll.service.dart';
import 'package:food_voting_app/widgets/option_tiles/add_option_tile.dart';
import 'package:food_voting_app/widgets/date_time_form_field.dart';
import 'package:food_voting_app/widgets/expanding_progress_indicator.dart';
import 'package:food_voting_app/widgets/option_tiles/edit_option_tile.dart';
import 'package:food_voting_app/widgets/pages/page_template.dart';
import 'package:provider/provider.dart';
import 'package:food_voting_app/models/poll.model.dart';
import 'package:food_voting_app/widgets/main_app_bar.dart';

class EditPage extends StatefulWidget {
  /// If null, new poll will be created
  final String pollId;

  EditPage({this.pollId});

  @override
  State<StatefulWidget> createState() {
    return _EditPageState();
  }
}

class _EditPageState extends State<EditPage> {
  final _formKey = GlobalKey<FormState>();
  final _overlayKey = GlobalKey<OverlayState>();
  final _inProgressOverlayEntry = OverlayEntry(
    maintainState: false,
    opaque: false,
    builder: (_) => ExpandingProgressIndicator(text: 'Saving poll'),
  );

  final List<PollOption> _newOptions = [];
  final Set<PollOption> _addGloballyOptions = Set();
  final Map<String, PollOption> _alreadyCreatedOptions = {};
  List<PollOption> _alreadyCreatedOptionsSorted;

  FirebaseUser _user;
  PollService _pollService;
  Future<Poll> _futurePoll;

  Icon optionIcon = Icon(
    Icons.radio_button_unchecked,
    size: 40,
  );

  @override
  void initState() {
    super.initState();
    _pollService = context.read<PollService>();
    _futurePoll = widget.pollId != null ? _pollService.getPoll(widget.pollId).first : Future.value(Poll());
    _futurePoll.then((poll) {
      if (poll.options != null) {
        setState(() {
          for (var option in poll.options) {
            _alreadyCreatedOptions[option.name] = option;
          }
          _alreadyCreatedOptionsSorted = _alreadyCreatedOptions.values.toList(growable: false)
            ..sort((a, b) => a.id.compareTo(b.id));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      builder: _build,
      appBar: buildMainAppBar(context: context, title: Text(widget.pollId == null ? 'Create Poll' : 'Edit Poll')),
    );
  }

  Widget _build(BuildContext context, FirebaseUser user) {
    _user = user;

    return Overlay(
      key: _overlayKey,
      initialEntries: [
        OverlayEntry(
          maintainState: true,
          opaque: true,
          builder: (_) => FutureBuilder(
            future: _futurePoll,
            builder: _buildForm,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AsyncSnapshot<Poll> snapshot) {
    final theme = Theme.of(context);
    final Poll poll = snapshot.data;

    if (poll == null) {
      return Center(child: CupertinoActivityIndicator());
    }

    return Container(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Poll name',
                  hintText: 'Please enter name',
                ),
                maxLength: 100,
                validator: (value) {
                  if (value.length < 2) {
                    return 'Poll name length must be at least 2 character long.';
                  }
                  return null;
                },
                initialValue: poll.name,
                onSaved: (value) {
                  poll.name = value;
                },
              ),
            ),
            DateTimeFormField(
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 365)),
              decoration: const InputDecoration(
                labelText: 'Open until',
                hintText: 'Please select end date',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Please enter valid end date and time of the poll.';
                }
                return null;
              },
              initialValue: poll.endAt?.toDate(),
              onSaved: (value) {
                poll.endAt = Timestamp.fromDate(value);
              },
            ),
            ListTile(
              title: Text(
                'Poll options',
                style: theme.textTheme.subtitle1,
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ..._buildAlreadyCreatedOptions(context),
                  ..._buildNewOptions(context),
                  AddOptionTile(
                    wouldBeFirstOption: _newOptions.length == 0 && _alreadyCreatedOptions.length == 0,
                    onAddOption: () {
                      setState(() {
                        var addOption = PollOption();
                        addOption.name = '';
                        addOption.id = '';
                        _newOptions.add(addOption);
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  RaisedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  RaisedButton(
                    textColor: theme.accentTextTheme.button.color,
                    highlightColor: theme.accentColor,
                    color: theme.accentColor,
                    onPressed: () {
                      _saveForm(poll);
                    },
                    child: Text('Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _buildAlreadyCreatedOptions(BuildContext context) {
    return _alreadyCreatedOptionsSorted.map(
      (option) => ListTile(
        leading: optionIcon,
        title: Text(option?.name ?? ''),
      ),
    );
  }

  Iterable<Widget> _buildNewOptions(BuildContext context) {
    return _newOptions.map(
      (option) => EditOptionTile(
        key: ObjectKey(option),
        showAddGloballyOption: true,
        initialValue: EditOptionTileInputValue()
          ..option = option
          ..addGlobally = false,
        showDeleteButton: true,
        onDeleteButtonClick: (_) {
          setState(() {
            _newOptions.remove(option);
            _addGloballyOptions.remove(option);
          });
        },
        onSaved: (value) {
          option.name = value.option.name;
          if (value.addGlobally) {
            _addGloballyOptions.add(option);
          } else {
            _addGloballyOptions.remove(option);
          }
        },
        onChanged: (value) {
          option.name = value.option.name;
        },
        validator: _newOptionUniqueIdValidator,
      ),
    );
  }

  String _newOptionUniqueIdValidator(EditOptionTileInputValue value) {
    bool conflictWithExisting = _alreadyCreatedOptions[value.option.name] != null;
    // "length >= 2" because the first one should be the option which I am validating and the other one is the one which is similar
    bool conflictWithAnotherNew = _newOptions.where((PollOption option) => option.name == value.option.name).length >= 2;

    if (conflictWithAnotherNew || conflictWithExisting) {
      return 'This option is similar to another one.';
    }

    return null;
  }

  void _saveForm(Poll poll) async {
    if (_formKey.currentState.validate()) {
      _overlayKey.currentState.insert(_inProgressOverlayEntry);

      _formKey.currentState.save();
      poll.creatorName = _user.displayName;
      poll.creatorId = _user.uid;
      poll.closed = false;
      poll.options = [
        ..._alreadyCreatedOptions.values,
        ..._newOptions,
      ];

      try {
        await _pollService.upsertPoll(poll: poll);
        // ignore errors from save of global options since only important thing here is that the poll is saved
        _addGloballyOptions.forEach((option) {
          _pollService.upsertGlobalOption(optionName: option.name).catchError((e) {
            print('Error during creation of global option');
            print(e);
          });
        });

        var nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          nav.popAndPushNamed('/');
        }
      } catch (e) {
        print(e);
        showCupertinoDialog(
          barrierDismissible: true,
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text('Error'),
            content: Text('We are sorry, an unexpected error occurred during poll saving.'),
            actions: [
              CupertinoDialogAction(
                child: Text('Ok'),
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
        _inProgressOverlayEntry.remove();
      }
    }
  }
}
