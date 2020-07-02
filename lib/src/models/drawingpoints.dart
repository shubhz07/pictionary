import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/src/widgets/drawingpage.dart';

class DrawingPoints {
  Paint paint;
  Offset points;
  DrawingPoints({this.points, this.paint});

  factory DrawingPoints.fromJson(Map<String,dynamic> json){
    return DrawingPoints(
        points : Offset(json['dx'],json['dy']),
        paint : Paint()
          ..color = Color(json["colorvalue"])
          ..strokeWidth = customStrokeWidth
    );

  }

  Map<String,dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["dx"] = points.dx;
    data["dy"] = points.dy;
    data["colorvalue"] = paint.color.value;
    return data;
  }
}