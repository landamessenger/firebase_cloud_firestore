# Firebase Cloud Firestore

[![Pub Version](https://img.shields.io/pub/v/firebase_cloud_firestore.svg)](https://pub.dev/packages/firebase_cloud_firestore)
[![Build Status](https://travis-ci.org/landamessenger/firebase_cloud_firestore.svg?branch=master)](https://travis-ci.org/landamessenger/firebase_cloud_firestore)
[![Coverage Status](https://coveralls.io/repos/github/landamessenger/firebase_cloud_firestore/badge.svg?branch=master)](https://coveralls.io/github/landamessenger/firebase_cloud_firestore?branch=master)

> `cloud_firestore` + `object` + `a bunch of improvements`

This Dart library extends the functionality of the `cloud_firestore` and `object` packages, providing additional features for observing collections and documents, as well as implementing pagination functions for collections.

It simplifies the serialization of objects for cloud_firestore in a Flutter app. It streamlines the process of converting Dart objects into formats compatible with cloud_firestore, making data storage and retrieval smoother and more efficient for developers.

> The `firebase_cloud_firestore` version will always be aligned with `cloud_firestore` version.

```dart
final chatDocument = FirebaseFirestore.instance.collection('chats').doc('chat_id').asDocument();

Chat? chat = await chatDocument.get();
```

### [Home](https://github.com/landamessenger/firebase_cloud_firestore/wiki)

### [Setup](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Setup)

### [Documents](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Documents)

[- Get](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Documents#get)

[- Listen](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Documents#listen)

### [Collections](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Collections)

[- Get](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Collections#get)

[- Listen](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Collections#listen)

[- Pagination](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Collections#pagination)

[- Collection Group](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Collections#collection-group)

### [Scopes](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Scopes)

[- FirestoreViewModel](https://github.com/landamessenger/firebase_cloud_firestore/wiki/Scopes#firestoreviewmodel)
