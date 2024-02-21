import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_query.dart';

class ObservableQueryReaction<T> {
  StreamSubscription<QuerySnapshot>? streamSubscription;

  FirestoreQuery? fireQuery;

  Future Function(List<T>, int)? callback;

  Future Function(List<T>, int)? deletionCallback;

  Future Function(int)? emptyCallback;

  DocumentSnapshot? firstDocSnapshot;

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
