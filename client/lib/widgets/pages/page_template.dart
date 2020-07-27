import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/services/auth.service.dart';
import 'package:food_voting_app/widgets/login_form.dart';
import 'package:provider/provider.dart';

class PageTemplate extends StatefulWidget {
  final Widget Function(BuildContext context, FirebaseUser user) builder;
  final PreferredSizeWidget appBar;

  PageTemplate({@required this.builder, this.appBar});

  @override
  State<StatefulWidget> createState() {
    return _PageTemplateState();
  }
}

class _PageTemplateState extends State<PageTemplate> {
  Stream<FirebaseUser> _userStream;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _userStream = auth.currentUser();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirebaseUser>(
      stream: _userStream,
      builder: (context, snapshot) {
        var renderIndicator = false;
        var renderLoginForm = false;

        if (snapshot.connectionState == ConnectionState.waiting) {
          // waiting for initial auth initialization
          renderIndicator = true;
        } else if (snapshot.data == null) {
          // waiting for sign in
          renderLoginForm = true;
        }

        return Scaffold(
          appBar: widget.appBar,
          resizeToAvoidBottomInset: true,
          body: renderIndicator
              ? _buildProgressIndicator()
              : (renderLoginForm ? LoginForm() : widget.builder(context, snapshot.data)),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Center(child: CupertinoActivityIndicator());
  }
}
