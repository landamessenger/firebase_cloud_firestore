
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object/object.dart' as object;

import 'firestore_query.dart';

class ObservableQueryReaction<T extends object.Object<T>> {
  StreamSubscription<QuerySnapshot>? streamSubscription;

  FireQuery? fireQuery;

  Future Function(List<T>)? callback;

  Future Function(List<T>)? deletionCallback;

  Future Function()? emptyCallback;

  DocumentSnapshot? lastDocSnapshot;

  ObservableQueryReaction();

  resume() {
    streamSubscription?.resume();
  }

  pause() {
    streamSubscription?.pause();
  }

  bool isPaused() {
    return streamSubscription?.isPaused ?? false;
  }

  Future<dynamic> cancel() async {
    await streamSubscription?.cancel();
  }
}
