import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object/object.dart' as object;

import '../fire/document.dart';
import '../firestore_manager.dart';
import '../firestore_view_model.dart';

extension DocumentReferenceExt on DocumentReference {
  Document asDocument() => Document(reference: this);
}

extension DocumentExt on Document {
  Future<T?> get<T extends object.Object<T>>() {
    return FirestoreManager().getDocument<T>(reference);
  }

  void listen<T extends object.Object<T>>({
    FirestoreViewModel? viewModel,
    Future Function(T)? callback,
    Future Function()? notExistCallback,
  }) {
    (viewModel ?? FirestoreManager()).listenDocument<T>(
      reference: reference,
      callback: callback,
      notExistCallback: notExistCallback,
    );
  }

  void resume({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).resumeDocument(reference: reference);

  void pause({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).pauseDocument(reference: reference);

  void cancel({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).cancelDocument(reference: reference);
}
