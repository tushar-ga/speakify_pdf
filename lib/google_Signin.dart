import 'dart:async';
import 'dart:convert' show json;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'UserArgument.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  clientId: '798955549864-fpe2qshf25kl63s1rc3dbqoutmepqk1t.apps.googleusercontent.com',
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);



class SignIn extends StatefulWidget {
  @override
  State createState() => SignInState();
}

class SignInState extends State<SignIn> {
  GoogleSignInAccount _currentUser;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();
  }


  Future<GoogleSignInAccount> _handleSignIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Widget _buildBody() {

      return
          Column(
            children: [
              SizedBox(height:5),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  child: const Text('SIGN IN'),
                  onPressed: () async{
                    GoogleSignInAccount asd = await _handleSignIn();
                    if(asd!=null){
                      Navigator.pushReplacementNamed(context, '/userhome',arguments: UserArguments(asd) );
                    }
                    },
                ),
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser != null) {
      String name = _currentUser.displayName;
      return AlertDialog(title: Text("Already signed in?"),
        content: SingleChildScrollView(
          child: Text("You are already signed in as $name. Do you want to continue?"),
        ),
        actions: [
          TextButton(
            onPressed: (){
                Navigator.pushNamed(context, '/userhome',arguments: UserArguments(_currentUser) );
                },
            child: Text('Yes'),),
          TextButton(
            onPressed: (){
             _handleSignOut();
             return _buildBody();
            },
            child: Text('No, Sign Out'),),
        ],
        );

    }
    return _buildBody();

  }
}