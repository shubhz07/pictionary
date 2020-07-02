import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutterapp/src/widgets/homePage.dart';
import 'package:http/http.dart' as http;


class AIPage extends StatefulWidget {
  final Ip ipObj;
  AIPage({Key key, @required this.ipObj}) : super(key: key);
  _AIPageState createState() => _AIPageState(ipVal: ipObj.ip);
}

double customStrokeWidth = 4;

class _AIPageState extends State<AIPage> {
  String ipVal;
  IOWebSocketChannel channel;
  Color pickerColor = new Color(0xff443a49);
  StrokeCap strokeCap = StrokeCap.round;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<dynamic> _future;
  bool erase = false;

  _AIPageState({Key key, this.ipVal});

  List<DrawingPoints> tempListServer = List();
  List<DrawingPoints> decodedData;


  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(ipVal);
    _future = fetchAIData();
  }

  Future<List<DrawingPoints>> fetchAIData() async {
    final response = await http.get('https://transform-vmp42eg4nq-de.a.run.app/transform/apple');

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      print("Received Data: " + response.body);
      tempListServer.clear();
      tempListServer = receivedMessage(response.body);
      return tempListServer;
//      return DrawingPoints.fromJson(json.decode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
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
                    child: Container(
                      color: Colors.white,
                      child: FutureBuilder<List<DrawingPoints>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Center(
                              child: CustomPaint(
                                size: Size.square(1),
                                painter: Drawing(
                                  pointsListDrawData: snapshot.data,
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(child: Text("${snapshot.error}"));
                          }
                          // By default, show a loading spinner.
                          return Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                  ),
                ]
            ),
          ),
        ],
      ),
    );
  }


  List<DrawingPoints> receivedMessage(String receivedData){
    Map<String, dynamic> drawingkey = new Map<String,dynamic>();
    Map<String, dynamic> key = new Map<String,dynamic>();
    drawingkey = jsonDecode(receivedData);
    key = jsonDecode(drawingkey["drawing"]);
    print(drawingkey["drawing"]);
    print(key["PointsList"]);
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
    double dx = 0.0;
    double dy = 0.0;
    dx = json["dx"].toDouble();
    dy = json["dy"].toDouble();
    return DrawingPoints(
//        points : Offset(double.parse(json['dx']),double.parse(json['dy'])),
        points : Offset(dx,dy),
        paint : Paint()
          ..color = Color(json["colorvalue"])
          ..strokeWidth = customStrokeWidth
    );
  }
}