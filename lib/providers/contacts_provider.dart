import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/contact.dart';
import '../services/contact_storage_service.dart';

/// State management provider for WhatsApp favorite contacts
///
/// Manages up to 8 favorite contacts with:
/// - CRUD operations
/// - Fuzzy search by name
/// - Loading state
///
/// Usage:
/// ```dart
/// final provider = context.read<ContactsProvider>();
/// await provider.loadContacts();
/// final contact = provider.findByName('María');
/// ```
class ContactsProvider extends ChangeNotifier {
  final ContactStorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _error;

  /// All contacts sorted by sortOrder/name
  List<Contact> get contacts => List.unmodifiable(_contacts);

  /// Whether contacts are currently loading
  bool get isLoading => _isLoading;

  /// Last error message (if any)
  String? get error => _error;

  /// Whether more contacts can be added (max 8)
  bool get canAddMore => _contacts.length < ContactStorageService.maxContacts;

  /// Current contact count
  int get count => _contacts.length;

  /// Maximum allowed contacts
  int get maxContacts => ContactStorageService.maxContacts;

  ContactsProvider({
    required ContactStorageService storageService,
  }) : _storageService = storageService;

  /// Initializes the provider and loads contacts from storage
  ///
  /// Call this once during app startup
  Future<void> init() async {
    developer.log('Initializing ContactsProvider', name: 'ContactsProvider');

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _storageService.init();
      _contacts = _storageService.getAll();

      developer.log(
        'Loaded ${_contacts.length} contacts',
        name: 'ContactsProvider',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize contacts',
        name: 'ContactsProvider',
        error: e,
        stackTrace: stackTrace,
      );
      _error = 'Error cargando contactos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads contacts from storage (refresh)
  Future<void> loadContacts() async {
    if (!_storageService.isInitialized) {
      await init();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _contacts = _storageService.getAll();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load contacts',
        name: 'ContactsProvider',
        error: e,
        stackTrace: stackTrace,
      );
      _error = 'Error cargando contactos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new contact
  ///
  /// Returns the created contact, or null if failed
  /// Throws [StateError] if max contacts reached
  Future<Contact?> addContact({
    required String name,
    required String phoneNumber,
  }) async {
    developer.log(
      'Adding contact: $name',
      name: 'ContactsProvider',
    );

    if (!canAddMore) {
      _error = 'No puedes agregar más de $maxContacts contactos';
      notifyListeners();
      return null;
    }

    try {
      _error = null;

      final contact = Contact(
        id: _uuid.v4(),
        name: name.trim(),
        phoneNumber: _sanitizePhoneNumber(phoneNumber),
        sortOrder: _contacts.length,
      );

      await _storageService.save(contact);
      _contacts = _storageService.getAll();

      developer.log(
        'Contact added: ${contact.id}',
        name: 'ContactsProvider',
      );

      notifyListeners();
      return contact;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to add contact',
        name: 'ContactsProvider',
        error: e,
        stackTrace: stackTrace,
      );
      _error = 'Error guardando contacto';
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing contact
  Future<bool> updateContact(Contact contact) async {
    developer.log(
      'Updating contact: ${contact.id}',
      name: 'ContactsProvider',
    );

    try {
      _error = null;

      await _storageService.save(contact);
      _contacts = _storageService.getAll();

      developer.log(
        'Contact updated: ${contact.name}',
        name: 'ContactsProvider',
      );

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update contact',
        name: 'ContactsProvider',
        error: e,
        stackTrace: stackTrace,
      );
      _error = 'Error actualizando contacto';
      notifyListeners();
      return false;
    }
  }

  /// Deletes a contact by ID
  Future<bool> deleteContact(String id) async {
    developer.log(
      'Deleting contact: $id',
      name: 'ContactsProvider',
    );

    try {
      _error = null;

      await _storageService.delete(id);
      _contacts = _storageService.getAll();

      developer.log(
        'Contact deleted',
        name: 'ContactsProvider',
      );

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete contact',
        name: 'ContactsProvider',
        error: e,
        stackTrace: stackTrace,
      );
      _error = 'Error eliminando contacto';
      notifyListeners();
      return false;
    }
  }

  /// Finds a contact by name using fuzzy matching
  ///
  /// Used by voice commands to find contacts by spoken name
  Contact? findByName(String query) {
    // First try using storage service (more robust)
    if (_storageService.isInitialized) {
      return _storageService.findByName(query);
    }

    // Fallback to in-memory search
    final normalizedQuery = _normalizeString(query);

    // Try exact match first
    for (final contact in _contacts) {
      if (contact.normalizedName == normalizedQuery) {
        return contact;
      }
    }

    // Try partial match
    for (final contact in _contacts) {
      if (contact.matchesQuery(query)) {
        return contact;
      }
    }

    return null;
  }

  /// Gets a contact by ID
  Contact? getById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clears any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sanitizes phone number by removing spaces and dashes
  String _sanitizePhoneNumber(String phone) {
    // Remove spaces, dashes, parentheses
    var sanitized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Ensure it starts with + for international format
    if (!sanitized.startsWith('+')) {
      // Assume Mexico if no country code
      if (!sanitized.startsWith('52')) {
        sanitized = '+52$sanitized';
      } else {
        sanitized = '+$sanitized';
      }
    }

    return sanitized;
  }

  /// Normalizes a string for fuzzy matching
  String _normalizeString(String input) {
    var result = input.toLowerCase().trim();

    const accents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const noAccents = 'aeiouunAEIOUUN';

    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], noAccents[i]);
    }

    return result;
  }

  @override
  void dispose() {
    developer.log('Disposing ContactsProvider', name: 'ContactsProvider');
    _storageService.close();
    super.dispose();
  }
}
