import 'dart:convert';

import 'package:cinema/MediaModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UserMediaLibrary {
  _UserMediaLibrary(this.collectionName, this.guestStorageKey);

  final String collectionName;
  final String guestStorageKey;
  final ValueNotifier<List<Media>> items = ValueNotifier<List<Media>>([]);

  String? _loadedForUser;

  bool contains(Media media) => items.value.any((item) => item.id == media.id);

  Future<void> load({bool force = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final userKey = user?.uid ?? 'guest';
    if (!force && _loadedForUser == userKey) return;

    _loadedForUser = userKey;
    items.value = [];

    try {
      if (user == null) {
        final preferences = await SharedPreferences.getInstance();
        final stored = preferences.getString(guestStorageKey);
        items.value = stored == null
            ? []
            : (jsonDecode(stored) as List<dynamic>)
                .map((item) => Media.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ))
                .toList();
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(collectionName)
          .get();
      items.value = snapshot.docs
          .map((document) => Media.fromJson(document.data()))
          .toList();
    } catch (error) {
      debugPrint('Could not load $collectionName: $error');
      items.value = [];
    }
  }

  Future<void> toggle(Media media) async {
    final user = FirebaseAuth.instance.currentUser;
    final previousItems = List<Media>.from(items.value);
    final nextItems = List<Media>.from(previousItems);
    final existingIndex = nextItems.indexWhere((item) => item.id == media.id);

    if (existingIndex >= 0) {
      nextItems.removeAt(existingIndex);
    } else {
      nextItems.add(media);
    }
    items.value = nextItems;

    try {
      if (user == null) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          guestStorageKey,
          jsonEncode(nextItems.map((item) => item.toJson()).toList()),
        );
        return;
      }

      final document = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(collectionName)
          .doc(Uri.encodeComponent(media.id));

      if (existingIndex >= 0) {
        await document.delete();
      } else {
        await document.set(media.toJson());
      }
    } catch (error) {
      items.value = previousItems;
      debugPrint('Could not update $collectionName: $error');
      rethrow;
    }
  }
}

class Favorites {
  static final _UserMediaLibrary _library =
      _UserMediaLibrary('favorites', 'favorites_guest');

  static ValueListenable<List<Media>> get listenable => _library.items;
  static List<Media> get favorites => _library.items.value;
  static bool contains(Media media) => _library.contains(media);
  static Future<void> load({bool force = false}) => _library.load(force: force);
  static Future<void> addToFavorites(Media media, [Function? onChanged]) async {
    await _library.toggle(media);
    onChanged?.call();
  }
}

class WatchLater {
  static final _UserMediaLibrary _library =
      _UserMediaLibrary('watchLater', 'watchLater_guest');

  static ValueListenable<List<Media>> get listenable => _library.items;
  static List<Media> get watchLater => _library.items.value;
  static bool contains(Media media) => _library.contains(media);
  static Future<void> load({bool force = false}) => _library.load(force: force);
  static Future<void> addToWatchLater(Media media,
      [Function? onChanged]) async {
    await _library.toggle(media);
    onChanged?.call();
  }
}
