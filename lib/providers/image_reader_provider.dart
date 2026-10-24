import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../config/image_reader_config.dart';
import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';
import '../models/image_description.dart';
import '../services/gallery_service.dart';
import '../services/tts/tts_service.dart';
import '../services/vision/vision_service.dart';

/// Estado general de la pantalla del lector de imágenes
enum ImageReaderStatus {
  /// Aún no se ha llamado a [ImageReaderProvider.initialize]
  initial,

  /// Esperando respuesta al diálogo de permiso del sistema
  requestingPermission,

  /// El usuario no dio permiso para ver las fotos
  permissionDenied,

  /// Cargando la primera página de fotos
  loading,

  /// La galería no tiene fotos
  empty,

  /// Fotos cargadas y listas para navegar
  ready,

  /// Error al cargar la galería
  error,
}

/// Estado de la lectura de UNA foto
enum AnalysisState {
  /// Todavía no se ha pedido a la IA
  idle,

  /// Esperando respuesta de la IA
  analyzing,

  /// Descripción disponible
  done,

  /// La IA falló. Solo se reintenta si el usuario lo pide.
  failed,
}

class ImageAnalysis {
  final AnalysisState state;
  final ImageDescription? description;

  const ImageAnalysis._(this.state, [this.description]);

  static const idle = ImageAnalysis._(AnalysisState.idle);
  static const analyzing = ImageAnalysis._(AnalysisState.analyzing);
  static const failed = ImageAnalysis._(AnalysisState.failed);

  factory ImageAnalysis.done(ImageDescription description) =>
      ImageAnalysis._(AnalysisState.done, description);
}

/// Provider del Lector de Imágenes (Feature 6.4)
///
/// Flujo:
/// 1. Pide permiso de fotos y carga la galería (paginada)
/// 2. El usuario desliza entre fotos a pantalla completa
/// 3. Si una foto permanece en pantalla [dwellDuration] (2 s por defecto),
///    se envía a la IA de visión y la descripción se lee con TTS
/// 4. Las descripciones se guardan en memoria: volver a una foto ya leída
///    la repite sin coste
///
/// Sin reintentos automáticos: si una lectura falla, se publica el error en
/// [takePendingError] para que la pantalla lo muestre con
/// `ErrorHandlerService`, y solo se reintenta con [retryCurrent].
///
/// Este provider es dueño de [VisionService] y lo libera en [dispose].
class ImageReaderProvider extends ChangeNotifier {
  final GalleryService _gallery;
  final VisionService _vision;
  final TTSService _tts;
  final Duration _dwellDuration;
  final int _pageSize;

  ImageReaderProvider({
    required GalleryService gallery,
    required VisionService vision,
    required TTSService tts,
    Duration dwellDuration = ImageReaderConfig.dwellDuration,
    int pageSize = ImageReaderConfig.pageSize,
  })  : _gallery = gallery,
        _vision = vision,
        _tts = tts,
        _dwellDuration = dwellDuration,
        _pageSize = pageSize;

  ImageReaderStatus _status = ImageReaderStatus.initial;
  bool _hasLimitedAccess = false;

  final List<GalleryImage> _images = [];
  int _currentIndex = 0;
  int _nextPage = 0;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  final Map<String, ImageAnalysis> _analyses = {};
  Timer? _dwellTimer;
  bool _isSpeaking = false;

  /// Se desactiva tras un error de configuración (ej. falta API key) para
  /// no repetir el mismo diálogo de error en cada foto.
  bool _autoReadEnabled = true;

  AppError? _pendingError;
  bool _disposed = false;

  // ========================================
  // Getters
  // ========================================

  ImageReaderStatus get status => _status;
  bool get hasLimitedAccess => _hasLimitedAccess;
  List<GalleryImage> get images => List.unmodifiable(_images);
  int get currentIndex => _currentIndex;
  bool get isSpeaking => _isSpeaking;
  bool get autoReadEnabled => _autoReadEnabled;
  GalleryService get gallery => _gallery;

  GalleryImage? get currentImage =>
      _images.isEmpty ? null : _images[_currentIndex];

  ImageAnalysis analysisFor(GalleryImage image) =>
      _analyses[image.id] ?? ImageAnalysis.idle;

  ImageAnalysis get currentAnalysis {
    final image = currentImage;
    return image == null ? ImageAnalysis.idle : analysisFor(image);
  }

  /// Devuelve el último error pendiente de mostrar y lo limpia
  AppError? takePendingError() {
    final error = _pendingError;
    _pendingError = null;
    return error;
  }

  // ========================================
  // Ciclo de vida
  // ========================================

  /// Pide permiso y carga la primera página de fotos
  Future<void> initialize() async {
    _setStatus(ImageReaderStatus.requestingPermission);

    final permission = await _gallery.requestPermission();
    if (_disposed) return;

    if (permission == GalleryPermission.denied) {
      _pendingError = AppError(
        category: ErrorCategory.platformChannel,
        code: ErrorCodes.galleryPermissionDenied,
        technicalMessage: 'Photo permission denied',
        userMessage: '',
        canRetry: false,
      );
      _setStatus(ImageReaderStatus.permissionDenied);
      return;
    }
    _hasLimitedAccess = permission == GalleryPermission.limited;

    _setStatus(ImageReaderStatus.loading);
    _images.clear();
    _analyses.clear();
    _currentIndex = 0;
    _nextPage = 0;
    _hasMorePages = true;

    try {
      await _loadNextPage();
    } on AppError catch (e) {
      _pendingError = e;
      _setStatus(ImageReaderStatus.error);
      return;
    }
    if (_disposed) return;

    if (_images.isEmpty) {
      _setStatus(ImageReaderStatus.empty);
      return;
    }

    _setStatus(ImageReaderStatus.ready);
    _scheduleDwell();
  }

  /// Llamar cuando el usuario cambia de foto (swipe o botones)
  void onPageChanged(int index) {
    if (index < 0 || index >= _images.length || index == _currentIndex) return;

    developer.log('Page changed to $index', name: 'ImageReaderProvider');
    _currentIndex = index;
    _dwellTimer?.cancel();

    // La lectura de la foto anterior ya no tiene sentido
    if (_isSpeaking) unawaited(stopSpeaking());

    _notify();
    _maybeLoadMore();
    _scheduleDwell();
  }

  /// Reintenta la lectura de la foto actual (acción explícita del usuario)
  Future<void> retryCurrent() async {
    final image = currentImage;
    if (image == null) return;
    _autoReadEnabled = true;
    _analyses.remove(image.id);
    await _analyze(image);
  }

  /// Lee la foto actual sin esperar el tiempo de permanencia
  Future<void> readCurrentNow() async {
    final image = currentImage;
    if (image == null) return;
    _dwellTimer?.cancel();
    final analysis = analysisFor(image);
    if (analysis.state == AnalysisState.done) {
      await _speak(analysis.description!.spokenText);
    } else if (analysis.state != AnalysisState.analyzing) {
      await _analyze(image);
    }
  }

  /// Vuelve a leer la descripción de la foto actual
  Future<void> repeatCurrent() => readCurrentNow();

  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    _notify();
    try {
      await _tts.stop();
    } catch (e) {
      developer.log('Failed to stop TTS', name: 'ImageReaderProvider', error: e);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _dwellTimer?.cancel();
    if (_isSpeaking) unawaited(_tts.stop());
    _vision.dispose();
    super.dispose();
  }

  // ========================================
  // Lógica interna
  // ========================================

  void _scheduleDwell() {
    _dwellTimer?.cancel();
    if (!_autoReadEnabled || currentImage == null) return;
    _dwellTimer = Timer(_dwellDuration, _onDwellElapsed);
  }

  void _onDwellElapsed() {
    final image = currentImage;
    if (_disposed || image == null) return;

    final analysis = analysisFor(image);
    switch (analysis.state) {
      case AnalysisState.idle:
        unawaited(_analyze(image));
        break;
      case AnalysisState.done:
        // Foto ya leída: repetir desde caché (sin coste)
        unawaited(_speak(analysis.description!.spokenText));
        break;
      case AnalysisState.analyzing:
      case AnalysisState.failed:
        // Ya en curso, o falló y espera a que el usuario pida reintentar
        break;
    }
  }

  Future<void> _analyze(GalleryImage image) async {
    _analyses[image.id] = ImageAnalysis.analyzing;
    _notify();
    unawaited(_speak('Leyendo la foto, un momento.'));

    try {
      final bytes = await _gallery.loadImageBytes(
        image,
        maxSide: ImageReaderConfig.maxImageSide,
        quality: ImageReaderConfig.jpegQuality,
      );
      if (bytes == null) {
        throw AppError(
          category: ErrorCategory.platformChannel,
          code: ErrorCodes.galleryLoadFailed,
          technicalMessage: 'Image ${image.id} no longer available',
          userMessage: 'Esta foto ya no está disponible.',
          canRetry: false,
        );
      }

      final description = await _vision.describeImage(bytes);
      if (_disposed) return;

      _analyses[image.id] = ImageAnalysis.done(description);
      _notify();

      // Solo leer si el usuario sigue mirando esta foto
      if (currentImage == image) {
        await _speak(description.spokenText);
      }
    } catch (e, stackTrace) {
      if (_disposed) return;
      final error = e is AppError
          ? e
          : AppError(
              category: ErrorCategory.llm,
              code: ErrorCodes.visionRequestFailed,
              technicalMessage: e.toString(),
              userMessage: '',
              canRetry: true,
              stackTrace: stackTrace,
            );
      developer.log(
        'Analysis failed for ${image.id}: ${error.code}',
        name: 'ImageReaderProvider',
        error: error,
      );

      _analyses[image.id] = ImageAnalysis.failed;
      if (!error.canRetry) _autoReadEnabled = false;
      if (_isSpeaking) await stopSpeaking();

      // Solo molestar al usuario si sigue en esta foto
      if (currentImage == image) _pendingError = error;
      _notify();
    }
  }

  Future<void> _speak(String text) async {
    if (_disposed) return;
    _isSpeaking = true;
    _notify();
    try {
      await _tts.speak(
        text,
        onComplete: () {
          _isSpeaking = false;
          _notify();
        },
        onError: (_) {
          _isSpeaking = false;
          _notify();
        },
      );
    } catch (e) {
      // TTS no debe romper la navegación
      developer.log('TTS failed', name: 'ImageReaderProvider', error: e);
      _isSpeaking = false;
      _notify();
    }
  }

  void _maybeLoadMore() {
    final nearEnd =
        _currentIndex >= _images.length - ImageReaderConfig.loadMoreThreshold;
    if (nearEnd && _hasMorePages && !_isLoadingMore) {
      unawaited(_loadMoreSilently());
    }
  }

  /// Falla silenciosa: el usuario puede seguir con las fotos ya cargadas
  Future<void> _loadMoreSilently() async {
    try {
      await _loadNextPage();
    } catch (e) {
      developer.log('Failed to load more', name: 'ImageReaderProvider', error: e);
    }
  }

  Future<void> _loadNextPage() async {
    _isLoadingMore = true;
    try {
      final page = await _gallery.loadImages(
        page: _nextPage,
        pageSize: _pageSize,
      );
      if (_disposed) return;
      _images.addAll(page);
      _nextPage++;
      _hasMorePages = page.length == _pageSize;
      _notify();
    } finally {
      _isLoadingMore = false;
    }
  }

  void _setStatus(ImageReaderStatus status) {
    _status = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
