import 'package:object/object.dart' as object;

import '../fire/collection.dart';
import '../firestore_singleton.dart';
import '../firestore_view_model.dart';

extension CollectionExt on Collection {
  Future<List<T>> get<T extends object.Object<T>>() =>
      FirestoreSingleton().getCollection<T>(
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
    (viewModel ?? FirestoreSingleton()).listenCollection<T>(
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
    (viewModel ?? FirestoreSingleton()).increaseLimitReference<T>(
      reference: reference,
      query: query,
      noMore: noMore ?? () {},
    );
  }
}
