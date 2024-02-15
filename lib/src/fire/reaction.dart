import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object/object.dart' as object;

class ObservableReaction<T extends object.Object<T>> {
  StreamSubscription<DocumentSnapshot> streamSubscription;

  ObservableReaction(this.streamSubscription);

  resume() {
    streamSubscription.resume();
  }

  pause() {
    streamSubscription.pause();
  }

  bool isPaused() {
    return streamSubscription.isPaused;
  }

  Future<dynamic> cancel() {
    return streamSubscription.cancel();
  }
}
