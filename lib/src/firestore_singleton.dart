import 'firestore_view_model.dart';

class FirestoreSingleton extends FirestoreViewModel {
  static FirestoreSingleton? _instance;

  FirestoreSingleton._internal();

  factory FirestoreSingleton() {
    _instance ??= FirestoreSingleton._internal();
    return _instance!;
  }
}
