import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../providers/remote_viewer_provider.dart';
import 'client_connect_screen.dart';

/// Screen for viewing remote host screen and sending touch events
///
/// Features:
/// - RTCVideoRenderer for displaying remote stream
/// - GestureDetector overlay for capturing taps
/// - Touch coordinate normalization (0.0-1.0)
/// - Connection status badge
/// - Disconnect button
/// - Auto-return to connect screen on disconnect
class ClientViewerScreen extends StatefulWidget {
  const ClientViewerScreen({super.key});

  @override
  State<ClientViewerScreen> createState() => _ClientViewerScreenState();
}

class _ClientViewerScreenState extends State<ClientViewerScreen> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _rendererInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    try {
      await _renderer.initialize();
      setState(() => _rendererInitialized = true);
      print('✅ [ClientViewerScreen] Renderer initialized');
    } catch (e) {
      print('🔴 [ClientViewerScreen] Failed to initialize renderer: $e');
    }
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<RemoteViewerProvider>(
          builder: (context, provider, child) {
            // Listen for disconnections and navigate back
            if (provider.status == RemoteViewerStatus.disconnected &&
                ModalRoute.of(context)?.isCurrent == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ClientConnectScreen(),
                    ),
                  );
                }
              });
            }

            // Update renderer when remote stream changes
            if (_rendererInitialized &&
                provider.remoteStream != null &&
                _renderer.srcObject != provider.remoteStream) {
              _renderer.srcObject = provider.remoteStream;
              print('✅ [ClientViewerScreen] Remote stream set to renderer');
            }

            return Stack(
              children: [
                // Video renderer (fullscreen)
                if (_rendererInitialized && provider.remoteStream != null)
                  GestureDetector(
                    onTapDown: (details) => _handleTap(details, provider),
                    child: SizedBox.expand(
                      child: RTCVideoView(
                        _renderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                        mirror: false,
                      ),
                    ),
                  )
                else
                  // Loading placeholder
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 4,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Esperando video...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Status badge (top-left)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _StatusBadge(status: provider.status),
                ),

                // Disconnect button (top-right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Semantics(
                    label: 'Desconectar',
                    hint: 'Toca para terminar la sesión remota',
                    button: true,
                    child: FloatingActionButton(
                      onPressed: () => _disconnect(provider),
                      backgroundColor: Colors.red[700],
                      child: const Icon(
                        Icons.close,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Error message (if any)
                if (provider.errorMessage != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.red[700],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Handles tap events on the video
  void _handleTap(TapDownDetails details, RemoteViewerProvider provider) {
    // Get video dimensions
    final videoWidth = _renderer.videoWidth ?? 1;
    final videoHeight = _renderer.videoHeight ?? 1;

    if (videoWidth == 0 || videoHeight == 0) {
      print('🔴 [ClientViewerScreen] Invalid video dimensions: $videoWidth x $videoHeight');
      return;
    }

    // Get render box to calculate normalized coordinates
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Calculate video display dimensions (accounting for aspect ratio)
    final videoAspectRatio = videoWidth / videoHeight;
    final screenAspectRatio = size.width / size.height;

    double displayWidth, displayHeight;
    double offsetX = 0, offsetY = 0;

    if (screenAspectRatio > videoAspectRatio) {
      // Screen is wider than video (letterbox on sides)
      displayHeight = size.height;
      displayWidth = displayHeight * videoAspectRatio;
      offsetX = (size.width - displayWidth) / 2;
    } else {
      // Screen is taller than video (letterbox on top/bottom)
      displayWidth = size.width;
      displayHeight = displayWidth / videoAspectRatio;
      offsetY = (size.height - displayHeight) / 2;
    }

    // Adjust tap coordinates for video offset
    final adjustedX = details.localPosition.dx - offsetX;
    final adjustedY = details.localPosition.dy - offsetY;

    // Check if tap is within video bounds
    if (adjustedX < 0 ||
        adjustedX > displayWidth ||
        adjustedY < 0 ||
        adjustedY > displayHeight) {
      print('🔴 [ClientViewerScreen] Tap outside video bounds');
      return;
    }

    // Normalize coordinates (0.0 - 1.0)
    final normalizedX = adjustedX / displayWidth;
    final normalizedY = adjustedY / displayHeight;

    print('🔵 [ClientViewerScreen] Tap: screen=(${details.localPosition.dx}, ${details.localPosition.dy}), '
        'video=($adjustedX, $adjustedY), normalized=($normalizedX, $normalizedY)');

    // Send touch event to host
    provider.sendTouch(normalizedX, normalizedY);
  }

  /// Disconnects from the session
  Future<void> _disconnect(RemoteViewerProvider provider) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Terminar sesión?',
          style: TextStyle(fontSize: 26),
        ),
        content: const Text(
          '¿Estás seguro de que quieres desconectar?',
          style: TextStyle(fontSize: 22),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 20)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text(
              'Desconectar',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.disconnect();
    }
  }
}

/// Status badge widget showing connection state
class _StatusBadge extends StatelessWidget {
  final RemoteViewerStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Semantics(
      label: 'Estado: ${config.label}',
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: config.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              config.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(RemoteViewerStatus status) {
    switch (status) {
      case RemoteViewerStatus.disconnected:
        return _StatusConfig(
          label: 'Desconectado',
          icon: Icons.cloud_off,
          color: Colors.grey[700]!,
        );
      case RemoteViewerStatus.connecting:
        return _StatusConfig(
          label: 'Conectando...',
          icon: Icons.sync,
          color: Colors.orange[700]!,
        );
      case RemoteViewerStatus.connected:
        return _StatusConfig(
          label: 'Conectado',
          icon: Icons.check_circle,
          color: Colors.green[700]!,
        );
      case RemoteViewerStatus.failed:
        return _StatusConfig(
          label: 'Error',
          icon: Icons.error,
          color: Colors.red[700]!,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;

  _StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}
