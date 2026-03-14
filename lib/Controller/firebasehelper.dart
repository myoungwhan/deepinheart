import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../main.dart';
import '../views/ui_helpers.dart';
import 'Model/user_model.dart';
import 'Viewmodel/userviewmodel.dart';

class Services {
  final auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future loginWithgoogl(context) async {
    try {
      await googleSignIn.signIn().then((value) async {
        if (value != null) {
          var email = value.email;

          var paylaod = {
            "username": email.substring(0, email.indexOf('@')).toString(),
            "email": email,
            "type": "user",
            "phone": "",
            "address": "",
            "token": Provider.of<UserViewModel>(
              context,
              listen: false,
            ).fcmToken.toString(),
            "url": value.photoUrl,
          };
        }
      });
    } catch (error) {
      print(error.toString() + ">>>>>");
    }
  }

  Future loginWithApple(context) async {
    UserViewModel provider = Provider.of<UserViewModel>(context, listen: false);
    try {
      AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          // TODO: Set the `clientId` and `redirectUri` arguments to the values you entered in the Apple Developer portal during the setup
          clientId: 'com.ktech.deepinheart',
          redirectUri: Uri.parse(
            'https://flutter-sign-in-with-apple-example.glitch.me/callbacks/sign_in_with_apple',
          ),
        ),
        // TODO: Remove these if you have no need for them
        nonce: 'example-nonce',
        state: 'example-state',
      ).catchError((error) {
        return error;
      });

      print(credential);
      var email = credential.email;

      var paylaod = {
        "username": credential.givenName,
        "email": email,
        "fcm_token": Provider.of<UserViewModel>(
          context,
          listen: false,
        ).fcmToken.toString(),
        "provider_id": '2',
        'type_account': 'apple',
      };

      await provider.socialLogin(context, paylaod);

      // This is the endpoint that will convert an authorization code obtained
      // via Sign in with Apple into a session in your system
      final signInWithAppleEndpoint = Uri(
        scheme: 'https',
        host: 'flutter-sign-in-with-apple-example.glitch.me',
        path: '/sign_in_with_apple',
        queryParameters: <String, String>{
          'code': credential.authorizationCode,
          'firstName': credential.givenName!,
          'lastName': credential.familyName!,
          'useBundleId': Platform.isIOS || Platform.isMacOS ? 'true' : 'false',
          if (credential.state != null) 'state': credential.state!,
        },
      );

      // If we got this far, a session based on the Apple ID credential has been created in your system,
      // and you can now set this as the app's session
    } catch (err) {
      return;
      //  _toastService.showToast(context, err.toString());
    }
  }

  void signOut(context) async {
    // try {
    //   auth.signOut().then((value) => Navigator.pushAndRemoveUntil(context,
    //       MaterialPageRoute(builder: (context) => LogIn()), (route) => false));
    // } catch (e) {
    //   errorBox(context, e);
    // }
  }

  void errorBox(context, e) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(title: Text("Error"), content: Text(e.toString()));
      },
    );
  }
}
