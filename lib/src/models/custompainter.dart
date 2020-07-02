import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/src/models/drawingpoints.dart';


class Drawing extends CustomPainter {
  Drawing({this.pointsListDrawData});

  List<DrawingPoints> pointsListDrawData;

  @override
  void paint(Canvas canvas, Size size){
    for(int i=0; i < pointsListDrawData.length; i++){
//      Drawing lines when pan action
      if(shouldDrawLine(i)){
        canvas.drawLine(pointsListDrawData[i].points, pointsListDrawData[i+1].points, pointsListDrawData[i].paint);
      }
//      Drawing points when user taps
      else if (shouldDrawPoint(i)) {
        canvas.drawPoints(PointMode.points,[pointsListDrawData[i].points] , pointsListDrawData[i].paint);
      }
    }
  }

  bool shouldDrawPoint(int i) => pointsListDrawData[i].points != Offset(0.0,0.0) && pointsListDrawData.length > i+1 && pointsListDrawData[i + 1].points == Offset(0.0,0.0);

  bool shouldDrawLine(int i) => pointsListDrawData[i].points != Offset(0.0,0.0) && pointsListDrawData.length > i+1 && pointsListDrawData[i+1].points != Offset(0.0,0.0);

  @override
  bool shouldRepaint(Drawing oldDelegate) => true;
}