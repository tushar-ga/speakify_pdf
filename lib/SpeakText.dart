import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ReadTextSpeech{
  FlutterTts flutterTts;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  ReadTextSpeech(){
    flutterTts = FlutterTts();

    if (isAndroid) {
      _getEngines();
    }
  }
  Future stop() async {
    await flutterTts.stop();
  }
  Future speak(String _newVoiceText) async {
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(0.5);

    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(_newVoiceText);
      }
    }
  }

  Future _getEngines() async {
    var engines = await flutterTts.getEngines;
    if (engines != null) {
      for (dynamic engine in engines) {
        print(engine);
      }
    }
  }
}