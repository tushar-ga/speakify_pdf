import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:speakify_pdf/SpeakText.dart';
import 'package:speech_recognition/speech_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
extension CapExtension on String {
  String get inCaps => this.length > 0 ?'${this[0].toUpperCase()}${this.substring(1)}':'';
  String get allInCaps => this.toUpperCase();
  String get capitalizeFirstofEach => this.replaceAll(RegExp(' +'), ' ').split(" ").map((str) => str.inCaps).join(" ");
}
const languages = const [
  const Language('English', 'en_US'),
];

class Language {
  final String name;
  final String code;

  const Language(this.name, this.code);
}

class SpeechRecognizer extends StatefulWidget {
  @override
  _SpeechRecognizer createState() => _SpeechRecognizer();
}

class _SpeechRecognizer extends State<SpeechRecognizer> {
  SpeechRecognition _speech;
  TextEditingController control = new TextEditingController();
  bool _speechRecognitionAvailable = false;
  bool _isListening = false;
  String transcription = '';
  List<dynamic> data;
  bool dataView = false;
  //String _currentLocale = 'en_US';
  Language selectedLang = languages.first;
  ReadTextSpeech speech = new ReadTextSpeech();
  @override
  initState()  {
    super.initState();
    getPermission();
    speech.speak("What can I read for you?");
  }
  void getPermission() async{
    if(await Permission.microphone.request().isGranted){
      activateSpeechRecognizer();
    }
    else{
      print("denied");
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void activateSpeechRecognizer() {
    print('_MyAppState.activateSpeechRecognizer... ');
    _speech = new SpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    _speech.setCurrentLocaleHandler(onCurrentLocale);
    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech
        .activate()
        .then((res) => setState(() => _speechRecognitionAvailable = res));
  }

  Widget _getCheck(String file){
    if(transcription!=''){
      return IconButton(icon : Icon(Icons.check), onPressed: (){
        EasyLoading.show(status: 'processing query...');
        http.get(
          Uri.https("lkjff9vpde.execute-api.ap-south-1.amazonaws.com", 'maxmatch', {'book': file, "query":transcription})

        ).then((response)
        {
          EasyLoading.dismiss();
          print(response.body);
          setState(() {
            data = json.decode(response.body);
            dataView = true;
          });
        }
        );
      });
    }
    return Container();
  }

  List<Widget> _getDataItems(){
    List<Widget> ret = [];
    for(int i=0; i<data.length; i++){
      List<dynamic> str = data[i];
      ret.add(Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 2.0, color: Colors.grey[350]))),
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(child: Text(str[0][0].toUpperCase()+str[0].substring(1).toLowerCase()), onPressed: (){
          Navigator.pop(context, str[0]);
        } ),
      ));
    }
    return ret;
  }
  Widget _getMainBody(String file){
    if(dataView==false) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(controller: control, onChanged: (String text) {
              setState(() {
                transcription = text;
              });
            },),
          ),
          _getCheck(file),
        ],
      );
    }
    else return SingleChildScrollView(
      child: Column(
        children: _getDataItems(),
      )
    );
  }
  @override
  Widget build(BuildContext context) {
    Map<String,String> args = ModalRoute.of(context).settings.arguments;
    String file = args["file"];
    return Scaffold(
        appBar: new AppBar(
          backgroundColor: Colors.deepPurple,
          title: new Text('What can I read for you?'),
          actions: [
            new PopupMenuButton<Language>(
              onSelected: _selectLangHandler,
              itemBuilder: (BuildContext context) => _buildLanguagesWidgets,
            )
          ],
        ),
        body: new Padding(
            padding: new EdgeInsets.all(8.0),
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                new Expanded(
                    child: new Container(
                        alignment: AlignmentDirectional.topStart,
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.grey.shade200,
                        child: _getMainBody(file),
                    ),
                ),
                _buildButton(
                  onPressed: _speechRecognitionAvailable && !_isListening
                      ? () => start()
                      : null,
                  icon: Icons.mic,
                  label: _isListening
                      ? 'Listening...'
                      : 'Speak',
                ),
                _buildButton(
                  onPressed: _isListening ? () => cancel() : null,
                  label: 'Cancel',
                  icon : Icons.close,
                ),
                _buildButton(
                  onPressed: _isListening ? () => stop() : null,
                  label: 'Stop',
                  icon: Icons.stop
                ),
              ],
            )),
      );
  }

  List<CheckedPopupMenuItem<Language>> get _buildLanguagesWidgets => languages
      .map((l) => new CheckedPopupMenuItem<Language>(
    value: l,
    checked: selectedLang == l,
    child: new Text(l.name),
  ))
      .toList();

  void _selectLangHandler(Language lang) {
    setState(() => selectedLang = lang);
  }

  Widget _buildButton({String label, VoidCallback onPressed, IconData icon}) => new Padding(
      padding: new EdgeInsets.all(12.0),
      child: new RaisedButton(
        color: Colors.deepPurple[400],
        onPressed: onPressed,
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Icon(icon , color: Colors.white70),
            SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ]
        ),
      ));

  void start() => _speech
      .listen(locale: selectedLang.code)
      .then((result) => print('_MyAppState.start => result ${result}'));

  void cancel() =>
      _speech.cancel().then((result) => setState(() => _isListening = result));

  void stop() =>
      _speech.stop().then((result) => setState(() => _isListening = result));

  void onSpeechAvailability(bool result) =>
      setState(() => _speechRecognitionAvailable = result);

  void onCurrentLocale(String locale) {
    print('_MyAppState.onCurrentLocale... $locale');
    setState(
            () => selectedLang = languages.firstWhere((l) => l.code == locale));
  }

  void onRecognitionStarted() => setState(() => _isListening = true);

  void onRecognitionResult(String text) async{
      setState(
          () => transcription = text);
      control.text = text;
  }

  void onRecognitionComplete() {
    setState(() => _isListening = false);
    print("Log State"+ transcription);
    Future.delayed(Duration(seconds: 1), () async{
      await speech.speak("You have said ");
      Future.delayed(Duration(milliseconds: 500),() async{
        await speech.speak(transcription);
      });
    });

  }
}