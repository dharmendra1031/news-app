// Offline episodes: downloads audio with `background_downloader` into the phone's
// public Downloads folder and tracks each file in Hive. Uploaded audio only.

import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/features/podcast/models/playable_audio.dart';

enum PodcastDownloadStatus { queued, running, complete, failed, canceled }

class PodcastDownloadDataSource {
  static final PodcastDownloadDataSource _instance =
      PodcastDownloadDataSource._internal();
  factory PodcastDownloadDataSource() => _instance;
  PodcastDownloadDataSource._internal();

  static const String _subDir = 'podcasts';

  bool _initialized = false;

  Box get _box => Hive.box(podcastDownloadsBoxKey);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FileDownloader().configureNotification(
      running: const TaskNotification('Downloading', '{filename}'),
      complete: const TaskNotification('Download complete', '{filename}'),
      error: const TaskNotification('Download failed', '{filename}'),
      progressBar: true,
    );

    FileDownloader().updates.listen(_onUpdate);
  }

  Future<void> ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;
    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> ensureDownloadPermissions() async {
    await ensureNotificationPermission();
    if (!Platform.isAndroid) return;
    try {
      final permissions = FileDownloader().permissions;
      final status =
          await permissions.status(PermissionType.androidSharedStorage);
      if (status != PermissionStatus.granted) {
        await permissions.request(PermissionType.androidSharedStorage);
      }
    } catch (_) {
    }
  }

  Future<bool> enqueue(PlayableAudio audio) async {
    if (audio.id.isEmpty || !audio.isDownloadable) return false;

    await _box.put(audio.id, {
      ...audio.toMap(),
      'status': PodcastDownloadStatus.queued.name,
      'progress': 0.0,
    });

    final task = DownloadTask(
      taskId: audio.id,
      url: audio.url,
      filename: '${_safeName(audio.title, audio.id)}.mp3',
      directory: _subDir,
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
    );

    return FileDownloader().enqueue(task);
  }

  String _safeName(String title, String fallback) {
    final base = title.trim().isEmpty ? fallback : title.trim();
    final cleaned = base
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  bool isDownloaded(String id) {
    final path = _storedPath(id);
    return path != null && File(path).existsSync();
  }

  String? localPath(String id) => isDownloaded(id) ? _storedPath(id) : null;

  PlayableAudio resolveSource(PlayableAudio audio) {
    final path = localPath(audio.id);
    return path == null ? audio : audio.copyWith(localFilePath: path);
  }

  Future<void> _onUpdate(TaskUpdate update) async {
    final id = update.task.taskId;

    if (update is TaskProgressUpdate) {
      _patch(id,
          status: PodcastDownloadStatus.running, progress: update.progress);
      return;
    }

    if (update is TaskStatusUpdate) {
      switch (update.status) {
        case TaskStatus.complete:
          String path = await update.task.filePath();
          if (Platform.isAndroid && update.task is DownloadTask) {
            try {
              final shared = await FileDownloader().moveToSharedStorage(
                  update.task as DownloadTask, SharedStorage.downloads);
              if (shared != null && shared.isNotEmpty) path = shared;
            } catch (_) {
            }
          }
          _patch(id,
              status: PodcastDownloadStatus.complete,
              progress: 1.0,
              localFilePath: path);
          break;
        case TaskStatus.failed:
        case TaskStatus.notFound:
          _patch(id, status: PodcastDownloadStatus.failed);
          break;
        case TaskStatus.canceled:
          _patch(id, status: PodcastDownloadStatus.canceled);
          break;
        case TaskStatus.enqueued:
        case TaskStatus.waitingToRetry:
          _patch(id, status: PodcastDownloadStatus.queued);
          break;
        case TaskStatus.running:
        case TaskStatus.paused:
          _patch(id, status: PodcastDownloadStatus.running);
          break;
      }
    }
  }

  void _patch(
    String id, {
    required PodcastDownloadStatus status,
    double? progress,
    String? localFilePath,
  }) {
    final existing = _box.get(id);
    final map = existing is Map
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{'id': id};
    map['status'] = status.name;
    if (progress != null) map['progress'] = progress;
    if (localFilePath != null) map['localFilePath'] = localFilePath;
    _box.put(id, map);
  }

  String? _storedPath(String id) {
    final raw = _box.get(id);
    if (raw is Map) return raw['localFilePath']?.toString();
    return null;
  }
}
