import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/services/user/other_user_details_service.dart';
import 'package:shopple/services/privacy/privacy_settings_service.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';

class FirebaseTestHelper {
  static late MockFirebaseAuth auth;
  static late FakeFirebaseFirestore firestore;

  static Future<void> setup() async {
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();

    // Inject into services/widgets
    UserProfileStreamService.instance.firestore = firestore;
    PresenceService.firestore = firestore;
    OtherUserDetailsService.instance.firestore = firestore;
    PrivacySettingsService.instance.firestore = firestore;
    PrivacySettingsService.instance.auth = auth;
    UnifiedProfileAvatar.firebaseAuthInstance = auth;
  }
  
  /// Seed test users into the fake Firestore
  static Future<void> seedUsers(List<Map<String, dynamic>> users) async {
    for (final user in users) {
      final userId = user['userId'] as String;
      await firestore.collection('users').doc(userId).set(user);
    }
  }
  
  /// Seed default privacy settings for users
  static Future<void> seedPrivacySettings(List<String> userIds) async {
    for (final userId in userIds) {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('privacy')
          .set({
        'searchableByName': true,
        'searchableByEmail': true,
        'searchableByPhone': true,
        'isFullyPrivate': false,
        'emailVisibility': 'partial',
        'phoneVisibility': 'partial',
        'nameVisibility': 'full',
      });
    }
  }
}
