import 'package:cloud_firestore/cloud_firestore.dart';

class FireQuery {
  String path;

  Query<Object?> query;

  int index = 0;

  FireQuery(this.path, this.query);
}
