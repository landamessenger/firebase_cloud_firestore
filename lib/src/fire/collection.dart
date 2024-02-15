import 'package:cloud_firestore/cloud_firestore.dart';

class Collection {
  final CollectionReference reference;
  final Query<Object?> Function(CollectionReference)? query;

  Collection({required this.reference, this.query});
}
