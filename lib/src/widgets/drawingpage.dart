import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutterapp/src/widgets/homePage.dart';
import 'package:flutterapp/src/models/drawingpoints.dart';
import 'package:flutterapp/src/models/custompainter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:math' as math;
import 'package:flutterapp/src/dialogs/width_dialog.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:dash_chat/dash_chat.dart';

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
  String send_Message;
  String received_chat_data ;
  String received_chat_Message;
  String receiver_Username;
  IOWebSocketChannel channel;
  Color pickerColor = new Color(0xff443a49);
  StrokeCap strokeCap = StrokeCap.round;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Stream<dynamic> _stream;
  bool erase = false;
  var sendMessageController = new TextEditingController();
  AnimationController controller;
  Map<String, dynamic> send_key = new Map<String,dynamic>();
  Map<String, dynamic> received_key = new Map<String,dynamic>();
  Map<String, String> send_chat_key = new Map<String,String>();
  Map<String, dynamic> received_chat_key = new Map<String,dynamic>();
  Map<String, dynamic> chat_key = new Map<String, dynamic>();
  StreamController<dynamic> _chatStreamController = new StreamController();
  Stream<dynamic> _chatStream;

  _DrawingPageState({Key key, this.ipVal, this.userName});

  List<DrawingPoints> userDrawnList = List();
  List<DrawingPoints> tempList = List();
  List<DrawingPoints> tempListServer = List();
  List<DrawingPoints> serverDrawnList = List();
  List<DrawingPoints> endPointList = List();
  List send_mappedlist = List();
  List<dynamic> received_mapsList;
  List chatData = List();
  List<DrawingPoints> decodedData;
  List<String> chatMessage_List = List();

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
    _chatStream = chatStreamFunction();
  }

  Stream<String> chatStreamFunction() async* {
    _chatStreamController.stream.listen((data) {
      print("DataReceived: "+data);
      return data;
    }, onDone: () {
      print("Chat Stream Done");
    }, onError: (error) {
      print("Chat Stream Error");
    });

  }


  void processStreamData(data) {
    print("Received Data: " + data);
    tempListServer.clear();
    tempListServer = received_From_Server(data);
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
        panel:Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
//            SizedBox(height: 10,),
            Container(
              height: 350,
              child: StreamBuilder<String>(
                stream: _chatStream,
                builder:(context, snapshot){
                  if(snapshot.hasData){
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: chatMessage_List.length,
                      itemBuilder: (context, index) =>
                          Card(
                            child: ListTile(
//                            leading: Text("$userName  ->",
//                              style: TextStyle(color: Colors.red),),
                                title: Text("${chatMessage_List[index]}")
                            ),

                          ),
                      reverse: false,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 5,),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: chatMessage_List.length,
                    itemBuilder: (context, index) =>
                        Card(
                          child: ListTile(
//                            leading: Text("$userName  ->",
//                              style: TextStyle(color: Colors.red),),
                              title: Text("${chatMessage_List[index]}")
                          ),

                        ),
                    reverse: false,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 5,),
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
                          send_To_Server();
                          chatMessage_List.add(send_Message);
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
          ),
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
                            send_To_Server();
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
                                    send_To_Server();
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

  void send_To_Server(){
    if(tempList.isNotEmpty){
      send_mappedlist = tempList.map((e) => e.toJson()).toList();
    }else{
      send_mappedlist = List();
    }
    if(send_Message.isNotEmpty){
      send_chat_key["Message"] = send_Message;
      send_chat_key["User"] = userName;
    }
    send_key["PointsList"] = send_mappedlist;
    send_key["Erase"] = erase;
    send_key["Chat"] = send_chat_key;
    String jsonPointData = jsonEncode(send_key);
    print("****************************************************************************************");
    print("Sent Message");
    print("TempList len:" + tempList.length.toString());
    print(jsonPointData);
    print("UserDrawnList len:" + userDrawnList.length.toString());
    print("******************************************************************************************");
    channel.sink.add(jsonPointData);
  }

  List<DrawingPoints> received_From_Server(String receivedData){
    received_key = jsonDecode(receivedData);
    received_mapsList = received_key["PointsList"];
    erase = received_key["Erase"];
    chat_key = received_key["Chat"];
//    received_chat_key = jsonDecode(received_chat_data);
    received_chat_Message = chat_key["Message"];
    receiver_Username = chat_key["User"];
    if(receiver_Username.isNotEmpty && received_chat_Message.isNotEmpty){
      _chatStreamController.sink.add("Chat Message Received");
      chatMessage_List.add(receiver_Username+"->"+received_chat_Message);
    }
    if(received_mapsList.isNotEmpty){
      decodedData = received_mapsList.map((e) => DrawingPoints.fromJson(e)).toList();
    }
    return decodedData;
  }

  @override
  void dispose(){
    super.dispose();
    channel.sink.close();
  }

}