import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreQuery {

  bool group;

  String path;

  Query<Object?> query;

  FirestoreQuery(this.path, this.query, this.group);
}
