import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object/object.dart' as object;

import '../fire/document.dart';
import '../firestore_singleton.dart';
import '../firestore_view_model.dart';

extension DocumentReferenceExt on DocumentReference {
  Document asDocument() => Document(reference: this);
}

extension DocumentExt on Document {
  Future<T?> get<T extends object.Object<T>>() {
    return FirestoreSingleton().getDocument<T>(reference);
  }

  void listen<T extends object.Object<T>>({
    FirestoreViewModel? viewModel,
    Future Function(T)? callback,
    Future Function()? notExistCallback,
  }) {
    (viewModel ?? FirestoreSingleton()).listenDocument<T>(
      reference: reference,
      callback: callback,
      notExistCallback: notExistCallback,
    );
  }
}
