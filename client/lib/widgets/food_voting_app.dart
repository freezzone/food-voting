import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/models/poll_in_list.model.dart';
import 'package:food_voting_app/services/poll_evaluation_task.service.dart';
import 'package:food_voting_app/widgets/pages/detail_page.dart';
import 'package:food_voting_app/widgets/pages/edit_page.dart';
import 'package:food_voting_app/widgets/pages/home_page.dart';
import 'package:provider/provider.dart';

class FoodVotingApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FoodVotingAppState();
  }
}

class _FoodVotingAppState extends State<FoodVotingApp> with WidgetsBindingObserver {
  PollEvaluationTaskService _evaluatePollsTaskService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _evaluatePollsTaskService?.start();
        break;

      default:
        _evaluatePollsTaskService?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    var evaluatePollsTaskService = context.watch<PollEvaluationTaskService>();

    if (evaluatePollsTaskService != _evaluatePollsTaskService) {
      _evaluatePollsTaskService?.stop();
      _evaluatePollsTaskService = evaluatePollsTaskService;
      _evaluatePollsTaskService?.start();
    }

    return MaterialApp(
      title: 'Food Voting',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      initialRoute: '/',
      routes: {
        '/create': (_) => EditPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          if (settings?.arguments is PollInList) {
            return MaterialPageRoute(builder: (context) => DetailPage(pollInList: settings.arguments));
          }
          return MaterialPageRoute(builder: (context) => HomePage());
        }

        if (settings.name == '/edit') {
          if (settings?.arguments is String) {
            return MaterialPageRoute(builder: (context) => EditPage(pollId: settings.arguments));
          }
          return MaterialPageRoute(builder: (context) => HomePage());
        }

        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Center(
            child: Text('Page not found'),
          ),
        );
      },
    );
  }
}
