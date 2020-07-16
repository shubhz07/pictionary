import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutterapp/src/screens/homePage.dart';
import 'package:flutterapp/src/models/drawingpoints.dart';
import 'package:flutterapp/src/models/custompainter.dart';
import 'dart:math' as math;
import 'package:flutterapp/src/dialogs/width_dialog.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutterapp/src/models/drawing_functionality.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DrawingPage extends StatefulWidget {
  final Ip ipObj;
  final String userName;
  DrawingPage({Key key, @required this.ipObj, @required this.userName}) : super(key: key);
  _DrawingPageState createState() => _DrawingPageState(ipVal: ipObj.ip, userName: userName);
}

double customStrokeWidth = 4;

class _DrawingPageState extends State<DrawingPage> with TickerProviderStateMixin {
  String ipVal;
  String userName;
  String send_Message = "";
  IOWebSocketChannel channel;
  StrokeCap strokeCap = StrokeCap.round;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamController chatStreamController = new StreamController();
  Stream _chatStream;
  Stream _stream;
  var sendMessageController = new TextEditingController();
  AnimationController controller;
  
  _DrawingPageState({Key key, this.ipVal, this.userName});

  DrawingFunctionality _drawingFunc = DrawingFunctionality();

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(ipVal);
    _stream = channel.stream.map((data) => processStreamData(data));
    _drawingFunc.endPointList.add(DrawingPoints(points: Offset(0.0,0.0), paint: Paint()));
    controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _chatStream = chatStreamController.stream;
  }

  void processStreamData(data) {
    print("Received Data: " + data);
    _drawingFunc.tempListServer.clear();
    _drawingFunc.tempListServer = _drawingFunc.received_From_Server(data, chatStreamController);
    _drawingFunc.serverDrawnList = _drawingFunc.serverDrawnList + _drawingFunc.endPointList + _drawingFunc.tempListServer;
    if(_drawingFunc.erase){
      _drawingFunc.tempList.clear();
      _drawingFunc.userDrawnList.clear();
      _drawingFunc.serverDrawnList.clear();
      _drawingFunc.tempListServer.clear();
      _drawingFunc.erase = false;
    }
    return data;
  }
  
  Color pickerColor = new Color(0xff443a49);

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );

    return Scaffold(
      key: _scaffoldKey,
      body:SlidingUpPanel(
        panel: ChatPanel(context),
        minHeight: 60,
        parallaxEnabled: true,
        color: Colors.lightGreen.shade300,
        collapsed: Center(child: Text("Slide up to Chat " + userName)),
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
                        onPanStart: (details) {
                          setState(() {
                            _drawingFunc.userDrawnList.add(DrawingPoints(points: details.localPosition, paint: Paint()
                              ..strokeCap = strokeCap
                              ..color = pickerColor
                              ..strokeWidth = customStrokeWidth
                            ));

                            _drawingFunc.tempList.add(DrawingPoints(points: details.localPosition, paint: Paint()
                              ..strokeCap = strokeCap
                              ..color = pickerColor
                              ..strokeWidth = customStrokeWidth
                            ));
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _drawingFunc.userDrawnList.add(DrawingPoints(points: details.localPosition, paint: Paint()
                              ..strokeCap = strokeCap
                              ..color = pickerColor
                              ..strokeWidth = customStrokeWidth
                            ));

                            _drawingFunc.tempList.add(DrawingPoints(points: details.localPosition, paint: Paint()
                              ..strokeCap = strokeCap
                              ..color = pickerColor
                              ..strokeWidth = customStrokeWidth
                            ));
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _drawingFunc.userDrawnList.add(DrawingPoints(points: Offset(0.0,0.0), paint: Paint()));
                            _drawingFunc.tempList.add(DrawingPoints(points: Offset(0.0,0.0), paint: Paint()));
                            _drawingFunc.send_To_Server(send_Message, userName, channel);
                            _drawingFunc.tempList.clear();
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
                                    pointsListDrawData: _drawingFunc.userDrawnList,
                                  ),
                                );
                              }
                              else if(snapshot.hasData)
                              {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: Drawing(
                                    pointsListDrawData: _drawingFunc.userDrawnList + _drawingFunc.serverDrawnList,
                                  ),
                                );
                              }
//                          No data on stream
                              else{
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: Drawing(
                                    pointsListDrawData: _drawingFunc.userDrawnList + _drawingFunc.serverDrawnList,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    DrawingTools(context),
                    DrawingToolsAnimation(context),

                  ]
              ),
            ),
            SizedBox(height: 60,),
          ],
        ),
      ),
    );
  }

  Widget DrawingTools(BuildContext context){
      return Positioned(
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
                      _drawingFunc.erase = true;
                      _drawingFunc.tempList.clear();
                      _drawingFunc.userDrawnList.clear();
                      _drawingFunc.serverDrawnList.clear();
                      _drawingFunc.tempListServer.clear();
                      _drawingFunc.send_To_Server(send_Message, userName, channel);
                      _drawingFunc.erase = false;
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
                            colorPallete(context);
                          });
                        }
                    )
                )
            ),
          ],
        ),
      );
  }

  Widget colorPallete(BuildContext context){
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

  Widget DrawingToolsAnimation(BuildContext context){
      return Positioned(
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
      );
  }

  Widget ChatPanel(BuildContext context){
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
//            SizedBox(height: 10,),
          Container(
            height: 350,
            child: StreamBuilder(
              stream: _chatStream,
              builder:(context, snapshot){
                return Container(
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    borderRadius: new BorderRadius.only(
                      topLeft: const Radius.circular(20.0),
                      topRight: const Radius.circular(20.0),
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _drawingFunc.chatMessage_List.length,
                    itemBuilder: (context, index) =>
                        ListTile(
                          leading: RawMaterialButton(
                            onPressed: () {},
                            elevation: 2.0,
                            fillColor: Colors.black26,
                            child: Text("${_drawingFunc.chatMessage_List[index].senderName}",
                              style: TextStyle(color: Colors.white),),
                            padding: EdgeInsets.all(19.0),
                            shape: CircleBorder(),
                          ),
                          title: Text("${_drawingFunc.chatMessage_List[index].Message}"),
                        ),
                    reverse: false,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 5,),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10,),
          Stack(
            children: [
              Theme(
                data: Theme.of(context).copyWith(splashColor: Colors.transparent),
                child: TextField(
                  controller: sendMessageController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Type a message!',
                    contentPadding:
                    const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(25.7),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(25.7),
                    ),
                  ),
                ),
              ),
              Positioned(
                right:7,
                child: SizedBox(
                  width: 60,
                  child: FlatButton(
                    onPressed: () {
                      setState(() {
                        send_Message = sendMessageController.text;
                        _drawingFunc.userSentMessage(userName,send_Message);
                        _drawingFunc.send_To_Server(send_Message, userName, channel);
                        send_Message = "";
                        sendMessageController.clear();
                      });
                    },
                    child: Icon(Icons.send, color: Colors.blue,),
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 10,),
        ]
    );
  }
  
  @override
  void dispose(){
    super.dispose();
    channel.sink.close();
    chatStreamController.close();
  }

}