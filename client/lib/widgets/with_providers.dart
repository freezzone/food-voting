import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_voting_app/services/auth.service.dart';
import 'package:food_voting_app/services/cf_client.service.dart';
import 'package:food_voting_app/services/poll.service.dart';
import 'package:food_voting_app/services/poll_evaluation_task.service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
// works only for web
// import 'package:intl/intl_browser.dart';
// works only for mobile
import 'package:intl/intl_standalone.dart';

class WithProviders extends StatelessWidget {
  final Widget child;

  const WithProviders({
    Key key,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        FutureProvider<void>(
            initialData: Intl(),
            lazy: false,
            create: (context) async {
              final defaultLocale = 'en_US';
              String locale = defaultLocale;

              try {
                locale = await findSystemLocale();
                await initializeDateFormatting(locale, null);
              } catch (_) {
                locale = defaultLocale;
              }
              Intl.defaultLocale = locale;
              return;
            }),
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<FirebaseUser>(create: (context) => context.read<AuthService>().currentUser()),
        Provider<CloudFunctions>(create: (_) {
          var cf = CloudFunctions(app: FirebaseApp.instance, region: 'europe-west3');
          // uncomment when run locally
          // cf.useFunctionsEmulator(origin: 'http://localhost:5001');
          return cf;
        }),
        Provider<CfClientService>(
          create: (context) => CfClientService(
            cf: context.read<CloudFunctions>(),
          ),
        ),
        Provider<PollService>(
          create: (context) => PollService(
            cfClient: context.read<CfClientService>(),
          ),
        ),
        Provider<PollEvaluationTaskService>(
          create: (context) => PollEvaluationTaskService(
            pollService: context.read<PollService>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
