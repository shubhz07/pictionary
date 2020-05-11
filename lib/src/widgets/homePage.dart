import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({Key key, this.title}) : super(key:key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pictionary'),
        centerTitle: true,
      ),
      body: Center(
        child: FlatButton(
          onPressed: () {
            return (Navigator.of(context).pushNamed('/drawingpage'));
          },
          child: Text('Start Game'),
          color: Colors.orangeAccent,
          splashColor: Colors.green,

        ),
      ),
    );
  }

}