import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/src/widgets/drawingpage.dart';
import 'package:flutterapp/src/widgets/aipage.dart';

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
  var _textController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    ipObj = Ip(ip: "ws://192.168.225.220:6969/data");
    return Scaffold(
      appBar: AppBar(
        title: Text('Pictionary'),
        centerTitle: true,
      ),
      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Default ip sample: -> "+ipObj.ip,
              ),
            ),
//          Multiplayer page
            RaisedButton(
              onPressed: () {
                if(_textController.text.isNotEmpty){
                  ipObj = Ip(ip: _textController.text);
                }
                var route = MaterialPageRoute(builder: (context) => DrawingPage(ipObj: ipObj));
                return Navigator.push(context, route);
              },
              child: Text('Play Online'),
              color: Colors.orangeAccent,
              splashColor: Colors.green,
            ),
//          AI page
            RaisedButton(
              onPressed: () {
                var route = MaterialPageRoute(builder: (context) => AIPage(ipObj: ipObj));
                return Navigator.push(context, route);
              },
              child: Text('Play with AI!'),
              color: Colors.blueAccent,
              splashColor: Colors.green,
            ),
          ]
        ),
      ),
    );
  }
}