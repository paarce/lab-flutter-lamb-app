import 'package:hive/hive.dart';

part 'contact.g.dart';

/// Contact model for storing favorite WhatsApp contacts
///
/// Stored in Hive local database with max 8 contacts enforced
/// at the service level.
///
/// Usage:
/// ```dart
/// final contact = Contact(
///   id: 'uuid-here',
///   name: 'María García',
///   phoneNumber: '+525512345678',
/// );
/// ```
@HiveType(typeId: 0)
class Contact extends HiveObject {
  /// Unique identifier for the contact
  @HiveField(0)
  final String id;

  /// Display name of the contact (user-friendly)
  @HiveField(1)
  String name;

  /// Phone number with country code (e.g., +525512345678)
  @HiveField(2)
  String phoneNumber;

  /// Sort order for display (optional, 0-7)
  @HiveField(3)
  int? sortOrder;

  /// Timestamp when contact was created
  @HiveField(4)
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.sortOrder,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this contact with optional field updates
  Contact copyWith({
    String? name,
    String? phoneNumber,
    int? sortOrder,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  /// Masks the phone number for display (e.g., +52 551 *** **78)
  String get maskedPhoneNumber {
    if (phoneNumber.length < 8) return phoneNumber;

    // Show first 6 chars and last 2 chars
    final prefix = phoneNumber.substring(0, 6);
    final suffix = phoneNumber.substring(phoneNumber.length - 2);
    final maskedMiddle = '*' * (phoneNumber.length - 8);

    return '$prefix $maskedMiddle $suffix';
  }

  /// Normalizes the name for fuzzy matching (removes accents, lowercase)
  String get normalizedName {
    return normalizeString(name);
  }

  /// Normalizes a string for fuzzy matching (public for service use)
  static String normalizeString(String input) {
    // Convert to lowercase
    var result = input.toLowerCase().trim();

    // Remove common Spanish accents
    const accents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const noAccents = 'aeiouunAEIOUUN';

    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], noAccents[i]);
    }

    return result;
  }

  /// Checks if this contact matches the given search query (fuzzy match)
  ///
  /// Matches if the normalized name contains the normalized query
  bool matchesQuery(String query) {
    final normalizedQuery = normalizeString(query);
    return normalizedName.contains(normalizedQuery);
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phone: $maskedPhoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
