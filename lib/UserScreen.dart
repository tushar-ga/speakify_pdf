import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:speakify_pdf/PDFArguments.dart';
import 'package:speakify_pdf/UserArgument.dart';
import 'PDFArguments.dart';

class UserHome extends StatefulWidget {
  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  List<Map<String,String>> books=[{"name":'Computer Algorithms', "file": "InternationalLaw.pdf" }, {"name":'International Law', "file": "InternationalLaw.pdf" },{"name":'Environmental Studies', "file": "InternationalLaw.pdf" }, {"name":'Science NCERT', "file": "InternationalLaw.pdf" }];

  Widget buildListItem(Map<String,String> text){
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 2.0, color: Colors.grey[350]))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text["name"], style: TextStyle(fontFamily: 'Poppins', fontSize: 18),),
            IconButton(icon: Icon(Icons.arrow_forward_ios_rounded, color: Colors.blue), onPressed: (){
              Navigator.pushNamed(context, '/pdf', arguments: {"file": text["file"]});
            },)
          ],
        ),
      ),
    );
  }
  List<Widget> listBooks(List<Map<String,String>> books){
    List<Widget> booksList= [];
    for(int i=0; i<books.length; i++){
      booksList.add(buildListItem(books[i]));
    }
    return booksList;
  }
  @override
  Widget build(BuildContext context) {
    UserArguments args = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Your Books"),
            GoogleUserCircleAvatar(identity: args.user),
          ],
        ),
      ),
      body: ListView(
        scrollDirection: Axis.vertical,
        children: listBooks(books)
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: ()async{
          var res= await Navigator.pushNamed(context, '/addPDF');
          PDFArgs result =res;
          print(result.name+" "+result.file);
          Map<String,String> add = {"name" : result.name, "file":result.file};
          setState(() {
            books = [...books, add];
          });
        },
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
