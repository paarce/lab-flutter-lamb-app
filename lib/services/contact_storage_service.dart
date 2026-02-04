import 'dart:developer' as developer;

import 'package:hive/hive.dart';

import '../models/contact.dart';

/// Service for persisting and managing contacts with Hive
///
/// Features:
/// - CRUD operations for contacts
/// - Maximum 8 contacts enforced
/// - Fuzzy search by name
///
/// Usage:
/// ```dart
/// final service = ContactStorageService();
/// await service.init();
/// await service.save(contact);
/// final contacts = service.getAll();
/// ```
class ContactStorageService {
  static const String _boxName = 'contacts';
  static const int maxContacts = 8;

  Box<Contact>? _box;

  /// Whether the service has been initialized
  bool get isInitialized => _box != null && _box!.isOpen;

  /// Opens the Hive box for contacts
  ///
  /// Must be called before any other operations
  Future<void> init() async {
    if (_box != null && _box!.isOpen) {
      developer.log('Box already open', name: 'ContactStorageService');
      return;
    }

    developer.log('Opening contacts box', name: 'ContactStorageService');
    _box = await Hive.openBox<Contact>(_boxName);
    developer.log(
      'Contacts box opened with ${_box!.length} contacts',
      name: 'ContactStorageService',
    );
  }

  /// Ensures the box is initialized
  void _ensureInitialized() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'ContactStorageService not initialized. Call init() first.',
      );
    }
  }

  /// Gets all contacts sorted by sortOrder, then by name
  List<Contact> getAll() {
    _ensureInitialized();

    final contacts = _box!.values.toList();

    // Sort by sortOrder (nulls last), then by name
    contacts.sort((a, b) {
      final orderA = a.sortOrder ?? 999;
      final orderB = b.sortOrder ?? 999;

      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    developer.log(
      'Retrieved ${contacts.length} contacts',
      name: 'ContactStorageService',
    );

    return contacts;
  }

  /// Gets a contact by its ID
  Contact? getById(String id) {
    _ensureInitialized();
    return _box!.get(id);
  }

  /// Saves a contact (create or update)
  ///
  /// Throws [StateError] if trying to add more than 8 contacts
  Future<void> save(Contact contact) async {
    _ensureInitialized();

    // Check if this is a new contact and we're at the limit
    final existing = _box!.get(contact.id);
    if (existing == null && _box!.length >= maxContacts) {
      developer.log(
        'Cannot save contact: max limit of $maxContacts reached',
        name: 'ContactStorageService',
      );
      throw StateError(
        'No puedes agregar más de $maxContacts contactos favoritos',
      );
    }

    await _box!.put(contact.id, contact);
    developer.log(
      'Saved contact: ${contact.name} (${contact.id})',
      name: 'ContactStorageService',
    );
  }

  /// Deletes a contact by its ID
  Future<void> delete(String id) async {
    _ensureInitialized();

    final contact = _box!.get(id);
    if (contact != null) {
      await _box!.delete(id);
      developer.log(
        'Deleted contact: ${contact.name} ($id)',
        name: 'ContactStorageService',
      );
    } else {
      developer.log(
        'Contact not found for deletion: $id',
        name: 'ContactStorageService',
      );
    }
  }

  /// Finds a contact by name using fuzzy matching
  ///
  /// Returns the first contact that matches the query, or null
  Contact? findByName(String query) {
    _ensureInitialized();

    final contacts = _box!.values.toList();

    // Try exact match first (normalized)
    for (final contact in contacts) {
      if (contact.normalizedName == Contact.normalizeString(query)) {
        developer.log(
          'Exact match found: ${contact.name}',
          name: 'ContactStorageService',
        );
        return contact;
      }
    }

    // Try partial match (contains)
    for (final contact in contacts) {
      if (contact.matchesQuery(query)) {
        developer.log(
          'Partial match found: ${contact.name} for query "$query"',
          name: 'ContactStorageService',
        );
        return contact;
      }
    }

    developer.log(
      'No match found for query: "$query"',
      name: 'ContactStorageService',
    );
    return null;
  }

  /// Checks if we can add more contacts
  bool get canAddMore {
    _ensureInitialized();
    return _box!.length < maxContacts;
  }

  /// Gets the current number of contacts
  int get count {
    _ensureInitialized();
    return _box!.length;
  }

  /// Closes the Hive box
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      developer.log('Contacts box closed', name: 'ContactStorageService');
    }
  }
}
