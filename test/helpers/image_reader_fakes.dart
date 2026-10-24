import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lamb/errors/app_error.dart';
import 'package:lamb/models/image_description.dart';
import 'package:lamb/services/gallery_service.dart';
import 'package:lamb/services/tts/tts_service.dart';
import 'package:lamb/services/vision/vision_service.dart';

/// Galería en memoria con [count] fotos (ids "img-0", "img-1"...)
class FakeGalleryService implements GalleryService {
  FakeGalleryService({
    this.count = 3,
    this.permission = GalleryPermission.granted,
    this.bytes,
  });

  final int count;
  GalleryPermission permission;

  /// Bytes devueltos por [loadImageBytes]. `null` = foto no disponible.
  final Uint8List? bytes;

  final List<int> requestedPages = [];
  int settingsOpened = 0;

  @override
  Future<GalleryPermission> requestPermission() async => permission;

  @override
  Future<List<GalleryImage>> loadImages({
    required int page,
    required int pageSize,
  }) async {
    requestedPages.add(page);
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, count);
    if (start >= count) return const [];
    return [
      for (var i = start; i < end; i++)
        GalleryImage(id: 'img-$i', createdAt: DateTime(2026, 1, 1)),
    ];
  }

  @override
  Future<Uint8List?> loadImageBytes(
    GalleryImage image, {
    required int maxSide,
    int quality = 85,
  }) async =>
      bytes;

  @override
  Future<void> openSettings() async => settingsOpened++;
}

/// IA de visión controlable desde el test
///
/// Por defecto responde al instante con una descripción por foto. Con
/// [manual] = true, cada llamada queda pendiente hasta completar el
/// [Completer] correspondiente en [pending].
class FakeVisionService implements VisionService {
  FakeVisionService({this.manual = false, this.error});

  final bool manual;

  /// Si no es null, todas las llamadas fallan con este error
  AppError? error;

  int calls = 0;
  bool disposed = false;
  final List<Completer<ImageDescription>> pending = [];

  @override
  String get providerName => 'fake';

  @override
  Future<ImageDescription> describeImage(Uint8List jpegBytes) {
    calls++;
    if (error != null) return Future.error(error!);
    if (manual) {
      final completer = Completer<ImageDescription>();
      pending.add(completer);
      return completer.future;
    }
    return Future.value(describe(calls));
  }

  static ImageDescription describe(int n) => ImageDescription(
        kind: ImageKind.photo,
        spokenText: 'Descripción $n',
      );

  @override
  void dispose() => disposed = true;
}

/// TTS que registra lo que se "dice"
class FakeTTSService implements TTSService {
  final List<String> spoken = [];
  int stops = 0;
  bool _speaking = false;

  @override
  Future<void> speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
    Function(String)? onError,
  }) async {
    spoken.add(text);
    _speaking = true;
    onStart?.call();
  }

  @override
  Future<void> stop() async {
    stops++;
    _speaking = false;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  double get volume => 1.0;

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> increaseVolume({double step = 0.1}) async {}

  @override
  Future<void> decreaseVolume({double step = 0.1}) async {}

  @override
  bool get isSpeaking => _speaking;
}
