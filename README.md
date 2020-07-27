# Food Voting Application

Food voting application is an application for creation of polls where participants are voting for their
favorite restaurant from which will be ordered food delivery. Winning restaurant is a restaurant randomly selected
from all votes. Which means eg:
- given that 100 votes are given by participants
- from that 20 votes for a restaurant A
- from that 30 votes for a restaurant B
- from that 50 votes for a restaurant C
- at all the restaurant A has chance to win 20%, B 30% and C 50%

## Used technologies
- Client: Web + Android (possibly to add iOS support) - **Flutter**
- Server: Firebase - **Firestore, Cloud Functions, Authentication, Hosting**

## How to

### Requirements
1. npm
2. Node.js
3. Firebase CLI `npm install -g firebase-tools` (https://firebase.google.com/docs/cli)
4. Flutter (https://flutter.dev/docs/get-started/install/linux) with web support. To enable web support run
   ```
   $ flutter channel beta
   $ flutter upgrade
   $ flutter config --enable-web
   ```
5. Android Studio with Flutter and Dart plugins (https://flutter.dev/docs/get-started/editor?tab=androidstudio)
5. Google account - the application can run on the free Firebase plan

### Installation
1. in folder `/functions` run `npm install`
2. in folder `/client` run `flutter pub get`
3. create new project in Firebase Console (https://console.firebase.google.com)
   - add there web and android app for the created project (you can do that in project settings)
   - when creating android app, make sure you set correct android package name (currently in the project is
   the package set to `com.food_voting_app`)
   - rename file `/client/web/init.js.example` to `/client/web/init.js`, edit it and put there updated values for
   `var firebaseConfig` which you can find in firebase console
   - download `google-services.json` file from Firebase Console and save it as `/android/app/google-services.json`
4. run `firebase login`
5. associate your local project with the created firestore project `firebase use --add`, when asked for 
   an alias, then set `default`

### Build

1. for web: in `/client` run `flutter build web`
2. for android: in `/client` run `flutter build apk`
3. Cloud functions are build as part of deploy command itself

### Deploy
1. for web and optionally android: in `/` run `firebase deploy`
2. only for backend for android: in `/` run `firebase deploy --only functions,firestore` (so it is same as for web, 
   except the hosting is not deployed)
   
### Run locally
1. To run web or android client locally, the easiest way is to use Android Studio. When run web build, ensure that
   it runs locally on port `5000`, otherwise the Firebase Authentication will not work. You can set it in run 
   configuration by adding parameter `--web-port 5000`
2. You can connect directly into your Firebase services (no extra steps needed in that case) or you can run
   whole Firebase locally, in that case:
   - `firebase serve`
   - search in file `/client/lib/widgets/with_providers.dart` for line containing `cf.useFunctionsEmulator` and
     uncomment this line and update the port, to correct port where is your local firestore running.
