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
    Future Function(Map<String, T>)? results,
    Future Function(List<T>)? callback,
    Future Function(List<T>)? deletionCallback,
    Future Function()? emptyCallback,
  }) {
    final map = <String, T>{};
    (viewModel ?? FirestoreManager()).listenCollectionGroup<T>(
      reference: reference,
      query: query,
      callback: (List<T> instances) async {
        callback?.call(instances);
        if (results != null) {
          for (T instance in instances) {
            map[instance.getId()] = instance;
          }
          results(map);
        }
      },
      deletionCallback: (List<T> instances) async {
        deletionCallback?.call(instances);
        if (results != null) {
          for (T instance in instances) {
            map.remove(instance.getId());
          }
          results(map);
        }
      },
      emptyCallback: () async {
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
    (viewModel ?? FirestoreManager()).increaseLimitGroupReference<T>(
      reference: reference,
      query: query,
      noMore: noMore ?? () {},
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
