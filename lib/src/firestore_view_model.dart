import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:object/object.dart' as object;

import 'fire/firestore_query.dart';
import 'fire/query_reaction.dart';
import 'fire/reaction.dart';

class FirestoreViewModel {
  Map<String, ObservableReaction<dynamic>> documentsSub =
      <String, ObservableReaction<dynamic>>{};
  Map<String, ObservableQueryReaction<dynamic>> collectionsSub =
      <String, ObservableQueryReaction<dynamic>>{};

  final pathIndexed = <String, int>{};

  final limited = <String>[];

  FirestoreViewModel();

  Future<T?> getDocument<T extends object.Object<T>>(
      DocumentReference reference) async {
    try {
      DocumentSnapshot snapshot = await reference.get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        T instance = object.ObjectLib().instance<T>(T, data['id']);
        instance.fromJson(data);
        return instance;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return null;
  }

  void listenDocument<T extends object.Object<T>>({
    required DocumentReference reference,
    Future Function(T)? callback,
    Future Function()? notExistCallback,
  }) {
    _internalDocumentObserver<T>(
      reference,
      callback,
      notExistCallback,
    );
  }

  Future<List<T>> getCollection<T extends object.Object<T>>({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) async {
    final q = query == null ? reference : query(reference);
    return _getInternalCollection(query: q);
  }

  Future<List<T>> getCollectionGroup<T extends object.Object<T>>({
    required Query<Map<String, dynamic>> reference,
    Query<Object?> Function(Query<Map<String, dynamic>>)? query,
  }) {
    final q = query == null ? reference : query(reference);
    return _getInternalCollection(query: q);
  }

  Future<List<T>> _getInternalCollection<T extends object.Object<T>>({
    required Query<Object?> query,
  }) async {
    final instances = <T>[];
    try {
      final snapshot = await query.get();
      if (snapshot.size == 0) {
        return instances;
      }
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        T instance = object.ObjectLib().instance<T>(T, data['id']);
        instance.fromJson(data);
        instances.add(instance);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return instances;
  }

  void listenCollection<T extends object.Object<T>>({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
    Future Function(List<T>)? callback,
    Future Function(List<T>)? deletionCallback,
    Future Function()? emptyCallback,
  }) {
    final q = query == null ? reference : query(reference);
    _internalCollectionObserver<T>(
      FireQuery(
        '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
      ),
      callback,
      deletionCallback,
      emptyCallback,
      null,
    );
  }

  void listenCollectionGroup<T extends object.Object<T>>({
    required Query<Map<String, dynamic>> reference,
    Query<Object?> Function(Query<Map<String, dynamic>>)? query,
    Future Function(List<T>)? callback,
    Future Function(List<T>)? deletionCallback,
    Future Function()? emptyCallback,
  }) {
    final q = query == null ? reference : query(reference);
    _internalCollectionObserver<T>(
      FireQuery(
        '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
      ),
      callback,
      deletionCallback,
      emptyCallback,
      null,
    );
  }

  void _internalDocumentObserver<T extends object.Object<T>>(
    DocumentReference ref,
    Future Function(T)? callback,
    Future Function()? notExistCallback,
  ) {
    final observation = documentsSub[_docPath(ref)];
    if (observation != null) {
      if (observation.isPaused()) {
        observation.resume();
      }
      return;
    }

    // ignore: cancel_subscriptions
    StreamSubscription<DocumentSnapshot> s = ref.snapshots().listen(
      (documentSnapshot) async {
        if (documentSnapshot.exists && callback != null) {
          var data = documentSnapshot.data() as Map<String, dynamic>;
          T instance = object.ObjectLib().instance<T>(T, data['id']);
          await callback(instance.fromJson(data));
        } else if (!documentSnapshot.exists && notExistCallback != null) {
          final snap = await ref.get();
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
    documentsSub[_docPath(ref)] = ObservableReaction<T>(s);
  }

  void _internalCollectionObserver<T extends object.Object<T>>(
    FireQuery fireQuery,
    Future Function(List<T>)? callback,
    Future Function(List<T>)? deletionCallback,
    Future Function()? emptyCallback,
    DocumentSnapshot? lastDocSnapshot,
  ) {
    final observation = collectionsSub[_colPath(fireQuery)];
    if (observation != null) {
      if (observation.isPaused()) {
        observation.resume();
      }
      return;
    }

    collectionsSub[_colPath(fireQuery)] = ObservableQueryReaction<T>();

    StreamSubscription<QuerySnapshot<Object?>> s;

    if (lastDocSnapshot == null) {
      s = fireQuery.query.snapshots().listen((querySnapShot) async {
        if (querySnapShot.docs.isEmpty) {
          limited.add(_colPath(fireQuery, indexed: false));
          await emptyCallback?.call();
        }
        if (querySnapShot.docs.isNotEmpty) {
          collectionsSub[_colPath(fireQuery)]?.lastDocSnapshot =
              querySnapShot.docs.last;
        }
        if (querySnapShot.docChanges.isNotEmpty) {
          var removed = <T>[];
          var changed = <T>[];
          for (var snapshot in querySnapShot.docChanges) {
            var data = snapshot.doc.data() as Map<String, dynamic>;
            if (data.containsKey('date') && data['date'] == null) {
              return;
            }

            T instance = object.ObjectLib().instance<T>(T, data['id']);
            instance.fromJson(data);

            if (snapshot.type == DocumentChangeType.removed) {
              removed.add(instance);
            } else {
              changed.add(instance);
            }
          }

          if (removed.isNotEmpty) await deletionCallback?.call(removed);
          if (changed.isNotEmpty) {
            await callback?.call(changed);
          }
        }
      });
    } else {
      s = fireQuery.query
          .startAfterDocument(lastDocSnapshot)
          .snapshots()
          .listen((querySnapShot) async {
        if (querySnapShot.docs.isEmpty) {
          limited.add(_colPath(fireQuery, indexed: false));
          await emptyCallback?.call();
        }
        if (querySnapShot.docs.isNotEmpty) {
          collectionsSub[_colPath(fireQuery)]?.lastDocSnapshot =
              querySnapShot.docs.last;
        }
        if (querySnapShot.docChanges.isNotEmpty) {
          var removed = <T>[];
          var changed = <T>[];
          for (var snapshot in querySnapShot.docChanges) {
            var data = snapshot.doc.data() as Map<String, dynamic>;
            if (data.containsKey('date') && data['date'] == null) {
              return;
            }

            T instance = object.ObjectLib().instance<T>(T, data['id']);
            instance.fromJson(data);

            if (snapshot.type == DocumentChangeType.removed) {
              removed.add(instance);
            } else {
              changed.add(instance);
            }
          }

          if (removed.isNotEmpty) await deletionCallback?.call(removed);
          if (changed.isNotEmpty) {
            await callback?.call(changed);
          }
        }
      });
    }
    var o = collectionsSub[_colPath(fireQuery)] as ObservableQueryReaction<T>;
    o.streamSubscription = s;
    o.fireQuery = fireQuery;
    o.callback = callback;
    o.deletionCallback = deletionCallback;
    o.emptyCallback = emptyCallback;
  }

  Future<void> increaseLimitReference<T extends object.Object<T>>({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
    required Function() noMore,
  }) async {
    final q = query == null ? reference : query(reference);
    return _increaseLimitOfCollection<T>(
      fireQuery: FireQuery(
        '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
      ),
      noMore: noMore,
    );
  }

  Future<void> increaseLimitGroupReference<T extends object.Object<T>>({
    required Query reference,
    Query<Object?> Function(Query)? query,
    required Function() noMore,
  }) async {
    final q = query == null ? reference : query(reference);
    return _increaseLimitOfCollection<T>(
      fireQuery: FireQuery(
        '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
      ),
      noMore: noMore,
    );
  }

  Future<void> _increaseLimitOfCollection<T extends object.Object<T>>({
    required FireQuery fireQuery,
    required Function() noMore,
  }) async {
    /**
     * Previous index
     */
    final index = pathIndexed[_colPath(fireQuery, indexed: false)] ?? 0;
    fireQuery.index = index;

    final observation =
        collectionsSub[_colPath(fireQuery)] as ObservableQueryReaction<T>?;
    if (observation == null) {
      return;
    }

    if (limited.contains(_colPath(fireQuery, indexed: false))) {
      noMore();
      return;
    }

    final lastDocSnapshot = observation.lastDocSnapshot;
    if (lastDocSnapshot == null) {
      noMore();
      return;
    }

    fireQuery.index = index + 1;
    pathIndexed[_colPath(fireQuery, indexed: false)] = fireQuery.index;
    _internalCollectionObserver<T>(
      fireQuery,
      observation.callback,
      observation.deletionCallback,
      () async {
        noMore();
      },
      lastDocSnapshot,
    );
  }

  String _docPath(DocumentReference reference) {
    return reference.path;
  }

  String _colPath(FireQuery fireQuery, {bool indexed = true}) {
    return fireQuery.path +
        fireQuery.query.parameters.toString() +
        (indexed ? '${fireQuery.index}' : '');
  }

  void resumeDocument({required DocumentReference reference}) {
    documentsSub[_docPath(reference)]?.resume();
  }

  void resumeCollection({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) {
    final q = query == null ? reference : query(reference);
    final fireQuery = FireQuery(
      '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
    );
    _resumeCollection(fireQuery: fireQuery);
  }

  void resumeCollectionGroup({
    required Query reference,
    Query<Object?> Function(Query)? query,
  }) async {
    final q = query == null ? reference : query(reference);
    final fireQuery = FireQuery(
      '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
    );
    _resumeCollection(fireQuery: fireQuery);
  }

  void _resumeCollection({
    required FireQuery fireQuery,
  }) {
    final indexes = pathIndexed[_colPath(fireQuery, indexed: false)] ?? 0;
    for (var i = 0; i <= indexes; i++) {
      fireQuery.index = i;
      collectionsSub[_colPath(fireQuery)]?.resume();
    }
  }

  void resumeAll() async {
    var docIds = [];
    docIds.addAll(documentsSub.keys.toList());
    for (var docPath in docIds) {
      if (documentsSub.containsKey(docPath)) {
        documentsSub[docPath]?.resume();
        if (kDebugMode) {
          print('Resuming document reference: $docPath');
        }
      }
    }

    var colIds = [];
    colIds.addAll(collectionsSub.keys.toList());
    for (var colPath in colIds) {
      if (collectionsSub.containsKey(colPath)) {
        collectionsSub[colPath]?.resume();
        if (kDebugMode) {
          print('Resuming collection reference: $colPath');
        }
      }
    }
  }

  void pauseDocument({required DocumentReference reference}) {
    documentsSub[_docPath(reference)]?.pause();
  }

  void pauseCollection({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) {
    final q = query == null ? reference : query(reference);
    final fireQuery = FireQuery(
      '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
    );
    _pauseCollection(fireQuery: fireQuery);
  }

  void pauseCollectionGroup({
    required Query reference,
    Query<Object?> Function(Query)? query,
  }) {
    final q = query == null ? reference : query(reference);
    final fireQuery = FireQuery(
      '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
    );
    _pauseCollection(fireQuery: fireQuery);
  }

  void _pauseCollection({
    required FireQuery fireQuery,
  }) {
    final indexes = pathIndexed[_colPath(fireQuery, indexed: false)] ?? 0;
    for (var i = 0; i <= indexes; i++) {
      fireQuery.index = i;
      collectionsSub[_colPath(fireQuery)]?.pause();
    }
  }

  void pauseAll() async {
    var docIds = [];
    docIds.addAll(documentsSub.keys.toList());
    for (var docPath in docIds) {
      if (documentsSub.containsKey(docPath)) {
        documentsSub[docPath]?.pause();
        if (kDebugMode) {
          print('Pausing document reference: $docPath');
        }
      }
    }

    var colIds = [];
    colIds.addAll(collectionsSub.keys.toList());
    for (var colPath in colIds) {
      if (collectionsSub.containsKey(colPath)) {
        collectionsSub[colPath]?.pause();
        if (kDebugMode) {
          print('Pausing collection reference: $colPath');
        }
      }
    }
  }

  Future<void> cancelDocument({required DocumentReference reference}) async {
    await documentsSub[_docPath(reference)]?.cancel();
  }

  Future<void> cancelCollection({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) async {
    final q = query == null ? reference : query(reference);
    final fireQuery = FireQuery(
      '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
    );
    await _cancelCollection(fireQuery: fireQuery);
  }

  Future<void> cancelCollectionGroup({
    required Query reference,
    Query<Object?> Function(Query)? query,
  }) async {
    final q = query == null ? reference : query(reference);
    final fireQuery = FireQuery(
      '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
    );
    await _cancelCollection(fireQuery: fireQuery);
  }

  Future<void> _cancelCollection({
    required FireQuery fireQuery,
  }) async {
    final indexes = pathIndexed[_colPath(fireQuery, indexed: false)] ?? 0;
    for (var i = 0; i <= indexes; i++) {
      fireQuery.index = i;
      await collectionsSub[_colPath(fireQuery)]?.cancel();
    }
  }

  Future<void> cancelAll() async {
    var docIds = [];
    docIds.addAll(documentsSub.keys.toList());
    for (var docPath in docIds) {
      if (documentsSub.containsKey(docPath)) {
        try {
          await documentsSub[docPath]?.cancel();
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
        documentsSub.remove(docPath);
        if (kDebugMode) {
          print('Cancelling document reference: $docPath');
        }
      }
    }

    var colIds = [];
    colIds.addAll(collectionsSub.keys.toList());
    for (var colPath in colIds) {
      if (collectionsSub.containsKey(colPath)) {
        try {
          await collectionsSub[colPath]?.cancel();
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
        collectionsSub.remove(colPath);
        if (kDebugMode) {
          print('Cancelling collection reference: $colPath');
        }
      }
    }
  }
}
