import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../providers/contacts_provider.dart';
import '../services/tts/tts_service.dart';
import '../widgets/accessible_button.dart';
import '../widgets/base_screen_layout.dart';

/// Screen for adding or editing a WhatsApp contact
///
/// Features:
/// - Name field (required)
/// - Phone number field with country code
/// - 80dp buttons, 24sp text
/// - Delete button in edit mode
/// - Full accessibility support
class ContactConfigurationScreen extends StatefulWidget {
  /// Contact to edit (null for new contact)
  final Contact? contact;

  const ContactConfigurationScreen({
    super.key,
    this.contact,
  });

  @override
  State<ContactConfigurationScreen> createState() =>
      _ContactConfigurationScreenState();
}

class _ContactConfigurationScreenState
    extends State<ContactConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _isEditing = widget.contact != null;

    if (_isEditing) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;
    }

    // Announce screen for TalkBack
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tts = context.read<TTSService>();
      if (_isEditing) {
        tts.speak('Editando contacto ${widget.contact!.name}');
      } else {
        tts.speak('Agregar nuevo contacto favorito');
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Editar Contacto' : 'Nuevo Contacto';

    return BaseScreenLayout(
      title: title,
      showBackButton: true,
      content: _buildContent(),
      footerActions: _buildFooterActions(),
    );
  }

  List<Widget> _buildContent() {
    final theme = Theme.of(context);

    return [
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            Semantics(
              label: 'Nombre del contacto',
              hint: 'Escribe el nombre como quieres que aparezca',
              textField: true,
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(fontSize: 20),
                  hintText: 'Ej: María García',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(Icons.person, size: 28),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(fontSize: 24),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 24),

            // Phone number field
            Semantics(
              label: 'Número de teléfono con código de país',
              hint: 'Incluye el código de país, por ejemplo más 52 para México',
              textField: true,
              child: TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  labelStyle: const TextStyle(fontSize: 20),
                  hintText: 'Ej: +52 55 1234 5678',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(Icons.phone, size: 28),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Incluye el código de país (+52 para México)',
                  helperStyle: const TextStyle(fontSize: 14),
                ),
                style: const TextStyle(fontSize: 24),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]')),
                ],
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es obligatorio';
                  }
                  // Remove formatting to check length
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) {
                    return 'El número debe tener al menos 10 dígitos';
                  }
                  if (digits.length > 15) {
                    return 'El número es demasiado largo';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 32),

            // Info text
            Semantics(
              readOnly: true,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Podrás abrir este chat diciendo el nombre del contacto',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Add padding for footer
      const SizedBox(height: 120),
    ];
  }

  List<Widget> _buildFooterActions() {
    final actions = <Widget>[];

    // Save button
    actions.add(
      AccessibleButton(
        label: _isSaving ? 'Guardando...' : 'Guardar',
        icon: Icons.save,
        semanticHint: 'Toca dos veces para guardar el contacto',
        onPressed: _isSaving ? null : () => _saveContact(),
      ),
    );

    // Delete button (only in edit mode)
    if (_isEditing) {
      actions.add(
        AccessibleButton(
          label: 'Eliminar',
          icon: Icons.delete,
          isDestructive: true,
          semanticHint: 'Toca dos veces para eliminar este contacto',
          onPressed: _isSaving ? null : () => _confirmDelete(),
        ),
      );
    }

    return actions;
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      // Announce validation error
      final tts = context.read<TTSService>();
      await tts.speak('Por favor, corrige los errores del formulario');
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<ContactsProvider>();
    final tts = context.read<TTSService>();

    try {
      if (_isEditing) {
        // Update existing contact
        final updated = widget.contact!.copyWith(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

        final success = await provider.updateContact(updated);

        if (success && mounted) {
          await tts.speak('Contacto actualizado');
          Navigator.pop(context);
        } else if (mounted) {
          await tts.speak(provider.error ?? 'Error al guardar');
        }
      } else {
        // Create new contact
        final contact = await provider.addContact(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

        if (contact != null && mounted) {
          await tts.speak('Contacto guardado');
          Navigator.pop(context);
        } else if (mounted) {
          await tts.speak(provider.error ?? 'Error al guardar');
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to save contact',
        name: 'ContactConfigurationScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        await tts.speak('Error al guardar el contacto');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final tts = context.read<TTSService>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          header: true,
          child: Text(
            'Eliminar contacto',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                ),
          ),
        ),
        content: Semantics(
          readOnly: true,
          child: Text(
            '¿Estás seguro de eliminar a ${widget.contact!.name}?',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Cancelar',
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Eliminar',
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteContact();
    } else {
      await tts.speak('Eliminación cancelada');
    }
  }

  Future<void> _deleteContact() async {
    setState(() => _isSaving = true);

    final provider = context.read<ContactsProvider>();
    final tts = context.read<TTSService>();

    try {
      final success = await provider.deleteContact(widget.contact!.id);

      if (success && mounted) {
        await tts.speak('Contacto eliminado');
        Navigator.pop(context);
      } else if (mounted) {
        await tts.speak(provider.error ?? 'Error al eliminar');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete contact',
        name: 'ContactConfigurationScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        await tts.speak('Error al eliminar el contacto');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
