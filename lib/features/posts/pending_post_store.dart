import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'post_image_sanitizer.dart';

class PendingPost {
  const PendingPost({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    required this.description,
    required this.coordinationMode,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.imagePath,
    this.blockedReason,
  });

  final String id;
  final String category;
  final String type;
  final String title;
  final String description;
  final String coordinationMode;
  final double latitude;
  final double longitude;
  final String createdAt;
  final String? imagePath;
  final String? blockedReason;

  PendingPost copyWith({String? blockedReason}) => PendingPost(
    id: id,
    category: category,
    type: type,
    title: title,
    description: description,
    coordinationMode: coordinationMode,
    latitude: latitude,
    longitude: longitude,
    createdAt: createdAt,
    imagePath: imagePath,
    blockedReason: blockedReason ?? this.blockedReason,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'type': type,
    'title': title,
    'description': description,
    'coordination_mode': coordinationMode,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': createdAt,
    'image_path': imagePath,
    'blocked_reason': blockedReason,
  };

  static PendingPost? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (id is! String || latitude is! num || longitude is! num) return null;
    return PendingPost(
      id: id,
      category: json['category'] as String? ?? 'help',
      type: json['type'] as String? ?? 'help_request',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coordinationMode: json['coordination_mode'] as String? ?? 'individual',
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      createdAt: json['created_at'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      blockedReason: json['blocked_reason'] as String?,
    );
  }

  Map<String, dynamic> toFeedMap({
    required String authorName,
    required double fromLatitude,
    required double fromLongitude,
  }) => {
    'id': id,
    'category': category,
    'type': type,
    'title': title,
    'description': description,
    'coordination_mode': coordinationMode,
    'status': blockedReason == null ? 'pending_send' : 'pending_blocked',
    'author_name': authorName,
    'created_at': createdAt,
    'local_image_path': imagePath,
    'distance_m': _roundedMeters(
      fromLatitude,
      fromLongitude,
      latitude,
      longitude,
    ),
    'member_count': 0,
    'recommendation_count': 0,
    'blocked_reason': blockedReason,
  };
}

int _roundedMeters(double fromLat, double fromLng, double toLat, double toLng) {
  const earth = 6371000.0;
  final lat1 = fromLat * math.pi / 180;
  final lat2 = toLat * math.pi / 180;
  final dLat = (toLat - fromLat) * math.pi / 180;
  final dLng = (toLng - fromLng) * math.pi / 180;
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
  final meters = earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return (meters / 10).round() * 10;
}

class PendingPostStore {
  // ignore: prefer_initializing_formals
  PendingPostStore({Directory? directory}) : _directory = directory;

  static final instance = PendingPostStore();

  final Directory? _directory;
  Future<void> _tail = Future<void>.value();

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final gate = _tail;
    final result = gate.then((_) => action());
    _tail = result.then((_) {}, onError: (_, _) {});
    return result;
  }

  Future<Directory> _folder() async {
    final given = _directory;
    if (given != null) return given;
    final root = await getApplicationSupportDirectory();
    final folder = Directory('${root.path}${Platform.pathSeparator}yunta-private');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<File> _index() async {
    final folder = await _folder();
    return File('${folder.path}${Platform.pathSeparator}pending-posts.json');
  }

  Future<List<PendingPost>> read() => _exclusive(_readUnlocked);

  Future<void> upsert(PendingPost post) => _exclusive(() async {
    final posts = await _readUnlocked();
    await _write([
      post,
      for (final item in posts)
        if (item.id != post.id) item,
    ]);
  });

  Future<void> markBlocked(String id, String reason) => _exclusive(() async {
    final posts = await _readUnlocked();
    await _write([
      for (final post in posts)
        if (post.id == id) post.copyWith(blockedReason: reason) else post,
    ]);
  });

  Future<void> remove(String id) => _exclusive(() async {
    final posts = await _readUnlocked();
    PendingPost? removed;
    final next = <PendingPost>[];
    for (final item in posts) {
      if (item.id == id) {
        removed = item;
      } else {
        next.add(item);
      }
    }
    await _write(next);
    final path = removed?.imagePath;
    if (path == null) return;
    final image = File(path);
    if (await image.exists()) await image.delete();
  });

  Future<List<PendingPost>> _readUnlocked() async {
    final file = await _index();
    final tmp = File('${file.path}.tmp');
    final source = await file.exists()
        ? file
        : await tmp.exists()
        ? tmp
        : null;
    if (source == null) return const [];
    try {
      final decoded = jsonDecode(await source.readAsString());
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            PendingPost.fromJson(Map<String, dynamic>.from(item)),
      ].whereType<PendingPost>().toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<String> saveImage(String postId, XFile image) async {
    final source = await image.readAsBytes();
    final bytes = await compute(sanitizePostImage, source);
    final folder = await _folder();
    final file = File(
      '${folder.path}${Platform.pathSeparator}pending-$postId.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _write(List<PendingPost> posts) async {
    final file = await _index();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode([for (final post in posts) post.toJson()]),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }
}
