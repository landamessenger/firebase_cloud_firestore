import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firestore_view_model.dart';

class FirestoreManager extends FirestoreViewModel {
  static FirestoreManager? _instance;

  FirestoreManager._internal();

  var lockTime = const Duration(seconds: 0);

  factory FirestoreManager() {
    _instance ??= FirestoreManager._internal();
    return _instance!;
  }

  bool debug = kDebugMode;

  GlobalKey<ScaffoldMessengerState>? key;

  void showSnackBar(String message) => key?.currentState?.showSnackBar(
        SnackBar(
          content: Text('🔥 $message'),
        ),
      );
}
