import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_voting_app/services/auth.service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

buildMainAppBar({BuildContext context, Widget title}) {
  final user = context.watch<FirebaseUser>();
  final auth = context.watch<AuthService>();

  return AppBar(
    title: title,
    actions: user != null
        ? [
            Center(child: Text(user.displayName)),
            IconButton(
              icon: Icon(Icons.exit_to_app),
              color: Colors.white,
              tooltip: "Logout",
              onPressed: () {
                auth.signOut();
              },
            ),
          ]
        : [],
  );
}
