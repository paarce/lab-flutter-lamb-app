import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/image_reader_config.dart';
import '../models/image_description.dart';
import '../providers/image_reader_provider.dart';
import '../services/error_handler_service.dart';
import '../services/gallery_service.dart';
import '../services/tts/tts_service.dart';
import '../services/vision/vision_service.dart';
import '../services/vision/vision_service_factory.dart';
import '../widgets/accessible_button.dart';

/// Lector de Imágenes (Feature 6.4)
///
/// Muestra las fotos de la galería a pantalla completa. Al detenerse en una
/// foto ~2 segundos, la IA la interpreta y la lee en voz alta (chat, foto,
/// resultados médicos, documento...).
///
/// [galleryService] y [visionService] son opcionales para inyectar fakes en
/// tests; por defecto se usan `photo_manager` y el proveedor configurado.
class ImageReaderScreen extends StatelessWidget {
  final GalleryService? galleryService;
  final VisionService? visionService;

  const ImageReaderScreen({
    super.key,
    this.galleryService,
    this.visionService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ImageReaderProvider>(
      create: (context) => ImageReaderProvider(
        gallery: galleryService ?? PhotoManagerGalleryService(),
        vision: visionService ?? VisionServiceFactory.create(),
        tts: context.read<TTSService>(),
      )..initialize(),
      child: const _ImageReaderView(),
    );
  }
}

class _ImageReaderView extends StatefulWidget {
  const _ImageReaderView();

  @override
  State<_ImageReaderView> createState() => _ImageReaderViewState();
}

class _ImageReaderViewState extends State<_ImageReaderView> {
  final PageController _pageController = PageController();

  /// Panel de texto visible (se oculta para ver la foto completa)
  bool _panelVisible = true;

  bool _showingError = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImageReaderProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _showPendingError());

    final isReady = provider.status == ImageReaderStatus.ready;

    return Scaffold(
      backgroundColor: isReady ? Colors.black : null,
      appBar: AppBar(
        title: Semantics(header: true, child: const Text('Mis fotos')),
        leading: Semantics(
          label: 'Volver',
          hint: 'Toca dos veces para regresar a la pantalla anterior',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          if (isReady)
            Semantics(
              label: _panelVisible ? 'Ocultar texto' : 'Mostrar texto',
              hint: 'Toca dos veces para ver la foto completa o el texto',
              button: true,
              child: IconButton(
                iconSize: 32,
                icon: Icon(
                  _panelVisible ? Icons.fullscreen : Icons.subject,
                ),
                onPressed: _togglePanel,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: isReady
            ? _buildViewer(provider)
            : _buildStatusContent(provider),
      ),
    );
  }

  // ========================================
  // Estados sin fotos (cargando, permiso, vacío, error)
  // ========================================

  Widget _buildStatusContent(ImageReaderProvider provider) {
    switch (provider.status) {
      case ImageReaderStatus.initial:
      case ImageReaderStatus.requestingPermission:
      case ImageReaderStatus.loading:
      case ImageReaderStatus.ready:
        return _buildMessage(
          icon: null,
          message: 'Abriendo tus fotos...',
          showProgress: true,
        );
      case ImageReaderStatus.permissionDenied:
        return _buildMessage(
          icon: Icons.lock_outline,
          message: 'Necesito permiso para ver tus fotos.',
          actions: [
            AccessibleButton(
              label: 'Abrir configuración',
              icon: Icons.settings,
              semanticHint:
                  'Toca dos veces para abrir la configuración y dar permiso de fotos',
              onPressed: () => provider.gallery.openSettings(),
            ),
            AccessibleButton(
              label: 'Ya lo activé',
              icon: Icons.refresh,
              semanticHint: 'Toca dos veces para volver a intentar',
              onPressed: () => provider.initialize(),
            ),
          ],
        );
      case ImageReaderStatus.empty:
        return _buildMessage(
          icon: Icons.photo_library_outlined,
          message: 'No hay fotos en tu galería.',
        );
      case ImageReaderStatus.error:
        return _buildMessage(
          icon: Icons.error_outline,
          message: 'No pude abrir tus fotos.',
          actions: [
            AccessibleButton(
              label: 'Intentar de nuevo',
              icon: Icons.refresh,
              onPressed: () => provider.initialize(),
            ),
          ],
        );
    }
  }

  Widget _buildMessage({
    required IconData? icon,
    required String message,
    bool showProgress = false,
    List<Widget> actions = const [],
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          if (showProgress)
            const Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(strokeWidth: 6),
              ),
            ),
          if (icon != null) Icon(icon, size: 96),
          const SizedBox(height: 24),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(height: 24),
            action,
          ],
        ],
      ),
    );
  }

  // ========================================
  // Visor de fotos
  // ========================================

  Widget _buildViewer(ImageReaderProvider provider) {
    final images = provider.images;
    final current = provider.currentIndex;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: provider.onPageChanged,
                itemBuilder: (context, index) => _GalleryPhoto(
                  key: ValueKey(images[index].id),
                  image: images[index],
                  gallery: provider.gallery,
                  semanticLabel: _photoSemanticLabel(provider, index),
                  onTap: _togglePanel,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _buildCounter(
                  current + 1,
                  images.length,
                  provider.hasLimitedAccess,
                ),
              ),
            ],
          ),
        ),
        if (_panelVisible) _buildDescriptionPanel(provider),
        _buildControls(provider),
      ],
    );
  }

  String _photoSemanticLabel(ImageReaderProvider provider, int index) {
    final position = 'Foto ${index + 1} de ${provider.images.length}.';
    final description = provider.analysisFor(provider.images[index]).description;
    return description == null
        ? '$position Desliza con dos dedos para cambiar de foto.'
        : '$position ${description.spokenText}';
  }

  Widget _buildCounter(int position, int total, bool limited) {
    final text = limited
        ? 'Foto $position de $total (solo las que elegiste)'
        : 'Foto $position de $total';
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionPanel(ImageReaderProvider provider) {
    final theme = Theme.of(context);
    final analysis = provider.currentAnalysis;
    final maxHeight = MediaQuery.of(context).size.height * 0.35;

    final Widget content;
    switch (analysis.state) {
      case AnalysisState.idle:
        content = _panelStatus(
          provider.autoReadEnabled
              ? 'Quédate en esta foto y te la leeré.'
              : 'Lectura automática pausada. Toca "Leer foto".',
        );
        break;
      case AnalysisState.analyzing:
        content = Row(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
            const SizedBox(width: 16),
            Expanded(child: _panelStatus('Leyendo la foto...')),
          ],
        );
        break;
      case AnalysisState.failed:
        content = _panelStatus('No pude leer esta foto.');
        break;
      case AnalysisState.done:
        final description = analysis.description!;
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Row(
                children: [
                  Icon(_iconFor(description.kind),
                      size: 32, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      description.kind.label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description.spokenText,
              style: TextStyle(
                fontSize: 24,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        );
        break;
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Semantics(
        container: true,
        label: 'Descripción de la foto',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }

  Widget _panelStatus(String text) {
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  IconData _iconFor(ImageKind kind) {
    switch (kind) {
      case ImageKind.chatScreenshot:
        return Icons.chat;
      case ImageKind.medicalResults:
        return Icons.monitor_heart;
      case ImageKind.document:
        return Icons.description;
      case ImageKind.photo:
        return Icons.photo_camera;
      case ImageKind.other:
        return Icons.image;
    }
  }

  Widget _buildControls(ImageReaderProvider provider) {
    final index = provider.currentIndex;
    final total = provider.images.length;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Semantics(
        container: true,
        label: 'Controles de fotos',
        child: Row(
          children: [
            Expanded(
              child: _ControlButton(
                icon: Icons.chevron_left,
                label: 'Anterior',
                hint: 'Toca dos veces para ver la foto anterior',
                onPressed: index > 0 ? () => _goTo(index - 1) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildMainAction(provider)),
            const SizedBox(width: 8),
            Expanded(
              child: _ControlButton(
                icon: Icons.chevron_right,
                label: 'Siguiente',
                hint: 'Toca dos veces para ver la siguiente foto',
                onPressed: index < total - 1 ? () => _goTo(index + 1) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón central: cambia según el estado de la lectura
  Widget _buildMainAction(ImageReaderProvider provider) {
    if (provider.isSpeaking) {
      return _ControlButton(
        icon: Icons.stop,
        label: 'Detener',
        hint: 'Toca dos veces para dejar de leer',
        onPressed: provider.stopSpeaking,
      );
    }

    switch (provider.currentAnalysis.state) {
      case AnalysisState.analyzing:
        return const _ControlButton(
          icon: Icons.hourglass_bottom,
          label: 'Leyendo',
          hint: 'Espera mientras leo la foto',
          onPressed: null,
        );
      case AnalysisState.failed:
        return _ControlButton(
          icon: Icons.refresh,
          label: 'Reintentar',
          hint: 'Toca dos veces para intentar leer la foto otra vez',
          onPressed: provider.retryCurrent,
        );
      case AnalysisState.done:
        return _ControlButton(
          icon: Icons.replay,
          label: 'Repetir',
          hint: 'Toca dos veces para escuchar la descripción otra vez',
          onPressed: provider.repeatCurrent,
        );
      case AnalysisState.idle:
        return _ControlButton(
          icon: Icons.record_voice_over,
          label: 'Leer foto',
          hint: 'Toca dos veces para leer esta foto ahora',
          onPressed: provider.readCurrentNow,
        );
    }
  }

  void _goTo(int index) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _togglePanel() => setState(() => _panelVisible = !_panelVisible);

  Future<void> _showPendingError() async {
    if (!mounted || _showingError) return;
    final provider = context.read<ImageReaderProvider>();
    final error = provider.takePendingError();
    if (error == null) return;

    _showingError = true;
    final isReadingError = provider.status == ImageReaderStatus.ready;
    developer.log(
      'Showing error ${error.code}',
      name: 'ImageReaderScreen',
    );
    await ErrorHandlerService.handleError(
      context: context,
      error: error,
      service: 'ImageReaderScreen',
      canRetry: error.canRetry,
      onRetry: isReadingError ? provider.retryCurrent : provider.initialize,
    );
    _showingError = false;
  }
}

/// Foto individual a pantalla completa (carga bajo demanda)
class _GalleryPhoto extends StatefulWidget {
  final GalleryImage image;
  final GalleryService gallery;
  final String semanticLabel;
  final VoidCallback onTap;

  const _GalleryPhoto({
    super.key,
    required this.image,
    required this.gallery,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  State<_GalleryPhoto> createState() => _GalleryPhotoState();
}

class _GalleryPhotoState extends State<_GalleryPhoto> {
  late final Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.gallery.loadImageBytes(
      widget.image,
      maxSide: ImageReaderConfig.maxImageSide,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final cacheWidth = (media.size.width * media.devicePixelRatio).round();

    return Semantics(
      image: true,
      label: widget.semanticLabel,
      hint: 'Toca dos veces para mostrar u ocultar el texto',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: FutureBuilder<Uint8List?>(
          future: _bytes,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            final bytes = snapshot.data;
            if (bytes == null) {
              return const Center(
                child: Icon(Icons.broken_image, size: 96, color: Colors.white),
              );
            }
            return SizedBox.expand(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                cacheWidth: cacheWidth > 0 ? cacheWidth : null,
                gaplessPlayback: true,
                // Foto corrupta o formato no soportado
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 96, color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Botón de control: icono grande + texto, 88dp de alto
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: SizedBox(
        height: 88,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.disabledColor,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 36),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
