import 'package:object/object.dart' as object;

import '../fire/collection_group.dart';
import '../firestore_manager.dart';
import '../firestore_view_model.dart';

extension CollectionGroupExt on CollectionGroup {
  Future<List<T>> get<T extends object.Object<T>>() =>
      FirestoreManager().getCollectionGroup<T>(
        reference: reference,
        query: query,
      );

  void listen<T extends object.Object<T>>({
    FirestoreViewModel? viewModel,
    Future Function(Map<String, T>, List<int>)? results,
    Future Function(List<T>, int, bool)? callback,
    Future Function(List<T>, int)? deletionCallback,
    Future Function()? emptyCallback,
  }) {
    final map = <int, Map<String, T>>{};
    (viewModel ?? FirestoreManager()).listenCollectionGroup<T>(
      reference: reference,
      query: query,
      callback: (List<T> instances, int page, bool hasMore) async {
        callback?.call(instances, page, hasMore);
        if (results != null) {
          if (map[page] == null) {
            map[page] = {};
          }
          for (T instance in instances) {
            map[page]?[instance.getId()] = instance;
          }

          final pages =
              (viewModel ?? FirestoreManager()).activePagesCollectionGroup<T>(
            reference: reference,
            query: query,
          );

          final keys = map.keys.toList();
          final res = <String, T>{};
          for (int key in keys) {
            if (!pages.contains(key)) {
              map.remove(key);
            } else {
              res.addAll(map[key] ?? {});
            }
          }
          results(res, pages);
        }
      },
      deletionCallback: (List<T> instances, int page) async {
        deletionCallback?.call(instances, page);
        if (results != null) {
          for (T instance in instances) {
            map[page]?.remove(instance.getId());
          }

          final pages =
              (viewModel ?? FirestoreManager()).activePagesCollectionGroup<T>(
            reference: reference,
            query: query,
          );

          final keys = map.keys.toList();
          final res = <String, T>{};
          for (int key in keys) {
            if (!pages.contains(key)) {
              // map.remove(key);
            } else {
              res.addAll(map[key] ?? {});
            }
          }
          results(res, pages);
        }
      },
      emptyCallback: (int page) async {
        if (page > 0) return;
        emptyCallback?.call();
        if (results != null) {
          results({}, []);
        }
      },
    );
  }

  void next<T extends object.Object<T>>({
    FirestoreViewModel? viewModel,
    Function()? noMore,
  }) {
    (viewModel ?? FirestoreManager()).nextCollectionGroupPage<T>(
      reference: reference,
      query: query,
      noMore: noMore ?? () {},
    );
  }

  void previous<T extends object.Object<T>>({
    FirestoreViewModel? viewModel,
  }) {
    (viewModel ?? FirestoreManager()).previousCollectionGroupPage<T>(
      reference: reference,
      query: query,
    );
  }

  void resume({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).resumeCollectionGroup(
        reference: reference,
        query: query,
      );

  void pause({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).pauseCollectionGroup(
        reference: reference,
        query: query,
      );

  void cancel({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).cancelCollectionGroup(
        reference: reference,
        query: query,
      );
}
