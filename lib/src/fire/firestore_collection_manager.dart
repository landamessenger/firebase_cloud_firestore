import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_cloud_firestore/src/fire/firestore_collection_entity.dart';
import 'package:firebase_cloud_firestore/src/firestore_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:object/object.dart' as object;

import 'query_reaction.dart';

class FirestoreCollectionManager<T extends object.Object<T>>
    extends FirestoreCollectionEntity {
  final bool group = false;

  bool loading = false;

  bool limited = false;

  int index = 0;

  int maxActivePages = -1;

  final Map<int, ObservableQueryReaction<T>> collectionPages = {};

  FirestoreCollectionManager({required super.firestoreQuery});

  int nextIndex() {
    return index + 1;
  }

  int previousIndex() {
    return index - 1;
  }

  int firstIndex() {
    int index = 99999999;
    for (int c in collectionPages.keys.toList()) {
      if (c < index) {
        index = c;
      }
    }
    return index;
  }

  int lastIndex() {
    int index = 0;
    for (int c in collectionPages.keys.toList()) {
      if (c > index) {
        index = c;
      }
    }
    return index;
  }

  void collectionObserver({
    int page = 0,
    Future Function(List<T>, int, bool)? callback,
    Future Function(List<T>, int)? deletionCallback,
    Future Function(int)? emptyCallback,
    Future Function(int)? moreContent,
    DocumentSnapshot? startAfterDocument,
    DocumentSnapshot? endBeforeDocument,
  }) {
    collectionPages[page] = ObservableQueryReaction<T>();

    StreamSubscription<QuerySnapshot<Object?>> s;

    if (startAfterDocument == null && endBeforeDocument == null) {
      s = firestoreQuery.query.snapshots().listen(
        (querySnapShot) async {
          await _collectionObserverQuery(
            page: page,
            callback: callback,
            deletionCallback: deletionCallback,
            emptyCallback: emptyCallback,
            moreContent: moreContent,
            querySnapShot: querySnapShot,
          );
        },
      );
    } else if (startAfterDocument != null) {
      s = firestoreQuery.query
          .startAfterDocument(startAfterDocument)
          .snapshots()
          .listen(
        (querySnapShot) async {
          await _collectionObserverQuery(
            page: page,
            callback: callback,
            deletionCallback: deletionCallback,
            emptyCallback: emptyCallback,
            moreContent: moreContent,
            querySnapShot: querySnapShot,
          );
        },
      );
    } else if (endBeforeDocument != null) {
      s = firestoreQuery.query
          .endBeforeDocument(endBeforeDocument)
          .limitToLast(firestoreQuery.query.parameters['limit'])
          .snapshots()
          .listen(
        (querySnapShot) async {
          await _collectionObserverQuery(
            page: page,
            callback: callback,
            deletionCallback: deletionCallback,
            emptyCallback: emptyCallback,
            moreContent: moreContent,
            querySnapShot: querySnapShot,
          );
        },
      );
    } else {
      return;
    }
    collectionPages[page]?.streamSubscription = s;
    collectionPages[page]?.fireQuery = firestoreQuery;
    collectionPages[page]?.callback = callback;
    collectionPages[page]?.deletionCallback = deletionCallback;
    collectionPages[page]?.emptyCallback = emptyCallback;
  }

  Future<void> _collectionObserverQuery({
    int page = 0,
    Future Function(List<T>, int, bool)? callback,
    Future Function(List<T>, int)? deletionCallback,
    Future Function(int)? emptyCallback,
    Future Function(int)? moreContent,
    required QuerySnapshot querySnapShot,
  }) async {
    /**
     * Update collection page limits
     */
    if (querySnapShot.docs.isNotEmpty) {
      collectionPages[page]?.firstDocSnapshot = querySnapShot.docs.first;
      collectionPages[page]?.lastDocSnapshot = querySnapShot.docs.last;
    }

    collectionPages[page]?.isEmpty = querySnapShot.docs.isEmpty;

    /**
     * Get changes/removals
     */
    final removed = <T>[];
    final changed = <T>[];
    if (querySnapShot.docChanges.isNotEmpty) {
      for (var snapshot in querySnapShot.docChanges) {
        var data = snapshot.doc.data() as Map<String, dynamic>;
        T instance = object.ObjectLib().instance<T>(T, data['id']);
        instance.fromJson(data);
        if (snapshot.type == DocumentChangeType.removed) {
          removed.add(instance);
        } else {
          changed.add(instance);
        }
      }
    }

    /**
     * Notify end of event (next or previous actions release)
     */
    if (querySnapShot.docs.isEmpty) {
      limited = true;
      await emptyCallback?.call(page);
    } else {
      await moreContent?.call(page);
    }

    /**
     * Check if there are more docs in next page
     */
    final collectionPage = collectionPages[page];
    if (collectionPage != null) {
      final query = collectionPage.fireQuery?.query;
      final lastDocSnapshot = collectionPage.lastDocSnapshot;
      if (query != null && lastDocSnapshot != null) {
        final nextDocument =
            await query.startAfterDocument(lastDocSnapshot).limit(1).get();
        collectionPages[page]?.hasMore = nextDocument.docs.isNotEmpty;
      }
    }

    /**
     * Execute callbacks
     */
    if (removed.isNotEmpty) await deletionCallback?.call(removed, page);
    if (changed.isNotEmpty) {
      await callback?.call(
        changed,
        page,
        collectionPages[page]?.hasMore ?? false,
      );
    }
  }

  Future<void> nextCollectionPage({
    required Function() noMore,
  }) async {
    if (loading) {
      return;
    }

    if (limited) {
      noMore();
      return;
    }

    int last = lastIndex();
    final observation = collectionPages[last];
    if (observation == null) {
      return;
    }

    final lastDocSnapshot = observation.lastDocSnapshot;
    if (lastDocSnapshot == null) {
      noMore();
      return;
    }

    loading = true;

    collectionObserver(
      page: last + 1,
      callback: observation.callback,
      deletionCallback: observation.deletionCallback,
      emptyCallback: (int page) async {
        if (maxActivePages > 0) {
          await Future.delayed(const Duration(milliseconds: 10));
          final last = lastIndex();
          await collectionPages[last]?.cancel();
          collectionPages.remove(last);
        }
        noMore();
        releaseLoader();
      },
      moreContent: (int page) async {
        index = page;
        if (maxActivePages > 0) {
          if (collectionPages.length > maxActivePages) {
            final first = firstIndex();
            await collectionPages[first]?.cancel();
            collectionPages.remove(first);
          }
        }
        if (kDebugMode) {
          FirestoreManager().showSnackBar(
              'page loaded: $index active pages [${activePages()}]');
        }

        releaseLoader();
      },
      startAfterDocument: lastDocSnapshot,
    );
  }

  Future<void> previousCollectionPage() async {
    if (loading) {
      return;
    }

    int first = firstIndex();
    final observation = collectionPages[first];
    if (observation == null) {
      return;
    }

    if (first == 0) {
      return;
    }

    final firstDocSnapshot = observation.firstDocSnapshot;
    if (firstDocSnapshot == null) {
      return;
    }

    loading = true;

    limited = false;

    collectionObserver(
      page: first - 1,
      callback: observation.callback,
      deletionCallback: observation.deletionCallback,
      emptyCallback: (int page) async {
        releaseLoader();
      },
      moreContent: (int page) async {
        index = first - 1;

        if (maxActivePages > 0) {
          if (collectionPages.length > maxActivePages) {
            final last = lastIndex();
            await collectionPages[last]?.cancel();
            collectionPages.remove(last);
          }
        }

        if (kDebugMode) {
          FirestoreManager().showSnackBar(
              'page loaded: $index active pages [${activePages()}]');
        }

        releaseLoader();
      },
      endBeforeDocument: firstDocSnapshot,
    );
  }

  void resume() {
    for (var page in collectionPages.values.toList()) {
      if (page.isPaused()) {
        page.resume();
      }
    }
  }

  void pause() {
    for (var page in collectionPages.values.toList()) {
      if (!page.isPaused()) {
        page.pause();
      }
    }
  }

  Future<void> cancel() async {
    for (var page in collectionPages.values.toList()) {
      await page.cancel();
    }
  }

  void releaseLoader() async {
    if (FirestoreManager().lockTime.inSeconds > 0) {
      await Future.delayed(FirestoreManager().lockTime);
    }
    loading = false;
  }

  List<int> activePages() => collectionPages.keys.toList();
}
