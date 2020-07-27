import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/models/poll.model.dart';
import 'package:food_voting_app/models/poll_in_list.model.dart';
import 'package:food_voting_app/models/poll_option.model.dart';
import 'package:food_voting_app/models/vote.model.dart';
import 'package:food_voting_app/services/poll.service.dart';
import 'package:food_voting_app/widgets/option_tiles/add_and_edit_option_tile.dart';
import 'package:food_voting_app/widgets/expandable.dart';
import 'package:food_voting_app/widgets/main_app_bar.dart';
import 'package:food_voting_app/widgets/option_tiles/edit_option_tile.dart';
import 'package:food_voting_app/widgets/pages/page_template.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum PollAction {
  delete,
  evaluate,
  edit,
}

class DetailPage extends StatefulWidget {
  final PollInList pollInList;

  DetailPage({@required this.pollInList});

  @override
  State<StatefulWidget> createState() {
    return _DetailPageState();
  }
}

class _DetailPageState extends State<DetailPage> {
  bool showMenuProgressIndicator = false;

  FirebaseUser _user;
  PollService _pollService;
  Poll _poll;
  Stream<Poll> _pollStream;
  EditOptionTileInputValue _initAddOptionTileState = EditOptionTileInputValue()
    ..addGlobally = false
    ..option = (PollOption()..name = '');

  get pollInList {
    // return _poll if already loaded since _poll is getting constant updates from db, so its value is more up to date
    return _poll != null ? _poll : widget.pollInList;
  }

  @override
  void initState() {
    super.initState();
    _pollService = context.read<PollService>();
    _pollStream = _pollService.getPoll(pollInList.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Poll>(
      stream: _pollStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _poll = snapshot.data;
        }

        return PageTemplate(
          builder: _build,
          appBar: buildMainAppBar(context: context, title: Text(pollInList.name)),
        );
      },
    );
  }

  Widget _build(BuildContext context, FirebaseUser user) {
    _user = user;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pollInList.closed ? _buildClosedInfo(context) : _buildOpenInfo(context),
          Expanded(child: _buildPollDetail()),
        ],
      ),
    );
  }

  Widget _buildPollDetail() {
    if (_poll == null) {
      return Center(child: CupertinoActivityIndicator());
    }

    Vote currentVote = _poll.votes.firstWhere((Vote vote) => vote.creatorId == _user.uid, orElse: () => null);
    Map<String, List<Vote>> votesByOptionId = {};
    _poll.votes.forEach((Vote vote) {
      var votesForOption = votesByOptionId.containsKey(vote.optionId) ? votesByOptionId[vote.optionId] : <Vote>[];
      votesForOption.add(vote);
      votesByOptionId[vote.optionId] = votesForOption;
    });

    return ListView(
      children: [
        ..._poll.options.map((option) => _buildOption(context, _poll, option, currentVote, votesByOptionId)),
        if (pollInList.closed == false) _buildAddOptionTile(context, _poll),
      ],
    );
  }

  Widget _buildClosedInfo(BuildContext context) {
    return ListTile(
      leading: Container(
        height: double.infinity,
        child: Icon(Icons.lock_outline, size: 40, color: Colors.red),
      ),
      title: Text('Voting closed'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Winning option: ${pollInList.result?.option != null ? pollInList.result?.option?.name : 'N/A'}'),
          Text(
              'Closed at ${pollInList.result?.evaluatedAt != null ? DateFormat.yMMMMEEEEd().add_Hm().format(pollInList.result.evaluatedAt.toDate()) : 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildOpenInfo(BuildContext context) {
    return ListTile(
      leading: Container(
        height: double.infinity,
        child: Hero(
          tag: pollInList.id,
          child: Icon(Icons.lock_open, size: 40, color: Colors.green),
        ),
      ),
      title: Text('Voting open'),
      subtitle: Text('until ' +
          (pollInList.endAt != null ? DateFormat.yMMMMEEEEd().add_Hm().format(pollInList.endAt.toDate()) : '')),
      trailing: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Created by'),
                Text(pollInList.creatorName),
              ],
            ),
            if (pollInList.creatorId == _user?.uid)
              PopupMenuButton<PollAction>(
                icon: showMenuProgressIndicator ? CupertinoActivityIndicator() : null,
                enabled: !showMenuProgressIndicator,
                tooltip: showMenuProgressIndicator ? 'Action in progress' : 'Show menu',
                onSelected: (result) => _onMenuAction(context, result),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<PollAction>>[
                  const PopupMenuItem<PollAction>(
                    value: PollAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                    ),
                  ),
                  const PopupMenuItem<PollAction>(
                    value: PollAction.evaluate,
                    child: ListTile(
                      leading: Icon(Icons.poll),
                      title: Text('Evaluate and close'),
                    ),
                  ),
                  const PopupMenuItem<PollAction>(
                    value: PollAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, Poll poll, PollOption option, Vote currentVote, Map<String, List<Vote>> votesByOptionId) {
    var votes = votesByOptionId[option.id] ?? <Vote>[];
    int voteCount = votes.length;

    return RadioListTile(
      title: Text(option.name),
      subtitle: Expandable(
        header: Text('Current votes: $voteCount'),
        body: voteCount > 0 ? _buildListOfVoters(votes) : null,
      ),
      groupValue: currentVote?.optionId,
      value: option.id,
      onChanged: poll.closed ? null : (_) => _vote(context, poll, option),
    );
  }

  void _vote(BuildContext context, Poll poll, PollOption option) {
    _pollService.vote(pollId: poll.id, optionId: option.id, user: _user);
  }

  Widget _buildAddOptionTile(BuildContext context, Poll poll) {
    return AddAndEditOptionTile(
      key: ValueKey(poll.options.length), // whenever a new option is added, reset the form
      wouldBeFirstOption: poll.options.length == 0,
      initialValue: _initAddOptionTileState,
      onSave: (value) {
        _pollService.upsertPollOption(pollId: poll.id, optionName: value.option.name);
        _initAddOptionTileState.addGlobally = value.addGlobally;

        if (value.addGlobally) {
          _pollService.upsertGlobalOption(optionName: value.option.name);
        }
      },
    );
  }

  Widget _buildListOfVoters(List<Vote> votes) {
    return Text(votes.map((vote) => vote.creatorName).join(', '));
  }

  void _onMenuAction(BuildContext context, PollAction result) {
    switch (result) {
      case PollAction.evaluate:
        showCupertinoModalPopup(
          context: context,
          semanticsDismissible: true,
          builder: (_) => CupertinoAlertDialog(
            content: Text('Are you sure you want to closed and evaluate the poll now?'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                isDestructiveAction: false,
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: false,
                isDestructiveAction: true,
                child: Text('Evaluate and close'),
                onPressed: () {
                  setState(() {
                    showMenuProgressIndicator = true;
                  });
                  _pollService.evaluatePoll(pollInList.id).whenComplete(() {
                    setState(() {
                      showMenuProgressIndicator = false;
                    });
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
        break;

      case PollAction.delete:
        showCupertinoModalPopup(
          context: context,
          semanticsDismissible: true,
          builder: (_) => CupertinoAlertDialog(
            content: Text('Are you sure you want to delete the poll?'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                isDestructiveAction: false,
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: false,
                isDestructiveAction: true,
                child: Text('Delete'),
                onPressed: () {
                  _pollService.deletePoll(pollInList.id);
                  Navigator.of(context).pop(); // closes the confirm dialog
                  Navigator.of(context).pop(); // returns back to home page
                },
              ),
            ],
          ),
        );
        break;

      case PollAction.edit:
        Navigator.of(context).pushNamed('/edit', arguments: pollInList.id);
        break;
    }
  }
}
