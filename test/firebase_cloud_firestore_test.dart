import 'package:firebase_cloud_firestore/firebase_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds one to input values', () {
    final fo = FirestoreManager();
    expect(fo.collections.isEmpty, true);
    expect(fo.documents.isEmpty, true);
  });
}
