import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'google_Signin.dart';
class HomeScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Center(child: Text('Speakify PDF')),
            backgroundColor: Colors.deepPurple,
          ),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 50,
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/Logo.png'),
                  ],
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Container(
                height: 300,
                child: SignIn(),
              )

            ],),
          )
          ,
      ),
    );
  }
}