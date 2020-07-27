import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_voting_app/services/auth.service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart' as buttons;

class LoginForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: buttons.GoogleSignInButton(
        onPressed: () {
          context.read<AuthService>().signInWithGoogle();
        },
      ),
    );
  }

}