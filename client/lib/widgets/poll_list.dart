import 'package:flutter/material.dart';
import 'package:food_voting_app/models/poll_in_list.model.dart';
import 'package:food_voting_app/models/poll_result.model.dart';
import 'package:intl/intl.dart';

class PollList extends StatelessWidget {
  final List<PollInList> polls;
  final void Function(PollInList poll) onTap;

  PollList({this.polls, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: polls.length,
      itemBuilder: (_, index) => _buildListItem(context, polls[index]),
      separatorBuilder: (_, __) => Divider(
        color: Theme.of(context).textTheme.bodyText1.color,
        thickness: 0.5,
      ),
    );
  }

  Widget _buildListItem(BuildContext context, PollInList poll) {
    return ListTile(
      key: ValueKey(poll.id),
      leading: Container(
        height: double.infinity,
        child: poll.closed == false
            ? Icon(Icons.lock_open, size: 40, color: Colors.green)
            : Icon(Icons.lock_outline, size: 40, color: Colors.red),
      ),
      title: Text(poll.name),
      trailing: Text(poll.endAt != null ? DateFormat.yMMMMEEEEd().add_Hm().format(poll.endAt.toDate()) : ''),
      subtitle: _buildSubtitle(context, poll),
      onTap: () => onTap != null ? onTap(poll) : null,
    );
  }

  Widget _buildSubtitle(BuildContext context, PollInList poll) {
    return Text(poll.closed == false ? 'In progress' : _resultText(poll.result));
  }

  String _resultText(PollResult result) {
    return result?.option == null ? 'Closed, no result' : 'Winning restaurant: ${result?.option?.name}';
  }
}
