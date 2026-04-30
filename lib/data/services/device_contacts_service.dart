import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to interface with the device's native contacts book.
class DeviceContactsService {
  const DeviceContactsService();

  /// Requests permission to access contacts.
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) return true;
    
    final result = await Permission.contacts.request();
    return result.isGranted;
  }

  /// Fetches all contacts that have at least one phone number.
  /// Returns a list of phone numbers (as strings).
  Future<List<String>> fetchAllPhoneNumbers() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final phones = <String>{}; // Use a set to avoid duplicates

      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = phone.number.trim();
          if (normalized.isNotEmpty) {
            phones.add(normalized);
          }
        }
      }
      return phones.toList();
    } catch (e) {
      // Log error or handle gracefully
      return [];
    }
  }
}
