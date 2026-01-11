import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/controllers/auth_controller.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';
import 'package:url_launcher/url_launcher.dart';

class UserStatusService extends GetxService {
  static UserStatusService get instance => Get.find();
  
  StreamSubscription<DocumentSnapshot>? _userStatusSub;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen(_handleAuthChanged);
  }

  void _handleAuthChanged(User? user) {
    _userStatusSub?.cancel();
    if (user != null) {
      _listenToUserStatus(user.uid);
    }
  }

  void _listenToUserStatus(String uid) {
    _userStatusSub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      
      // Check for ban status
      final isBanned = data['isBanned'] == true;
      if (isBanned) {
        final banReason = data['banReason'] ?? 'Violation of terms';
        final banExpiresAt = data['banExpiresAt'] as Timestamp?;
        
        if (banExpiresAt != null && banExpiresAt.toDate().isBefore(DateTime.now())) {
          return; // Ban expired
        }
        
        _handleBan(banReason, banExpiresAt?.toDate());
        return;
      }

      final forceLogoutAt = data['forceLogoutAt'] as Timestamp?;
      if (forceLogoutAt != null) {
        // TODO: Compare with stored local login time for better precision
        _handleForceLogout(forceLogoutAt);
      }
    });
  }

  Future<void> _handleBan(String reason, DateTime? expiresAt) async {
    await AuthController.instance.signOut();
    
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Account Suspended'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your account has been suspended.'),
              const SizedBox(height: 10),
              Text('Reason: $reason'),
              if (expiresAt != null)
                Text('Expires: ${expiresAt.toLocal()}'),
              const SizedBox(height: 20),
              const Text('If you believe this is a mistake, please contact support.'),
            ],
          ),
          actions: [
            LiquidGlassButton.text(
              onTap: () => _contactSupport(),
              text: 'Contact Support',
            ),
            LiquidGlassButton.text(
              onTap: () => Get.back(), // Will go to onboarding because of signOut
              text: 'Close',
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _handleForceLogout(Timestamp forceLogoutAt) async {
    AppLogger.d('Force logout triggered by admin');
    await AuthController.instance.signOut();
    
    Get.snackbar(
      'Session Expired',
      'You have been logged out by an administrator.',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@shopple.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Account Suspension Appeal',
        'body': 'My account (${_auth.currentUser?.email}) was suspended. Please review.',
      }),
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
  
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  void onClose() {
    _userStatusSub?.cancel();
    super.onClose();
  }
}
