import 'package:permission_handler/permission_handler.dart';
import 'package:fast_contacts/fast_contacts.dart';
import '../../models/contact_models.dart';
import '../../utils/app_logger.dart';

class ContactPermissionService {
  /// Request contact permission with user-friendly explanation
  static Future<bool> requestContactPermission() async {
    try {
      // Check current status first
      PermissionStatus status = await Permission.contacts.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // Request permission
        status = await Permission.contacts.request();
        return status.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // Guide user to settings
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e, st) {
      AppLogger.e(
        '[ContactPerm] Error requesting permission',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Check current permission status
  static Future<bool> hasContactPermission() async {
    try {
      PermissionStatus status = await Permission.contacts.status;
      return status.isGranted;
    } catch (e, st) {
      AppLogger.e(
        '[ContactPerm] Error checking permission',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Get contacts using fast_contacts (much faster than contacts_service)
  static Future<List<AppContact>> getContacts() async {
    try {
      if (!await hasContactPermission()) {
        return [];
      }

      // Get all contacts using fast_contacts
      final fastContacts = await FastContacts.getAllContacts();

      // Convert to our AppContact model
      List<AppContact> appContacts = [];

      for (final contact in fastContacts) {
        // Extract first phone number
        String? phoneNumber;
        if (contact.phones.isNotEmpty) {
          phoneNumber = contact.phones.first.number;
        }

        // Only include contacts with phone numbers and display names
        if (phoneNumber != null &&
            phoneNumber.isNotEmpty &&
            contact.displayName.isNotEmpty) {
          appContacts.add(
            AppContact(
              id: contact.id,
              name: contact.displayName,
              phoneNumber: phoneNumber,
              hasAppAccount: false, // Will be determined during sync
              originalContactName: contact.displayName,
            ),
          );
        }
      }

      return appContacts;
    } catch (e, st) {
      AppLogger.e(
        '[ContactPerm] Error getting contacts',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Get contact count for UI display
  static Future<int> getContactCount() async {
    try {
      if (!await hasContactPermission()) {
        return 0;
      }

      final contacts = await getContacts();
      return contacts.length;
    } catch (e, st) {
      AppLogger.e(
        '[ContactPerm] Error getting contact count',
        error: e,
        stackTrace: st,
      );
      return 0;
    }
  }
}
