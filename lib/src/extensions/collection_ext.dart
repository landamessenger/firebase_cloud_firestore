import 'package:object/object.dart' as object;

import '../fire/collection.dart';
import '../firestore_manager.dart';
import '../firestore_view_model.dart';

extension CollectionExt on Collection {
  Future<List<T>> get<T extends object.Object<T>>() =>
      FirestoreManager().getCollection<T>(
        reference: reference,
        query: query,
      );

  void listen<T extends object.Object<T>>({
    FirestoreViewModel? viewModel,
    Future Function(Map<String, T>)? results,
    Future Function(List<T>)? callback,
    Future Function(List<T>)? deletionCallback,
    Future Function()? emptyCallback,
  }) {
    final map = <int, Map<String, T>>{};
    (viewModel ?? FirestoreManager()).listenCollection<T>(
      reference: reference,
      query: query,
      callback: (List<T> instances, int page) async {
        callback?.call(instances);
        if (results != null) {
          if (map[page] == null) {
            map[page] = {};
          }
          for (T instance in instances) {
            map[page]?[instance.getId()] = instance;
          }

          final pages =
              (viewModel ?? FirestoreManager()).activePagesCollection<T>(
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
          results(res);
        }
      },
      deletionCallback: (List<T> instances, int page) async {
        deletionCallback?.call(instances);
        if (results != null) {
          for (T instance in instances) {
            map[page]?.remove(instance.getId());
          }

          final pages =
          (viewModel ?? FirestoreManager()).activePagesCollection<T>(
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
          results(res);
        }
      },
      emptyCallback: (int page) async {
        if (page > 0) return;
        emptyCallback?.call();
        if (results != null) {
          results({});
        }
      },
    );
  }

  void next<T extends object.Object<T>>({
    FirestoreViewModel? viewModel,
    Function()? noMore,
  }) {
    (viewModel ?? FirestoreManager()).nextCollectionPage<T>(
      reference: reference,
      query: query,
      noMore: noMore ?? () {},
    );
  }

  void previous<T extends object.Object<T>>({
    FirestoreViewModel? viewModel,
  }) {
    (viewModel ?? FirestoreManager()).previousCollectionPage<T>(
      reference: reference,
      query: query,
    );
  }

  void resume({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).resumeCollection(
        reference: reference,
        query: query,
      );

  void pause({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).pauseCollection(
        reference: reference,
        query: query,
      );

  void cancel({
    FirestoreViewModel? viewModel,
  }) =>
      (viewModel ?? FirestoreManager()).cancelCollection(
        reference: reference,
        query: query,
      );
}
