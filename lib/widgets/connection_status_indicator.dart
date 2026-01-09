import 'package:flutter/material.dart';

import '../providers/remote_control_provider.dart';

/// Widget that displays the current connection status
///
/// Features:
/// - Color-coded status (not relying solely on color)
/// - Icon + text for each status
/// - Large text for readability
/// - Accessible semantic labels
class ConnectionStatusIndicator extends StatelessWidget {
  /// Current connection status
  final RemoteControlStatus status;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    return Semantics(
      label: 'Estado de conexión: ${statusInfo.message}',
      liveRegion: true, // Announce changes to screen reader
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusInfo.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusInfo.borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Icon(
              statusInfo.icon,
              size: 36,
              color: statusInfo.iconColor,
            ),

            const SizedBox(width: 16),

            // Status message
            Expanded(
              child: Text(
                statusInfo.message,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: statusInfo.textColor,
                ),
              ),
            ),

            // Loading indicator for in-progress states
            if (statusInfo.showLoadingIndicator) ...[
              const SizedBox(width: 16),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(statusInfo.iconColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Gets UI information for the given status
  _StatusInfo _getStatusInfo(RemoteControlStatus status) {
    switch (status) {
      case RemoteControlStatus.idle:
        return _StatusInfo(
          message: 'Sin sesión activa',
          icon: Icons.power_settings_new,
          iconColor: Colors.grey[700]!,
          textColor: Colors.grey[700]!,
          backgroundColor: Colors.grey[100]!,
          borderColor: Colors.grey[400]!,
          showLoadingIndicator: false,
        );

      case RemoteControlStatus.requestingPermission:
        return _StatusInfo(
          message: 'Solicitando permisos...',
          icon: Icons.security,
          iconColor: Colors.orange[700]!,
          textColor: Colors.orange[900]!,
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[300]!,
          showLoadingIndicator: true,
        );

      case RemoteControlStatus.creatingSession:
        return _StatusInfo(
          message: 'Creando sesión...',
          icon: Icons.settings,
          iconColor: Colors.blue[700]!,
          textColor: Colors.blue[900]!,
          backgroundColor: Colors.blue[50]!,
          borderColor: Colors.blue[300]!,
          showLoadingIndicator: true,
        );

      case RemoteControlStatus.waitingForClient:
        return _StatusInfo(
          message: 'Esperando conexión...',
          icon: Icons.hourglass_empty,
          iconColor: Colors.amber[700]!,
          textColor: Colors.amber[900]!,
          backgroundColor: Colors.amber[50]!,
          borderColor: Colors.amber[300]!,
          showLoadingIndicator: true,
        );

      case RemoteControlStatus.connecting:
        return _StatusInfo(
          message: 'Conectando...',
          icon: Icons.sync,
          iconColor: Colors.lightBlue[700]!,
          textColor: Colors.lightBlue[900]!,
          backgroundColor: Colors.lightBlue[50]!,
          borderColor: Colors.lightBlue[300]!,
          showLoadingIndicator: true,
        );

      case RemoteControlStatus.connected:
        return _StatusInfo(
          message: 'Conectado - Compartiendo pantalla',
          icon: Icons.check_circle,
          iconColor: Colors.green[700]!,
          textColor: Colors.green[900]!,
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[300]!,
          showLoadingIndicator: false,
        );

      case RemoteControlStatus.ended:
        return _StatusInfo(
          message: 'Sesión terminada',
          icon: Icons.done,
          iconColor: Colors.grey[700]!,
          textColor: Colors.grey[700]!,
          backgroundColor: Colors.grey[100]!,
          borderColor: Colors.grey[400]!,
          showLoadingIndicator: false,
        );

      case RemoteControlStatus.error:
        return _StatusInfo(
          message: 'Error de conexión',
          icon: Icons.error,
          iconColor: Colors.red[700]!,
          textColor: Colors.red[900]!,
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[300]!,
          showLoadingIndicator: false,
        );
    }
  }
}

/// Information for displaying a status
class _StatusInfo {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showLoadingIndicator;

  _StatusInfo({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.showLoadingIndicator,
  });
}
