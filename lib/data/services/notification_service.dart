import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage _) async {}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  static const _prefKey = 'lastSeenBroadcastsAt';

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);
    _fcm.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
      .collection(FirestoreCollections.users).doc(uid)
      .update({'fcmToken': token}).catchError((_) {});
  }

  static String _topic(String uni) =>
    'uni_${uni.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

  Future<void> subscribeToUniversity(String shortName) =>
    _fcm.subscribeToTopic(_topic(shortName));

  Future<void> switchUniversity(String? oldName, String newName) async {
    if (oldName != null && oldName.isNotEmpty) {
      await _fcm.unsubscribeFromTopic(_topic(oldName));
    }
    await subscribeToUniversity(newName);
  }

  static Future<void> broadcastNewPost({
    required String postId,
    required String universityShortName,
    required String title,
    required String body,
  }) async {
    try {
      await FirebaseFirestore.instance
        .collection('broadcasts')
        .doc(postId)
        .set({
          'postId':              postId,
          'universityShortName': universityShortName,
          'posterUid':           FirebaseAuth.instance.currentUser?.uid ?? '',
          'title':               title,
          'body':                body,
          'type':                'new_post',
          'createdAt':           DateTime.now().toIso8601String(),
        });
    } catch (e) {
      debugPrint('broadcastNewPost error: $e');
    }
  }

  static Future<String> getLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? '1970-01-01T00:00:00.000Z';
  }

  static Future<void> markBroadcastsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, DateTime.now().toIso8601String());
  }
}