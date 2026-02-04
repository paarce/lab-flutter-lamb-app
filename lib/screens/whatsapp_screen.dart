import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../providers/contacts_provider.dart';
import '../services/error_handler_service.dart';
import '../services/tts/tts_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/accessible_button.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/contact_card.dart';
import 'contact_configuration_screen.dart';

/// WhatsApp favorite contacts screen
///
/// Features:
/// - Display up to 8 favorite contacts
/// - Tap contact to open WhatsApp chat
/// - Long-press to edit contact
/// - Add new contacts button
/// - Full accessibility support
class WhatsAppScreen extends StatefulWidget {
  const WhatsAppScreen({super.key});

  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  @override
  void initState() {
    super.initState();

    // Announce screen for TalkBack
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tts = context.read<TTSService>();
      tts.speak('Pantalla de WhatsApp. Tus contactos favoritos.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, contactsProvider, _) {
        return BaseScreenLayout(
          title: 'WhatsApp',
          showBackButton: true,
          content: _buildContent(contactsProvider),
          footerActions: _buildFooterActions(contactsProvider),
        );
      },
    );
  }

  List<Widget> _buildContent(ContactsProvider provider) {
    final widgets = <Widget>[];

    // Loading state
    if (provider.isLoading) {
      widgets.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
      return widgets;
    }

    // Error state
    if (provider.error != null) {
      widgets.add(
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              provider.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Header
    widgets.add(
      Semantics(
        header: true,
        child: Text(
          'Contactos Favoritos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );

    widgets.add(const SizedBox(height: 8));

    // Contact count
    widgets.add(
      Semantics(
        readOnly: true,
        child: Text(
          '${provider.count} de ${provider.maxContacts} contactos',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );

    widgets.add(const SizedBox(height: 16));

    // Contact list
    if (provider.contacts.isEmpty) {
      widgets.add(
        Semantics(
          readOnly: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes contactos favoritos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega hasta 8 contactos para abrirlos por voz',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      for (final contact in provider.contacts) {
        widgets.add(
          ContactCard(
            contact: contact,
            onTap: () => _openChat(contact),
            onLongPress: () => _editContact(contact),
          ),
        );
      }
    }

    // Add some bottom padding for the footer
    widgets.add(const SizedBox(height: 100));

    return widgets;
  }

  List<Widget> _buildFooterActions(ContactsProvider provider) {
    final actions = <Widget>[];

    // Add contact button (if not at max)
    if (provider.canAddMore) {
      actions.add(
        AccessibleButton(
          label: 'Agregar Contacto',
          icon: Icons.person_add,
          semanticHint: 'Toca dos veces para agregar un nuevo contacto favorito',
          onPressed: () => _addContact(),
        ),
      );
    } else {
      actions.add(
        Semantics(
          readOnly: true,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Has alcanzado el máximo de ${provider.maxContacts} contactos',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return actions;
  }

  Future<void> _openChat(Contact contact) async {
    developer.log(
      'Opening chat for: ${contact.name}',
      name: 'WhatsAppScreen',
    );

    final tts = context.read<TTSService>();
    final whatsAppService = context.read<WhatsAppService>();

    await tts.speak('Abriendo chat de ${contact.name}');

    try {
      await whatsAppService.openChatByPhone(contact.phoneNumber);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to open chat',
        name: 'WhatsAppScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        await ErrorHandlerService.handleError(
          context: context,
          error: e,
          service: 'WhatsApp',
        );
      }
    }
  }

  void _editContact(Contact contact) {
    developer.log(
      'Editing contact: ${contact.name}',
      name: 'WhatsAppScreen',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactConfigurationScreen(contact: contact),
      ),
    );
  }

  void _addContact() {
    developer.log('Adding new contact', name: 'WhatsAppScreen');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ContactConfigurationScreen(),
      ),
    );
  }
}
