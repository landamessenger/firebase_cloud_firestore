import 'package:firebase_cloud_firestore/firebase_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds one to input values', () {
    final fo = FirestoreSingleton();
    expect(fo.pathIndexed.isEmpty, true);
    expect(fo.collectionsSub.isEmpty, true);
    expect(fo.documentsSub.isEmpty, true);
  });
}
