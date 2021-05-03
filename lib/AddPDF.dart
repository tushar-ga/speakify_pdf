import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:aws_s3/aws_s3.dart';
import 'package:path/path.dart' as path;
import 'PDFArguments.dart';
class AddPDF extends StatefulWidget {
  @override
  _AddPDFState createState() => _AddPDFState();
}

class _AddPDFState extends State<AddPDF> {
  String name;
  Future displayUploadDialog(AwsS3 awsS3) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreamBuilder(
        stream: awsS3.getUploadStatus,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return buildFileUploadDialog(snapshot, context);
        },
      ),
    );
  }

  AlertDialog buildFileUploadDialog(
      AsyncSnapshot snapshot, BuildContext context) {
    return AlertDialog(
      title: Container(
        padding: EdgeInsets.all(6),
        child: LinearProgressIndicator(
          value: (snapshot.data != null) ? snapshot.data / 100 : 0,
          valueColor:
          AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColorDark),
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Text('Uploading...')),
            Text("${snapshot.data ?? 0}%"),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text("Upload your ebook"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 0, 0),
            child: Text("Ebook Name", style: TextStyle(fontSize: 18, fontFamily: 'Verdana')),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 1.00),
                  ),
                  enabledBorder: const OutlineInputBorder( borderSide: const BorderSide(color: Color(0xFFD1C4E9), width: 1.00),),
                  hintText: 'Enter the name of ebook'
              ),
              onChanged: (val){
                setState(() {
                  name=val;
                });
              },
            ),
          ),
          Container(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton( child:Text("Upload"),
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.deepPurple[300])),
                onPressed: ()async{
                  FilePickerResult result = await FilePicker.platform
                      .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

                  if (result != null) {

                    File file = File(result.files.single.path);
                    print(result.files.single.path);
                    String filename = path.basename(file.path);

                    AwsS3 awsS3 = AwsS3(
                        file: file,
                        fileNameWithExt: filename,
                        awsFolderPath: '',
                        poolId: 'ap-south-1:779987a1-1e84-45d5-9a1f-949d700a8477',
                        bucketName: 'mypdffile',
                        region: Regions.AP_SOUTH_1);
                    String res;
                    
                    try {
                      try {
                         res = await awsS3.uploadFile;
                        debugPrint("Result :'$res'.");
                      } on PlatformException {
                        debugPrint("Result :'$res'.");
                      }
                    } on PlatformException catch (e) {
                      debugPrint("Failed :'${e.message}'.");
                    }
                    Navigator.pop(context,PDFArgs(name,filename));
                  }
              },),
            ),
          )
        ],
      )
    );
  }
}
