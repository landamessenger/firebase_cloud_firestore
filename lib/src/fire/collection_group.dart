import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionGroup {
  final Query<Map<String, dynamic>> reference;

  final Query<Object?> Function(Query)? query;

  CollectionGroup({required this.reference, this.query});
}
