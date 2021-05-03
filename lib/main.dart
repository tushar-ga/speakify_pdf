
import 'package:flutter/material.dart';
import 'package:speakify_pdf/UserScreen.dart';
import 'PDFScreen.dart';
import 'HomeScreen.dart';
import "SpeechRecognizer.dart";
import 'TTS.dart';
import 'UserScreen.dart';
import 'AddPDF.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(TextToSpeech());
}

class TextToSpeech extends StatefulWidget {
  @override
  _TextToSpeechState createState() => _TextToSpeechState();
}

class _TextToSpeechState extends State<TextToSpeech> {
  @override
  void initState() {
    super.initState();

    // http
    //     .get(Uri.https(
    //         "0eaoyudwr7.execute-api.ap-south-1.amazonaws.com", "generateTags"))
    //     .then((response) => print(response.body));
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes:{
        '/': (context)=> HomeScreen(),
        '/userhome': (context)=>UserHome(),
        '/pdf': (context) => PDFHandler(),
        '/sr': (context) => SpeechRecognizer(),
        '/tts': (context)=> TTS(),
        '/addPDF':(context)=>AddPDF(),
      },
      builder: EasyLoading.init(),
    );
  }
}
