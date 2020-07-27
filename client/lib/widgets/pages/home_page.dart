import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/models/poll_in_list.model.dart';
import 'package:food_voting_app/services/poll.service.dart';
import 'package:food_voting_app/widgets/main_app_bar.dart';
import 'package:food_voting_app/widgets/pages/page_template.dart';
import 'package:food_voting_app/widgets/poll_list.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final _tabControl = CupertinoTabController();
  Stream<List<PollInList>> _recentPolls;
  Stream<List<PollInList>> _archivedPolls;

  @override
  void initState() {
    super.initState();
    final pollService = context.read<PollService>();
    _recentPolls = pollService.getRecentPolls();
    _archivedPolls = pollService.getArchivedPolls();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      builder: _build,
      appBar: buildMainAppBar(context: context, title: Text("Food Voting")),
    );
  }

  Widget _build(BuildContext context, FirebaseUser user) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.timer), title: Text("Recent polls")),
          BottomNavigationBarItem(icon: Icon(Icons.archive), title: Text("Archived polls")),
          BottomNavigationBarItem(icon: Icon(Icons.add), title: Text("Create poll"))
        ],
        currentIndex: _tabControl.index,
        onTap: (index) {
          if (index == 2) {
            _tabControl.index = 0; // when returned from poll creation page -> show list of recent
            Navigator.of(context).pushNamed('/create');
          }
        },
      ),
      controller: _tabControl,
      tabBuilder: (_, index) {
        return StreamBuilder<List<PollInList>>(
          stream: index == 0 ? _recentPolls : _archivedPolls,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CupertinoActivityIndicator();
            }

            if (snapshot.data.length == 0) {
              return Center(
                child: Text('No polls found'),
              );
            }

            return PollList(
              polls: snapshot.data,
              onTap: (poll) => _openDetail(context, poll),
            );
          },
        );
      },
    );
  }

  _openDetail(BuildContext context, PollInList poll) {
    Navigator.of(context, rootNavigator: true).pushNamed('/detail', arguments: poll);
  }

  void dispose() {
    _tabControl.dispose();
    super.dispose();
  }
}
