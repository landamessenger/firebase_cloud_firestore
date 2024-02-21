import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object/object.dart' as object;

import 'firestore_document_entity.dart';
import 'reaction.dart';

class FirestoreDocumentManager<T extends object.Object<T>>
    extends FirestoreDocumentEntity {
  ObservableReaction<T>? observableReaction;

  FirestoreDocumentManager({required super.reference});

  void documentObserver(
    Future Function(T)? callback,
    Future Function()? notExistCallback,
  ) {
    // ignore: cancel_subscriptions
    StreamSubscription<DocumentSnapshot> s = reference.snapshots().listen(
      (documentSnapshot) async {
        if (documentSnapshot.exists && callback != null) {
          var data = documentSnapshot.data() as Map<String, dynamic>;
          T instance = object.ObjectLib().instance<T>(T, data['id']);
          await callback(instance.fromJson(data));
        } else if (!documentSnapshot.exists && notExistCallback != null) {
          final snap = await reference.get();
          if (snap.exists) {
            if (callback != null) {
              var data = snap.data() as Map<String, dynamic>;
              T instance = object.ObjectLib().instance<T>(T, data['id']);
              await callback(instance.fromJson(data));
            }
          } else {
            await notExistCallback();
          }
        }
      },
    );
    observableReaction = ObservableReaction<T>(s);
  }

  void resume() => observableReaction?.resume();

  void pause() => observableReaction?.pause();

  Future<void> cancel() => observableReaction?.cancel() ?? Future.value();
}
