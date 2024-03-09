import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_cloud_firestore/src/extensions/query_ext.dart';
import 'package:firebase_cloud_firestore/src/utils/print.dart';
import 'package:object/object.dart' as object;

import 'fire/constants.dart';
import 'fire/firestore_collection_manager.dart';
import 'fire/firestore_document_manager.dart';
import 'fire/firestore_query.dart';

class FirestoreViewModel {
  final documents = <String, FirestoreDocumentManager>{};
  final collections = <String, FirestoreCollectionManager>{};

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
      printDebug(e);
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
      printDebug(e);
    }
    return instances;
  }

  void listenCollection<T extends object.Object<T>>({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
    Future Function(List<T>, int, bool)? callback,
    Future Function(List<T>, int)? deletionCallback,
    Future Function(int)? emptyCallback,
  }) {
    final int? maxActivePages = query != null
        ? query(reference).getValueOf<int>(reference, maxActivePagesKey, '==')
        : null;

    final q =
        query == null ? reference : query(reference).removeLibFields(reference);

    final fq = FirestoreQuery(
      '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
      false,
    );

    _internalCollectionObserver<T>(
      fq,
      0,
      maxActivePages,
      callback,
      deletionCallback,
      emptyCallback,
      null,
    );
  }

  void listenCollectionGroup<T extends object.Object<T>>({
    required Query<Map<String, dynamic>> reference,
    Query<Object?> Function(Query<Map<String, dynamic>>)? query,
    Future Function(List<T>, int, bool)? callback,
    Future Function(List<T>, int)? deletionCallback,
    Future Function(int)? emptyCallback,
  }) {
    final int? maxActivePages = query != null
        ? query(reference).getValueOf<int>(reference, maxActivePagesKey, '==')
        : null;

    final q =
        query == null ? reference : query(reference).removeLibFields(reference);

    final fq = FirestoreQuery(
      '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
      true,
    );

    _internalCollectionObserver<T>(
      fq,
      0,
      maxActivePages,
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
    final observation =
        (documents[_docPath(ref)] as FirestoreDocumentManager<T>?) ??
            FirestoreDocumentManager<T>(reference: ref);

    observation.documentObserver(callback, notExistCallback);

    documents[_docPath(ref)] = observation;
  }

  void _internalCollectionObserver<T extends object.Object<T>>(
    FirestoreQuery fireQuery,
    int page,
    int? maxActivePages,
    Future Function(List<T>, int, bool)? callback,
    Future Function(List<T>, int)? deletionCallback,
    Future Function(int)? emptyCallback,
    DocumentSnapshot? lastDocSnapshot,
  ) {
    final observation = (collections[_colPrimaryPath(fireQuery)]
            as FirestoreCollectionManager<T>?) ??
        FirestoreCollectionManager<T>(
          firestoreQuery: fireQuery,
        );

    observation.maxActivePages = maxActivePages ?? -1;

    if (observation.maxActivePages < 2) {
      observation.maxActivePages = -1;
    }

    observation.collectionObserver(
      page: page,
      callback: callback,
      deletionCallback: deletionCallback,
      emptyCallback: emptyCallback,
      startAfterDocument: lastDocSnapshot,
    );

    collections[_colPrimaryPath(fireQuery)] = observation;
  }

  Future<void> nextCollectionPage<T extends object.Object<T>>({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
    required Function() noMore,
  }) async {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    return _nextCollectionPage<T>(
      fireQuery: FirestoreQuery(
        '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
        false,
      ),
      noMore: noMore,
    );
  }

  Future<void> nextCollectionGroupPage<T extends object.Object<T>>({
    required Query reference,
    Query<Object?> Function(Query)? query,
    required Function() noMore,
  }) async {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    return _nextCollectionPage<T>(
      fireQuery: FirestoreQuery(
        '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
        true,
      ),
      noMore: noMore,
    );
  }

  Future<void> _nextCollectionPage<T extends object.Object<T>>({
    required FirestoreQuery fireQuery,
    required Function() noMore,
  }) async {
    final observation = collections[_colPrimaryPath(fireQuery)]
        as FirestoreCollectionManager<T>?;
    observation?.nextCollectionPage(
      noMore: noMore,
    );
  }

  Future<void> previousCollectionPage<T extends object.Object<T>>({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) async {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    return _previousCollectionPage<T>(
      fireQuery: FirestoreQuery(
        '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
        false,
      ),
    );
  }

  Future<void> previousCollectionGroupPage<T extends object.Object<T>>({
    required Query reference,
    Query<Object?> Function(Query)? query,
  }) async {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    return _previousCollectionPage<T>(
      fireQuery: FirestoreQuery(
        '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
        true,
      ),
    );
  }

  Future<void> _previousCollectionPage<T extends object.Object<T>>({
    required FirestoreQuery fireQuery,
  }) async {
    final observation = collections[_colPrimaryPath(fireQuery)]
        as FirestoreCollectionManager<T>?;
    observation?.previousCollectionPage();
  }

  String _docPath(DocumentReference reference) {
    return reference.path;
  }

  String _colPrimaryPath(FirestoreQuery fireQuery) {
    return fireQuery.path + fireQuery.query.parameters.toString();
  }

  void resumeDocument({required DocumentReference reference}) {
    documents[_docPath(reference)]?.resume();
  }

  void resumeCollection({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    final fireQuery = FirestoreQuery(
      '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
      false,
    );
    _resumeCollection(fireQuery: fireQuery);
  }

  void resumeCollectionGroup({
    required Query reference,
    Query<Object?> Function(Query)? query,
  }) async {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    final fireQuery = FirestoreQuery(
      '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
      true,
    );
    _resumeCollection(fireQuery: fireQuery);
  }

  void _resumeCollection({
    required FirestoreQuery fireQuery,
  }) {
    collections[_colPrimaryPath(fireQuery)]?.resume();
  }

  void resumeAll() async {
    var docIds = [];
    docIds.addAll(documents.keys.toList());
    for (var docPath in docIds) {
      if (documents.containsKey(docPath)) {
        documents[docPath]?.resume();
        printDebug('Resuming document reference: $docPath');
      }
    }

    var colIds = [];
    colIds.addAll(collections.keys.toList());
    for (var colPath in colIds) {
      if (collections.containsKey(colPath)) {
        collections[colPath]?.resume();
        printDebug('Resuming collection reference: $colPath');
      }
    }
  }

  void pauseDocument({required DocumentReference reference}) {
    documents[_docPath(reference)]?.pause();
  }

  void pauseCollection({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    final fireQuery = FirestoreQuery(
      '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
      false,
    );
    _pauseCollection(fireQuery: fireQuery);
  }

  void pauseCollectionGroup({
    required Query reference,
    Query<Object?> Function(Query)? query,
  }) {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    final fireQuery = FirestoreQuery(
      '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
      true,
    );
    _pauseCollection(fireQuery: fireQuery);
  }

  void _pauseCollection({
    required FirestoreQuery fireQuery,
  }) {
    collections[_colPrimaryPath(fireQuery)]?.pause();
  }

  void pauseAll() async {
    var docIds = [];
    docIds.addAll(documents.keys.toList());
    for (var docPath in docIds) {
      if (documents.containsKey(docPath)) {
        documents[docPath]?.pause();
        printDebug('Pausing document reference: $docPath');
      }
    }

    var colIds = [];
    colIds.addAll(collections.keys.toList());
    for (var colPath in colIds) {
      if (collections.containsKey(colPath)) {
        collections[colPath]?.pause();
        printDebug('Pausing collection reference: $colPath');
      }
    }
  }

  Future<void> cancelDocument({required DocumentReference reference}) async {
    await documents[_docPath(reference)]?.cancel();
  }

  Future<void> cancelCollection({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) async {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    final fireQuery = FirestoreQuery(
      '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
      false,
    );
    await _cancelCollection(fireQuery: fireQuery);
  }

  Future<void> cancelCollectionGroup({
    required Query reference,
    Query<Object?> Function(Query)? query,
  }) async {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    final fireQuery = FirestoreQuery(
      '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
      q,
      true,
    );
    await _cancelCollection(fireQuery: fireQuery);
  }

  Future<void> _cancelCollection({
    required FirestoreQuery fireQuery,
  }) async {
    await collections[_colPrimaryPath(fireQuery)]?.cancel();
  }

  Future<void> cancelAll() async {
    var docIds = [];
    docIds.addAll(documents.keys.toList());
    for (var docPath in docIds) {
      if (documents.containsKey(docPath)) {
        try {
          await documents[docPath]?.cancel();
        } catch (e) {
          printDebug(e);
        }
        documents.remove(docPath);
        printDebug('Cancelling document reference: $docPath');
      }
    }

    var colIds = [];
    colIds.addAll(collections.keys.toList());
    for (var colPath in colIds) {
      if (collections.containsKey(colPath)) {
        try {
          await collections[colPath]?.cancel();
        } catch (e) {
          printDebug(e);
        }
        collections.remove(colPath);
        printDebug('Cancelling collection reference: $colPath');
      }
    }
  }

  List<int> activePagesCollection<T extends object.Object<T>>({
    required CollectionReference reference,
    Query<Object?> Function(CollectionReference)? query,
  }) {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    return _activePagesCollection<T>(
      fireQuery: FirestoreQuery(
        '${reference.path}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
        false,
      ),
    );
  }

  List<int> activePagesCollectionGroup<T extends object.Object<T>>({
    required Query reference,
    Query<Object?> Function(Query)? query,
  }) {
    final q =
        query == null ? reference : query(reference).removeLibFields(reference);
    return _activePagesCollection<T>(
      fireQuery: FirestoreQuery(
        '${reference.parameters.values.map((e) => e.toString()).toList().join('_')}_${q.parameters.values.map((e) => e.toString()).toList().join('_')}',
        q,
        true,
      ),
    );
  }

  List<int> _activePagesCollection<T extends object.Object<T>>({
    required FirestoreQuery fireQuery,
  }) {
    final observation = collections[_colPrimaryPath(fireQuery)];
    return observation?.activePages() ?? [];
  }
}
