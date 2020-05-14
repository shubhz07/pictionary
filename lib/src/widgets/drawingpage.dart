import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

final WebSocketChannel channel = IOWebSocketChannel.connect("ws://192.168.225.220:6969/test");

class DrawingPage extends StatefulWidget {
  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  List<DrawingPoints> pointsList = List();
  List<DrawingPoints> tempList = List();
  StrokeCap strokeCap = StrokeCap.butt;
  PaintingContext paintingContext;
  Color pickerColor = new Color(0xff443a49);
  double customStrokeWidth = 4;
  String drawingKey;
//  int startIndex, lastIndex;

// Color selection is done here
  void selectedColor(){
    customStrokeWidth = 4;
    showDialog(
        context: context,
        child: AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color){
                setState(() {
                  pickerColor = color;
                });
              },
            ),
          ),
        )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    Color canvasBackgroundColor = Colors.grey;
    return Scaffold(

      appBar: AppBar(
        title: Text('Pictionary'),
        centerTitle: true,
        leading: BackButton(onPressed: (){
          return Navigator.pop(context);
        }),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: Stack(
                children: <Widget>[
                  Positioned(
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState( () {
                          pointsList.add(DrawingPoints(
                              points: details.localPosition,
                              paint: Paint()
                                ..strokeCap = strokeCap
                                ..isAntiAlias = true
                                ..color = pickerColor
                                ..strokeWidth = customStrokeWidth
                          ));
                          tempList.add(DrawingPoints(
                              points: details.localPosition,
                              paint: Paint()
                                ..strokeCap = strokeCap
                                ..isAntiAlias = true
                                ..color = pickerColor
                                ..strokeWidth = customStrokeWidth
                          ));
                        });

                      },
                      onPanStart: (details) {
                        setState(() {
//                          startIndex = 0 ;
                          pointsList.add(DrawingPoints(
                              points: details.localPosition,
                              paint: Paint()
                                ..strokeCap = strokeCap
                                ..isAntiAlias = true
                                ..color = pickerColor
                                ..strokeWidth = 6.0
                          ));
                          tempList.add(DrawingPoints(
                              points: details.localPosition,
                              paint: Paint()
                                ..strokeCap = strokeCap
                                ..isAntiAlias = true
                                ..color = pickerColor
                                ..strokeWidth = customStrokeWidth
                          ));
//                          startIndex = pointsList.length-1;
                        });

                      },
                      onPanEnd: (details) {
                        setState(() {
//                          lastIndex = 0 ;
                          pointsList.add(DrawingPoints(points: Offset(0.0,0.0), paint: Paint()));
                          tempList.add(DrawingPoints(points: Offset(0.0,0.0), paint: Paint()));
                          sendMessage();
                          tempList.clear();
//                          lastIndex = pointsList.length-1;
                        });
                      },

                      child: Container(

                        child: ClipRect(

                          child: CustomPaint(
                            size: Size.infinite,
                            painter: Drawing(
                              pointsList: pointsList,
                            ),
                          ),
                        ),
                        color: canvasBackgroundColor,
                      ),
                    ),
                  ),
//              Opens color Pallete
                  Positioned(
                    bottom: 10.0,
                    right: 10.0,
                    child: FloatingActionButton(
                      heroTag: "colorPallete",
                      onPressed: () {
                        setState(() {
                          selectedColor();
                        });
                      },
                      child: Icon(Icons.color_lens),
                      backgroundColor: Colors.lightGreen,
                    ),
                  ),
//              Selects Eraser
                  Positioned(
                    bottom: 80.0,
                    right: 10.0,
                    child: FloatingActionButton(
                      heroTag: "Eraser",
                      onPressed: () {
                        setState(() {
                          pickerColor = canvasBackgroundColor;
                          customStrokeWidth = 50;
                        });
                      },
                      child: Icon(Icons.stop),
                      backgroundColor: Colors.lightGreen,
                    ),
                  ),

                ]
            ),
          ),
          Expanded(
              child:
              StreamBuilder(
                  stream: channel.stream,
                  builder: (context, snapshot) {
                    if(snapshot.hasData && !snapshot.hasError){
                      String receivedData = snapshot.data.toString();
                      tempList = receivedMessage(receivedData);
                      print(tempList);
                      return Text("tempList");
                    }
                    else
                      return Text("No Data");
              }
          )
          ),
        ],
      ),
    );
  }

  //  send to server
  void sendMessage(){
    DrawingPoints pointData;
//    pointData = pointsList[i];
//    print(pointsList);
    List mappedlist = tempList.map((e) => e.toJson()).toList();
//    print(mappedlist);
//    Map<String, dynamic> map = pointData.toJson();
    String jsonPointData = jsonEncode(mappedlist);
    print("Sent Message");
    print(jsonPointData);
    print("**********************");
    channel.sink.add(jsonPointData);
  }

  List<DrawingPoints> receivedMessage(String receivedData){
    List<DrawingPoints> decodedData;
    Iterable i = jsonDecode(receivedData);
    decodedData =(i.map((e) => DrawingPoints.fromJson(e)).toList());
    return decodedData;
  }

  @override
  void dispose(){
    super.dispose();
  }

}


//Painting is done here
class Drawing extends CustomPainter {
  Drawing({this.pointsList});
  List<DrawingPoints> pointsList;
  List<Offset> offsetPoints = List();

  @override
  void paint(Canvas canvas, Size size){
    for(int i=0; i < pointsList.length-1; i++){
//      Drawing lines when pan action
      if(pointsList[i].points != Offset(0.0,0.0) && pointsList[i+1].points != Offset(0.0,0.0)){
        canvas.drawLine(pointsList[i].points, pointsList[i+1].points, pointsList[i].paint);
      }
//      Drawing points when user taps
      else if (pointsList[i].points != Offset(0.0,0.0) && pointsList[i + 1].points == Offset(0.0,0.0)) {
        offsetPoints.clear();
        offsetPoints.add(pointsList[i].points);
        canvas.drawPoints(PointMode.points, offsetPoints, pointsList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(Drawing oldDelegate) => true;
}

class DrawingPoints {
  Paint paint;
  Color color;
  Offset points;
  DrawingPoints({this.points, this.paint});

  DrawingPoints.fromJson(Map<String,dynamic> json){
        Color color;
        this.points = Offset(json['dx'],json['dy']);
        this.color = Color(json['colorvalue']);
  }

  Map<String,dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["dx"] = points.dx;
    data["dy"] = points.dy;
    data["colorvalue"] = paint.color.value;
    return data;
  }
}