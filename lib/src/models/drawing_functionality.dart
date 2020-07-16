import 'dart:async';

import 'package:flutterapp/src/models/drawingpoints.dart';
import 'package:flutterapp/src/models/userdetails.dart';
import 'package:flutterapp/src/screens/drawingpage.dart';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

class DrawingFunctionality{
  List<DrawingPoints> userDrawnList = List();
  List<DrawingPoints> tempList = List();
  List<DrawingPoints> tempListServer = List();
  List<DrawingPoints> serverDrawnList = List();
  List<DrawingPoints> endPointList = List();
  List send_mappedlist = List();
  List received_mapsList = List();
  List chatData = List();
  List<DrawingPoints> decodedData = List();
  List<UserDetails> chatMessage_List = List();

  Map<String, dynamic> send_key = new Map<String,dynamic>();
  Map<String, dynamic> received_key = new Map<String,dynamic>();
  Map<String, String> send_chat_key = new Map<String,String>();
  Map<String, dynamic> received_chat_key = new Map<String,dynamic>();
  Map<String, dynamic> chat_key = new Map<String, dynamic>();

  String received_chat_Message = "";
  String receiver_Username = "";
  bool erase = false;

  UserDetails _userDetailsObj = UserDetails();
  DrawingPage _drawingPage = DrawingPage();

  List<DrawingPoints> received_From_Server(String receivedData, StreamController chatStreamController){
    received_key.clear();
    chat_key.clear();
    received_key = jsonDecode(receivedData);
    received_mapsList = received_key["PointsList"];
    erase = received_key["Erase"];
    if(received_key.containsKey("Chat")){
      chat_key = received_key["Chat"];
      received_chat_Message = chat_key["Message"];
      receiver_Username = chat_key["User"];
      _userDetailsObj.senderName = receiver_Username;
      _userDetailsObj.Message = received_chat_Message;
      chatMessage_List.add(_userDetailsObj);
    }
    if(received_mapsList.isNotEmpty){
      decodedData = received_mapsList.map((e) => DrawingPoints.fromJson(e)).toList();
    }
    chatStreamController.sink.add("Chat Message Received");
    return decodedData;
  }

  void send_To_Server(String send_Message, String userName, IOWebSocketChannel channel){
    if(tempList.isNotEmpty){
      send_mappedlist = tempList.map((e) => e.toJson()).toList();
    }else{
      send_mappedlist = List();
    }
    send_chat_key.clear();
    send_key.clear();
    if(send_Message.isNotEmpty){
      send_chat_key["Message"] = send_Message;
      send_chat_key["User"] = userName;
      send_key["Chat"] = send_chat_key;
    }
    send_key["PointsList"] = send_mappedlist;
    send_key["Erase"] = erase;
    String jsonPointData = jsonEncode(send_key);
    print("****************************************************************************************");
    print("Sent Message");
    print("TempList len:" + tempList.length.toString());
    print(jsonPointData);
    print("UserDrawnList len:" + userDrawnList.length.toString());
    print("******************************************************************************************");
    channel.sink.add(jsonPointData);
  }

  void userSentMessage(String userName, String send_Message){
    _userDetailsObj = UserDetails();
    _userDetailsObj.senderName = userName;
    _userDetailsObj.Message = send_Message;
    chatMessage_List.add(_userDetailsObj);
  }

}