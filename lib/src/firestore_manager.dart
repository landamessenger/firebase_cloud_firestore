import 'package:flutter/material.dart';

import 'firestore_view_model.dart';

class FirestoreManager extends FirestoreViewModel {
  static FirestoreManager? _instance;

  FirestoreManager._internal();

  factory FirestoreManager() {
    _instance ??= FirestoreManager._internal();
    return _instance!;
  }

  GlobalKey<ScaffoldMessengerState>? key;

  void showSnackBar(String message) => key?.currentState?.showSnackBar(
        SnackBar(
          content: Text('🔥 $message'),
        ),
      );
}
