import 'package:flutter/material.dart';

import '../models/contact.dart';

/// Accessible card widget for displaying a favorite WhatsApp contact
///
/// Features:
/// - 80dp minimum height for touch target
/// - WhatsApp icon and contact info
/// - Tap to open chat, long-press to edit
/// - Full Semantics for TalkBack
///
/// Usage:
/// ```dart
/// ContactCard(
///   contact: contact,
///   onTap: () => openChat(contact),
///   onLongPress: () => editContact(contact),
/// )
/// ```
class ContactCard extends StatelessWidget {
  /// The contact to display
  final Contact contact;

  /// Called when the card is tapped (open chat)
  final VoidCallback? onTap;

  /// Called when the card is long-pressed (edit contact)
  final VoidCallback? onLongPress;

  const ContactCard({
    super.key,
    required this.contact,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Contacto ${contact.name}',
      hint: 'Toca dos veces para abrir chat. Mantén presionado para editar.',
      button: true,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // WhatsApp icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366), // WhatsApp green
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Contact info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        contact.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.maskedPhoneNumber,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
