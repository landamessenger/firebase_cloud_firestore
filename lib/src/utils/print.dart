import 'package:flutter/foundation.dart';

import '../firestore_manager.dart';

void printDebug(Object? object) {
  if (FirestoreManager().debug) {
    if (kDebugMode) {
      print('🔥 $object');
    }
  }
}
