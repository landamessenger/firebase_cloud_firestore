import 'package:firebase_cloud_firestore/firebase_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Basic test', () {
    final fo = FirestoreManager();
    expect(fo.collections.isEmpty, true);
    expect(fo.documents.isEmpty, true);
  });
}
