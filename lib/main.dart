import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/src/widgets/homePage.dart';
import 'package:flutterapp/src/widgets/drawingpage.dart';

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
      },
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: true,
    );
  }
}






