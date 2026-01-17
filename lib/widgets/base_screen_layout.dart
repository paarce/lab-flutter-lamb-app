import 'package:flutter/material.dart';

/// Widget base para crear pantallas con layout consistente.
///
/// Proporciona:
/// - AppBar con título y botón de retroceso opcional
/// - Contenido scrollable con padding estándar (24dp)
/// - Footer sticky con botones de acción principales
///
/// Uso:
/// ```dart
/// BaseScreenLayout(
///   title: 'Mi Pantalla',
///   content: [
///     Text('Contenido aquí'),
///     // más widgets...
///   ],
///   footerActions: [
///     AccessibleButton(
///       label: 'Acción Principal',
///       onPressed: () => ...,
///     ),
///   ],
/// )
/// ```
class BaseScreenLayout extends StatelessWidget {
  /// Título mostrado en el AppBar
  final String title;

  /// Si se muestra el botón de retroceso en el AppBar (default: true)
  final bool showBackButton;

  /// Lista de widgets que conforman el contenido scrollable
  final List<Widget> content;

  /// Lista de widgets (botones) para el footer sticky.
  /// Se recomienda usar 1-3 AccessibleButton widgets.
  /// Si está vacío, no se muestra footer.
  final List<Widget> footerActions;

  /// Acciones adicionales para el AppBar (trailing)
  final List<Widget>? appBarActions;

  /// Widget para FloatingActionButton (opcional)
  final Widget? floatingActionButton;

  const BaseScreenLayout({
    super.key,
    required this.title,
    this.showBackButton = true,
    required this.content,
    this.footerActions = const [],
    this.appBarActions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(title),
        ),
        leading: showBackButton
            ? Semantics(
                label: 'Volver',
                hint: 'Toca dos veces para regresar a la pantalla anterior',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
            : null,
        automaticallyImplyLeading: showBackButton,
        actions: appBarActions,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: content,
          ),
        ),
      ),
      persistentFooterButtons: footerActions.isNotEmpty
          ? [_buildFooter(context)]
          : null,
      floatingActionButton: floatingActionButton,
    );
  }

  /// Construye el footer con los botones de acción envueltos en Semantics
  Widget _buildFooter(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Acciones principales',
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 32, // Padding horizontal
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildFooterChildren(),
        ),
      ),
    );
  }

  /// Construye los hijos del footer con espaciado entre ellos
  List<Widget> _buildFooterChildren() {
    final List<Widget> children = [];

    for (int i = 0; i < footerActions.length; i++) {
      children.add(footerActions[i]);

      // Agregar espaciado entre botones (excepto después del último)
      if (i < footerActions.length - 1) {
        children.add(const SizedBox(height: 16));
      }
    }

    return children;
  }
}
