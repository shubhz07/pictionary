import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutterapp/src/widgets/homePage.dart';
import 'package:flutterapp/src/models/drawingpoints.dart';
import 'package:flutterapp/src/models/custompainter.dart';

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
  bool erase = false;

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
//                          No data on stream
                            else if(snapshot.hasData)
                              {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: Drawing(
                                    pointsListDrawData: userDrawnList + serverDrawnList,
                                  ),
                                );
                              }
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
                          erase = true;
                          tempList.clear();
                          userDrawnList.clear();
                          serverDrawnList.clear();
                          tempListServer.clear();
                          sendMessage();
                          erase = false;
                        });
                      },
                      child: Icon(Icons.stop),
                      backgroundColor: Colors.lightGreen,
                    ),
                  ),

                ]
            ),
          ),
//          RaisedButton(onPressed: () => _scaffoldKey.currentState.showSnackBar(snackBar),child: Text("Check IP"),),
        ],
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