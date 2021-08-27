import 'dart:io';

import 'package:e305/client/data/client.dart';
import 'package:e305/client/models/post.dart';
import 'package:e305/settings/data/settings.dart';
import 'package:e305/tags/data/post.dart';
import 'package:e305/tags/data/storage.dart';
import 'package:e305/tags/data/suggestions.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

// final Recommendations recommendations = Recommendations();

class Recommendations {
  final FavoriteDatabase database = FavoriteDatabase();

  Future<Map<Post, double>?> rate(List<Post> posts) async {
    List<SlimPost>? favs = await database.getFavorites();
    if (favs != null) {
      return ratePosts(favs, posts);
    }
  }
}

class FavoriteDatabase extends DatabaseController {
  late String? search;

  FavoriteDatabase() : super(name: 'favorites') {
    settings.credentials.addListener(reinitialize);
  }

  @override
  void dispose() {
    settings.credentials.removeListener(reinitialize);
    super.dispose();
  }

  Future<void> reinitialize() async {
    search = null;
    database = null;
    await initialize();
    notifyListeners();
  }

  Future<void> initialize() async {
    if (super.path == null) {
      super.path = [(await getApplicationSupportDirectory()).path, 'favs.json']
          .join('/');
    }
    if (search == null) {
      String? username = (await client.credentials)?.username;
      search = username != null ? 'fav:$username' : null;
    }
  }

  Future<List<SlimPost>?> getFavorites() async {
    await initialize();
    if (search != null) {
      await getDatabase(
        provide: (page) => client.posts(search!, page, limit: 200),
      );
      if (database != null) {
        return database!.posts;
      }
    }
  }

  Future<List<SlimPost>?> refreshFavorites() async {
    await initialize();
    if (search != null) {
      await recreate((page) => client.posts(search!, page, limit: 200));
      if (database != null) {
        return database!.posts;
      }
    }
  }
}

class DatabaseController with ChangeNotifier {
  static const Duration defaultStale = Duration(days: 7);

  final Duration? stale;
  final int limit;
  final String name;

  String? path;

  TagDataBase? database;

  DatabaseController({
    this.limit = 1200,
    this.stale = defaultStale,
    this.name = 'database',
    this.path,
  });

  Future<TagDataBase?> getDatabase(
      {String? path, PostProvider? provide}) async {
    if (database != null) {
      return database;
    }

    if (path != null) {
      this.path = path;
    }
    if (this.path == null) {
      throw StateError('no database path provided');
    }

    database = await load(this.path!);
    if (database != null) {
      return database;
    }

    if (provide != null) {
      database = await create(provide);
    }
    if (database != null) {
      return database;
    }
  }

  Future<TagDataBase?> load(String path) async {
    TagDataBase database;
    File file = File(path);
    if (file.existsSync()) {
      database = TagDataBase.read(path);
      if (stale == null ||
          database.creation.difference(DateTime.now()) < stale!) {
        notifyListeners();
        return database;
      } else {
        database.delete();
        notifyListeners();
      }
    }
  }

  Future<TagDataBase?> create(PostProvider provide) async {
    TagDataBase database = await TagDataBase.create(
        name: name, provide: provide, path: path, limit: limit);
    database.write();
    notifyListeners();
    return database;
  }

  Future<TagDataBase?> recreate(PostProvider provide) async {
    if (database != null) {
      database!.delete();
      database = null;
      notifyListeners();
    }
    return create(provide);
  }
}