import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';

/// Resultado de pedir permiso de acceso a fotos
enum GalleryPermission {
  /// Acceso a todas las fotos
  granted,

  /// Acceso solo a fotos seleccionadas (Android 14+, iOS)
  limited,

  /// Sin acceso
  denied,
}

/// Referencia ligera a una foto de la galería
///
/// No contiene los bytes: se cargan bajo demanda con
/// [GalleryService.loadImageBytes] para no llenar la memoria en
/// dispositivos de gama baja.
class GalleryImage {
  final String id;
  final DateTime createdAt;

  const GalleryImage({required this.id, required this.createdAt});

  @override
  bool operator ==(Object other) => other is GalleryImage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Acceso a la galería de fotos del dispositivo
///
/// Abstracción para poder testear el provider sin plugins nativos.
abstract class GalleryService {
  /// Pide permiso de lectura de fotos (muestra el diálogo del sistema)
  Future<GalleryPermission> requestPermission();

  /// Carga una página de fotos, de la más reciente a la más antigua
  Future<List<GalleryImage>> loadImages({required int page, required int pageSize});

  /// Carga la foto como JPEG reescalado (lado mayor = [maxSide] px)
  ///
  /// Retorna `null` si la foto ya no existe (borrada mientras se navegaba).
  Future<Uint8List?> loadImageBytes(
    GalleryImage image, {
    required int maxSide,
    int quality = 85,
  });

  /// Abre la configuración del sistema para que el usuario conceda permiso
  Future<void> openSettings();
}

/// Implementación real con `photo_manager`
///
/// Gestiona automáticamente los permisos según versión de Android:
/// - Android 13+: READ_MEDIA_IMAGES
/// - Android 12 o menor: READ_EXTERNAL_STORAGE
class PhotoManagerGalleryService implements GalleryService {
  /// Álbum "Recientes" (todas las fotos), cacheado tras la primera carga
  AssetPathEntity? _allPhotos;

  /// Entidades cargadas, indexadas por id para obtener los bytes
  final Map<String, AssetEntity> _entities = {};

  @override
  Future<GalleryPermission> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );
    developer.log('Gallery permission: $state', name: 'GalleryService');

    if (state == PermissionState.authorized) return GalleryPermission.granted;
    if (state == PermissionState.limited) return GalleryPermission.limited;
    return GalleryPermission.denied;
  }

  @override
  Future<List<GalleryImage>> loadImages({
    required int page,
    required int pageSize,
  }) async {
    try {
      if (_allPhotos == null) {
        final paths = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          onlyAll: true,
        );
        if (paths.isEmpty) return const [];
        _allPhotos = paths.first;
      }

      final assets = await _allPhotos!.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      for (final asset in assets) {
        _entities[asset.id] = asset;
      }
      developer.log(
        'Loaded page $page: ${assets.length} images',
        name: 'GalleryService',
      );

      return assets
          .map((a) => GalleryImage(id: a.id, createdAt: a.createDateTime))
          .toList();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load gallery page $page',
        name: 'GalleryService',
        error: e,
        stackTrace: stackTrace,
      );
      throw AppError(
        category: ErrorCategory.platformChannel,
        code: ErrorCodes.galleryLoadFailed,
        technicalMessage: e.toString(),
        userMessage: '',
        canRetry: true,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Uint8List?> loadImageBytes(
    GalleryImage image, {
    required int maxSide,
    int quality = 85,
  }) async {
    final entity = _entities[image.id] ?? await AssetEntity.fromId(image.id);
    if (entity == null) return null;

    // photo_manager mantiene la proporción de la foto; el tamaño final
    // queda en torno a [maxSide] (suficiente para pantalla y para la IA).
    return entity.thumbnailDataWithSize(
      ThumbnailSize.square(maxSide),
      format: ThumbnailFormat.jpeg,
      quality: quality,
    );
  }

  @override
  Future<void> openSettings() => PhotoManager.openSetting();
}
