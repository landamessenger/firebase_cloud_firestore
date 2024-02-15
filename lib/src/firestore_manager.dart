import 'firestore_view_model.dart';

class FirestoreManager extends FirestoreViewModel {
  static FirestoreManager? _instance;

  FirestoreManager._internal();

  factory FirestoreManager() {
    _instance ??= FirestoreManager._internal();
    return _instance!;
  }
}
