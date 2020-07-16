import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/src/screens/drawingpage.dart';
import 'package:flutterapp/src/screens/aipage.dart';

class Ip{
  final String ip;

  Ip({this.ip});
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key:key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Ip ipObj;
  var _textControllerIP = new TextEditingController();
  var _textUserName = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    ipObj = Ip(ip: "ws://192.168.225.220:6969/data");
    return Scaffold(
      appBar: AppBar(
        title: Text('Pictionary'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          color: Colors.grey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _textUserName,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Enter UserName',
                  contentPadding:
                  const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(25.7),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(25.7),
                  ),
                ),
              ),
              SizedBox(height: 10,),
              TextField(
                controller: _textControllerIP,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Enter IP',
                  contentPadding:
                  const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(25.7),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(25.7),
                  ),
                ),
              ),
              SizedBox(height: 10,),
//          Multiplayer page
              RaisedButton(
                onPressed: () {
                  if(_textControllerIP.text.isNotEmpty){
                    ipObj = Ip(ip: _textControllerIP.text);
                  }
                  if(_textUserName.text.isNotEmpty){
                    var route = MaterialPageRoute(builder: (context) => DrawingPage(ipObj: ipObj, userName: _textUserName.text,));
                    return Navigator.push(context, route);
                  }
                  else{
                    return showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Oops!"),
                        content: Text("Looks like you forgot to add UserName!"),
                        actions: <Widget>[
                          RaisedButton(onPressed: () async {Navigator.pop(context);}, child: Text("Ok", style: TextStyle(color:Colors.black),), color: Colors.grey,),
                        ],
                        elevation: 24.0,
                      ),
                      barrierDismissible: true,
                    );
                  }
                },
                child: Text('Play Online With Friends!'),
                color: Colors.orangeAccent,
                splashColor: Colors.green,
              ),
//          AI page
              RaisedButton(
                onPressed: () {
                  var route = MaterialPageRoute(builder: (context) => AIPage(ipObj: ipObj));
                  return Navigator.push(context, route);
                },
                child: Text('Play With AI!'),
                color: Colors.blueAccent,
                splashColor: Colors.green,
              ),
            ]
          ),
        ),
      ),
    );
  }
}