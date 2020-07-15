import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutterapp/src/widgets/homePage.dart';
import 'package:flutterapp/src/models/drawingpoints.dart';
import 'package:flutterapp/src/models/custompainter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:math' as math;
import 'package:flutterapp/src/dialogs/width_dialog.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class DrawingPage extends StatefulWidget {
  final Ip ipObj;
  DrawingPage({Key key, @required this.ipObj}) : super(key: key);
  _DrawingPageState createState() => _DrawingPageState(ipVal: ipObj.ip);
}

double customStrokeWidth = 4;

class _DrawingPageState extends State<DrawingPage> with TickerProviderStateMixin {
  String ipVal;
  IOWebSocketChannel channel;
  Color pickerColor = new Color(0xff443a49);
  StrokeCap strokeCap = StrokeCap.round;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Stream<dynamic> _stream;
  bool erase = false;
  AnimationController controller;

  _DrawingPageState({Key key, this.ipVal});

  List<DrawingPoints> userDrawnList = List();
  List<DrawingPoints> tempList = List();
  List<DrawingPoints> tempListServer = List();
  List<DrawingPoints> serverDrawnList = List();
  List<DrawingPoints> endPointList = List();
  List mappedlist = List();
  List<DrawingPoints> decodedData;

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
    controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void processStreamData(data) {
    print("Received Data: " + data);
    tempListServer.clear();
    tempListServer = receivedMessage(data);
    serverDrawnList = serverDrawnList + endPointList + tempListServer;
    if(erase){
      tempList.clear();
      userDrawnList.clear();
      serverDrawnList.clear();
      tempListServer.clear();
      erase = false;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    Color canvasBackgroundColor = Colors.grey;
    final snackBar = SnackBar(content: Text(ipVal), backgroundColor: Colors.red);
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );

    return Scaffold(
      key: _scaffoldKey,
//      appBar: AppBar(
//        title: Text('Pictionary'),
//        centerTitle: true,
//        leading: BackButton(onPressed: (){
//          return Navigator.pop(context);
//        }),
//      ),
      body:SlidingUpPanel(
        panel: Center(
          child: Text("The entire chat window"),
        ),
        minHeight: 60,
        parallaxEnabled: true,
        color: Colors.blue.shade300,
        collapsed: Center(child: Text("Slide up to Chat")),
        borderRadius: radius,

        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
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
                          color: Colors.white,
                          child: StreamBuilder(
                            stream: _stream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: Drawing(
                                    pointsListDrawData: userDrawnList,
                                  ),
                                );
                              }
                              else if(snapshot.hasData)
                              {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: Drawing(
                                    pointsListDrawData: userDrawnList + serverDrawnList,
                                  ),
                                );
                              }
//                          No data on stream
                              else{
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: Drawing(
                                    pointsListDrawData: userDrawnList + serverDrawnList,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
//              Drawing Tools
                    Positioned(
                      bottom: 65,
                      right: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
//                    Clear Screen
                          Container(
                            height: 70.0,
                            width: 56.0,
                            alignment: FractionalOffset.topCenter,
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: controller,
                                curve: Interval(0.0, 1.0 - 0 / 3 / 2.0, curve: Curves.easeOut),
                              ),
                              child: FloatingActionButton(
                                heroTag: "clear",
                                mini: true,
                                child: Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    erase = true;
                                    tempList.clear();
                                    userDrawnList.clear();
                                    serverDrawnList.clear();
                                    tempListServer.clear();
                                    sendMessage();
                                    erase = false;
                                  });
                                },
                              ),
                            ),
                          ),
//                    Change width
                          Container(
                            height: 70.0,
                            width: 56.0,
                            alignment: FractionalOffset.topCenter,
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: controller,
                                curve: Interval(0.0, 1.0 - 1 / 3 / 2.0, curve: Curves.easeOut),
                              ),
                              child: FloatingActionButton(
                                heroTag: "Width",
                                mini: true,
                                child: Icon(Icons.lens),
                                onPressed: () async {
                                  double temp;
                                  temp = await showDialog(
                                      context: context,
                                      builder: (context) =>
                                          WidthDialog(
                                              strokeWidth: customStrokeWidth));
                                  if (temp != null) {
                                    setState(() {
                                      customStrokeWidth = temp;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
//                    Change color
                          Container(
                              height: 70.0,
                              width: 56.0,
                              alignment: FractionalOffset.topCenter,
                              child: ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: controller,
                                    curve:
                                    Interval(0.0, 1.0 - 2 / 3 / 2.0, curve: Curves.easeOut),
                                  ),
                                  child: FloatingActionButton(
                                      heroTag: "color pallete",
                                      mini: true,
                                      child: Icon(Icons.color_lens),
                                      onPressed: () async {
                                        setState(() {
                                          selectedColor();
                                        });
                                      }
                                  )
                              )
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton(
                        heroTag: "animation",
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (BuildContext context, Widget child) {
                            return Transform(
                              transform: Matrix4.rotationZ(controller.value * 0.5 * math.pi),
                              alignment: FractionalOffset.center,
                              child: Icon(Icons.brush),
                            );
                          },
                        ),
                        onPressed: () {
                          if (controller.isDismissed) {
                            controller.forward();
                          } else {
                            controller.reverse();
                          }
                        },
                      ),
                    ),
                  ]
              ),
            ),
            SizedBox(height: 60,),
//          RaisedButton(onPressed: () => _scaffoldKey.currentState.showSnackBar(snackBar),child: Text("Check IP"),),
          ],
        ),
      ),

    );
  }

  //  send to server
  void sendMessage(){
    if(tempList.isNotEmpty){
      mappedlist = tempList.map((e) => e.toJson()).toList();
    }else{
      mappedlist = List();
    }
    Map<String, dynamic> key = new Map<String,dynamic>();
    key["PointsList"] = mappedlist;
    key["Erase"] = erase;
    String jsonPointData = jsonEncode(key);
    print("****************************************************************************************");
    print("Sent Message");
    print("TempList len:" + tempList.length.toString());
    print(jsonPointData);
    print("UserDrawnList len:" + userDrawnList.length.toString());
    print("******************************************************************************************");
    channel.sink.add(jsonPointData);
  }

  List<DrawingPoints> receivedMessage(String receivedData){
    Map<String, dynamic> key = new Map<String,dynamic>();
    key = jsonDecode(receivedData);
    List<dynamic> mapsList = key["PointsList"];
    erase = key["Erase"];
    if(mapsList.isNotEmpty){
      decodedData = mapsList.map((e) => DrawingPoints.fromJson(e)).toList();
    }
    return decodedData;
  }

  @override
  void dispose(){
    super.dispose();
    channel.sink.close();
  }

}