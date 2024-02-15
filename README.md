# Firebase Cloud Firestore

[![Pub Version](https://img.shields.io/pub/v/firebase_cloud_firestore.svg)](https://pub.dev/packages/firebase_cloud_firestore)
[![Build Status](https://travis-ci.org/landamessenger/firebase_cloud_firestore.svg?branch=master)](https://travis-ci.org/landamessenger/firebase_cloud_firestore)
[![Coverage Status](https://coveralls.io/repos/github/landamessenger/firebase_cloud_firestore/badge.svg?branch=master)](https://coveralls.io/github/landamessenger/firebase_cloud_firestore?branch=master)

> `cloud_firestore` + `object`

This Dart library extends the functionality of the `cloud_firestore` and `object` packages, providing additional features for observing collections and documents, as well as implementing pagination functions for collections.

It simplifies the serialization of objects for cloud_firestore in a Flutter app. It streamlines the process of converting Dart objects into formats compatible with cloud_firestore, making data storage and retrieval smoother and more efficient for developers.

> The `firebase_cloud_firestore` version will always be aligned with `cloud_firestore` version.

## Usage

Configure the classes you will get from firestore with `object` before working with this library. This is an example:

```dart
import 'generated/model.g.dart';

class Chat extends ChatGen {
  @override
  @Field(
    name: 'id',
    primary: true,
  )
  String id = '';

  @override
  @Field(name: 'name')
  String name = '';

  @override
  @Field(name: 'multiple')
  bool multiple = false;

  @override
  @Field(name: 'members')
  List<String> members = [];

  @override
  @Field(name: 'creation')
  DateTime? creation = null;

  Chat();
}
```

Go to `object` [documentation](https://pub.dev/packages/object) for more information.

### Documents

A `Document` object is required to work with documents:

```dart
final chatDocument = Document(
  reference: FirebaseFirestore.instance.collection('chats').doc('chat_id'),
);
```

```dart
final chatDocument = FirebaseFirestore.instance.collection('chats').doc('chat_id').asDocument();
```

#### Get

```dart
Chat chat = await chatDocument.get<Chat>();
```

#### Observe

```dart
chatDocument?.listen<Chat>(
    callback: (chat) async {
        state.chat = chat;
        refresh();
    },
    notExistCallback: () async {
        state.chat = null;
        refresh();
    },
);
```

### Collections

A `Collection` object is required to work with collections:

```dart
final chatsCollection = Collection(
  reference: FirebaseFirestore.instance.collection('chats'),
  query: (query) => query
    .where(
      'member',
      arrayContains: 'your_logged_user_id',
    )
    .orderBy('lastChange', descending: true)
    .limit(10),
);
```

#### Get

```dart
List<Chat> chats = await chatsCollection.get<Chat>();
```

#### Observe

```dart
chatsCollection.listen<Chat>(
  results: (Map<String, Chat> chats) async {
    state.chats = chats;
    refresh();
  },
);
```

#### Pagination

To use the `next` method you must include a `limit` in your query, this will allow you to paginate documents from your collection.

```dart
chatsCollection?.next<Chat>(
  noMore: () {
    refresh();
  },
);
```
