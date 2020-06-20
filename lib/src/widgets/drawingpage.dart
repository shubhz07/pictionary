import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutterapp/src/widgets/homePage.dart';

class DrawingPage extends StatefulWidget {
  final Ip ipObj;
  DrawingPage({Key key, @required this.ipObj}) : super(key: key);
  _DrawingPageState createState() => _DrawingPageState(ipVal: ipObj.ip);
}

double customStrokeWidth = 4;

class _DrawingPageState extends State<DrawingPage> {
  String ipVal;
  IOWebSocketChannel channel;
  Color pickerColor = new Color(0xff443a49);
  StrokeCap strokeCap = StrokeCap.round;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Stream<dynamic> _stream;
  StreamSubscription<dynamic> subscription;

  _DrawingPageState({Key key, this.ipVal});

  List<DrawingPoints> userDrawnList = List();
  List<DrawingPoints> tempList = List();
  List<DrawingPoints> tempListServer = List();
  List<DrawingPoints> serverDrawnList = List();
  List<DrawingPoints> endPointList = List();
  List<DrawingPoints> combinedList = List();

// Color selection is done here
  void selectedColor(){
    customStrokeWidth = 4;
    showDialog(
        context: context,
        child: AlertDialog(
          title: const Text('Pick a color!'),
          content: Stack(
            children: [
              ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  setState(() {
                    pickerColor = color;
                  });
                },
              ),
              Positioned(bottom: 10,right: 80, child: RaisedButton(color: Colors.blue,onPressed: () => Navigator.pop(context), child: Text("Close")))
            ]
          ),
        )
    );
  }

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(ipVal);
    _stream = channel.stream.map((data) => processStreamData(data));
    endPointList.add(DrawingPoints(points: Offset(0.0,0.0), paint: Paint()));
    }


  void processStreamData(data) {
    print("Received Data: " + data);
    tempListServer.clear();
    combinedList.clear();
    tempListServer = receivedMessage(data);
    serverDrawnList = serverDrawnList + endPointList + tempListServer;
    combinedList = userDrawnList + serverDrawnList;
  }

  @override
  Widget build(BuildContext context) {
    Color canvasBackgroundColor = Colors.grey;
    final snackBar = SnackBar(content: Text(ipVal), backgroundColor: Colors.red);

    return Scaffold(
      key: _scaffoldKey,
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
//              Gesture Detector
                  Positioned(
                    child: GestureDetector(
                      excludeFromSemantics: true,
                      onPanUpdate: (details) {
                        setState(() {
                          userDrawnList.add(DrawingPoints(points: details.localPosition, paint: Paint()
                                ..strokeCap = strokeCap
                                ..color = pickerColor
                                ..strokeWidth = customStrokeWidth
                          ));

                          tempList.add(DrawingPoints(points: details.localPosition, paint: Paint()
                                ..strokeCap = strokeCap
                                ..color = pickerColor
                                ..strokeWidth = customStrokeWidth
                          ));
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                        userDrawnList.add(DrawingPoints(points: Offset(0.0,0.0), paint: Paint()));
                        tempList.add(DrawingPoints(points: Offset(0.0,0.0), paint: Paint()));
                        sendMessage();
                        tempList.clear();
                        });
                      },
                      child: Container(
                        color: Colors.grey.shade400,
                        child: StreamBuilder(
                          stream: _stream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              print("****************************************************************************************");
                              print("STREAM ERROR: " + snapshot.error);
                              print("****************************************************************************************");
                              return CustomPaint(
                                size: Size.infinite,
                                painter: Drawing(
                                  pointsListDrawData: userDrawnList,
                                ),
                              );
                            }
                            else if(snapshot.hasData) {
                              return CustomPaint(
                                size: Size.infinite,
                                painter: Drawing(
                                  pointsListDrawData: combinedList,
                                ),
                              );
                            }
//                          No data on stream
                            else
                              {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: Drawing(
                                    pointsListDrawData: userDrawnList,
                                  ),
                                );
                              }
                          },
                        ),
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
                          tempList.clear();
                          userDrawnList.clear();
                          serverDrawnList.clear();
                          tempListServer.clear();
                          combinedList.clear();
                      },
                      child: Icon(Icons.stop),
                      backgroundColor: Colors.lightGreen,
                    ),
                  ),

                ]
            ),
          ),
          RaisedButton(onPressed: () => _scaffoldKey.currentState.showSnackBar(snackBar),child: Text("Check IP"),),
        ],
      ),
    );
  }

  //  send to server
  void sendMessage(){
    List mappedlist = tempList.map((e) => e.toJson()).toList();
    String jsonPointData = jsonEncode(mappedlist);
    print("****************************************************************************************");
    print("Sent Message");
    print("TempList len:" + tempList.length.toString());
    print(jsonPointData);
    print("UserDrawnList len:" + userDrawnList.length.toString());
    print("******************************************************************************************");
    channel.sink.add(jsonPointData);
  }

  List<DrawingPoints> receivedMessage(String receivedData){
    List<DrawingPoints> decodedData;
    List<dynamic> mapsList = jsonDecode(receivedData);
    decodedData = mapsList.map((e) => DrawingPoints.fromJson(e)).toList();
    return decodedData;
  }

  @override
  void dispose(){
    super.dispose();
    channel.sink.close();
    subscription.cancel();
  }

}


//Painting is done here
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