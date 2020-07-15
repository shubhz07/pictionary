import 'package:flutterapp/src/models/drawingpoints.dart';
import 'package:bloc/bloc.dart';

enum listEvent {addPoints, addZeroes}

class userlist_Bloc extends Bloc<listEvent, List<DrawingPoints>>{
  @override
  // TODO: implement initialState
  List<DrawingPoints> get initialState => throw UnimplementedError();

  @override
  Stream<List<DrawingPoints>> mapEventToState(listEvent event) {
    // TODO: implement mapEventToState
    throw UnimplementedError();
  }

}