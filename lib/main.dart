import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/src/screens/homePage.dart';
import 'package:flutterapp/src/screens/drawingpage.dart';
import 'package:flutterapp/src/screens/aipage.dart';

void main() => runApp(Route());

class Route extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DrawingPage(),
      initialRoute: 'home',
      routes: <String, WidgetBuilder>{
        'home': (BuildContext context) => HomePage(),
        'drawingpage': (BuildContext context) => DrawingPage(),
        'aipage': (BuildContext context) => AIPage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: true,
    );
  }
}






