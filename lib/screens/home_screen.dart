import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import 'remote_control_host_screen.dart';
import 'voice_command_screen.dart';

/// [DEPRECATED] Pantalla inicial original con menú de opciones.
///
/// Esta pantalla fue reemplazada por [VoiceCommandScreen] como pantalla
/// principal de la app, priorizando comandos de voz sobre navegación manual.
///
/// Se mantiene en el codebase para potencial uso futuro como:
/// - Pantalla de configuración avanzada
/// - Flujo secundario para usuarios que prefieren UI tradicional
/// - Acceso a features no disponibles por voz
///
/// Para acceder: Navegar desde VoiceCommandScreen usando comandos de voz
/// o botón "Más opciones" (futuro).
@Deprecated('Use VoiceCommandScreen as main entry point')
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título de bienvenida
              Semantics(
                header: true,
                child: Text(
                  'Bienvenido',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Mensaje descriptivo
              Semantics(
                readOnly: true,
                child: Text(
                  'Selecciona una opción para comenzar',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

              // Botón: Comandos de Voz
              Semantics(
                label: 'Comandos de voz',
                hint: 'Toca dos veces para usar comandos de voz',
                button: true,
                child: ElevatedButton.icon(
                  onPressed: () {
                    developer.log('User pressed voice commands', name: 'HomeScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceCommandScreen()),
                    );
                  },
                  icon: const Icon(Icons.mic, size: 32),
                  label: const Text('Comandos de Voz'),
                ),
              ),

              const SizedBox(height: 24),

              // Botón: WhatsApp (funcionalidad futura)
              Semantics(
                label: 'WhatsApp',
                hint: 'Toca dos veces para abrir asistente de WhatsApp',
                button: true,
                enabled: false,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.message, size: 32),
                  label: const Text('WhatsApp'),
                ),
              ),

              const SizedBox(height: 24),

              // Botón: Control Remoto
              Semantics(
                label: 'Control remoto',
                hint: 'Toca dos veces para iniciar control remoto con tu familiar',
                button: true,
                enabled: true,
                child: ElevatedButton.icon(
                  onPressed: () {
                    developer.log(
                      'User pressed "Control Remoto" button',
                      name: 'HomeScreen',
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RemoteControlHostScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.screen_share, size: 32),
                  label: const Text('Control Remoto'),
                ),
              ),

              const Spacer(),

              // Información de versión
              Semantics(
                readOnly: true,
                child: Text(
                  'Versión 1.0.0 - Setup inicial',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),

      // FloatingActionButton para configuración (futuro)
      floatingActionButton: Semantics(
        label: 'Configuración',
        hint: 'Toca dos veces para abrir configuración',
        button: true,
        child: FloatingActionButton(
          onPressed: () {
            // Mostrar snackbar temporal
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Configuración disponible en próxima versión',
                  style: TextStyle(fontSize: 20),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Icon(Icons.settings, size: 32),
        ),
      ),
    );
  }
}
