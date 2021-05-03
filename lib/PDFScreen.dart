import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakify_pdf/SpeakText.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
class PDFHandler extends StatefulWidget {
  PDFHandler({Key key}) : super(key: key);

  @override
  _PDFHandlerState createState() => _PDFHandlerState();
}
class _PDFHandlerState extends State<PDFHandler> {

  PdfViewerController _control = PdfViewerController();
  ReadTextSpeech speech = ReadTextSpeech();
  int pageNumber = 1;
  String lang = 'English';
  @override
  void deactivate() {
  speech.stop();
    super.deactivate();
  }
  @override
  Widget build(BuildContext context) {
    Map<String,String> args = ModalRoute.of(context).settings.arguments;
    String file = args["file"];
    String fileName = file.substring(0,file.length-4);
    String url = "https://mypdffile.s3.ap-south-1.amazonaws.com/"+ file;
    print(fileName);
    return Scaffold(
      appBar: AppBar(
        title: Text('Speakify PDF'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IntrinsicWidth(
                child: TextField(
                  onChanged: (String val){
                    setState((){
                      pageNumber= int.parse(val);
                    });
                  },
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 1.00),
                      ),
                      enabledBorder: const OutlineInputBorder( borderSide: const BorderSide(color: Color(0xFFD1C4E9), width: 1.00),),
                      hintText: 'P.no.'
                  ),
                ),
              ),
              ElevatedButton(onPressed: () async{
                await speech.stop();
                EasyLoading.show(status: 'loading...');
                _control.jumpToPage(pageNumber);
                PDFDoc doc = await PDFDoc.fromURL(url);
                PDFPage page = doc.pageAt(pageNumber);
                String pageText = await page.text;
                pageText = pageText.replaceAll('\n', ' ');
                if(lang=='English'){
                  EasyLoading.dismiss();
                  speech.speak(pageText);
                }
                else
                await http.get(Uri.https(
                        "ruh8j3z0uc.execute-api.ap-south-1.amazonaws.com", "hindi", {'text': pageText}))
                    .then((response) {
                      if(response.statusCode==200) {
                        EasyLoading.dismiss();
                       speech.speak(response.body);
                      }
                      else {
                        EasyLoading.dismiss();
                        speech.speak("There is an error. Please try again");
                      }
                    });
                //
              }, child: Text("Read PDF")),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: ()async{
                var result = await Navigator.pushNamed(context, '/sr',arguments: {"file": fileName});
                await http.get(Uri.https(
                    "hxb7psdavf.execute-api.ap-south-1.amazonaws.com", "pageRange", {'book': fileName, "heading": result.toString()}))
                    .then((response)async{
                      var data = json.decode(response.body);
                      for(int i =data[0]+1;i<=data[1]+1;i++){
                          await speech.stop();
                          EasyLoading.show(status: 'loading...');
                          _control.jumpToPage(i);
                          PDFDoc doc = await PDFDoc.fromURL(url);
                          PDFPage page = doc.pageAt(i);
                          String pageText = await page.text;
                          pageText = pageText.replaceAll('\n', ' ');
                          if(lang=='English'){
                            EasyLoading.dismiss();
                            await speech.speak(pageText);
                          }
                          else
                            await http.get(Uri.https(
                              "ruh8j3z0uc.execute-api.ap-south-1.amazonaws.com", "hindi", {'text': pageText}))
                              .then((response) async{
                            if(response.statusCode==200) {
                              EasyLoading.dismiss();
                              await speech.speak(response.body);
                            }
                            else {
                              EasyLoading.dismiss();
                              await speech.speak("There is an error. Please try again");
                            }
                          });
                          //
                      }
                });
              },
            ),
            PopupMenuButton(
              onSelected: (val) async{
                await speech.stop();
                setState(() {
                  lang = val;
                });
              },
              icon: Icon(Icons.language),
                itemBuilder:(context){
              return
              [
              PopupMenuItem(
                value: "English",
                child:  Text('English'),
              ),
              PopupMenuItem(
                value:"Hindi",
                child:Text("Hindi"),
              ),
              ];}),
            ],
          ),
          Expanded(
            child: Container(
              child:
              // Text("Here goes PDF Viewer"),
              SfPdfViewer.network(
                  url, controller: _control,),
            ),
          ),
        ],
      ),
    );
  }
}
