import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService {
  NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _webVapidKey =
      String.fromEnvironment('FCM_WEB_VAPID_KEY');
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'megashop_updates',
    'MegaShop Updates',
    description: 'Order and chat updates from MegaShop.',
    importance: Importance.high,
  );

  static StreamSubscription<QuerySnapshot>? _chatSubscription;
  static StreamSubscription<QuerySnapshot>? _orderSubscription;
  static final Set<String> _notifiedChatKeys = {};
  static final Set<String> _notifiedOrderIds = {};
  static bool _chatBaselineReady = false;
  static bool _orderBaselineReady = false;

  static Future<void> configure() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _configureLocalNotifications();
    await _requestPermission();
    await _messaging.setAutoInitEnabled(true);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        syncTokenForCurrentUser();
        _startFirestoreNotificationListeners(user.uid);
      } else {
        _stopFirestoreNotificationListeners();
      }
    });

    _messaging.onTokenRefresh.listen((token) {
      _saveToken(token);
    });

    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageNavigation(initialMessage);
      });
    }
  }

  static Future<void> syncTokenForCurrentUser() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb && _webVapidKey.isNotEmpty ? _webVapidKey : null,
      );
      if (token != null) {
        await _saveToken(token);
      }
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  static Future<void> _requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('FCM permission error: $e');
    }
  }

  static Future<void> _configureLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final navigator = navigatorKey.currentState;
        if (navigator == null) return;

        if (response.payload == 'chat') {
          navigator.pushNamed('/chat');
        } else if (response.payload == 'order') {
          navigator.pushNamed('/notifications');
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  static void _startFirestoreNotificationListeners(String userId) {
    _stopFirestoreNotificationListeners();
    _notifiedChatKeys.clear();
    _notifiedOrderIds.clear();
    _chatBaselineReady = false;
    _orderBaselineReady = false;

    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final unreadBy = data['unreadBy'] as Map<String, dynamic>? ?? {};
        final unreadCount = (unreadBy[userId] ?? 0) as num;
        if (unreadCount <= 0) continue;

        final updatedAt = data['updatedAt'];
        final key =
            '${change.doc.id}_${updatedAt is Timestamp ? updatedAt.millisecondsSinceEpoch : unreadCount}';
        if (!_chatBaselineReady || _notifiedChatKeys.contains(key)) continue;

        _notifiedChatKeys.add(key);
        final senderName = data['buyerId'] == userId
            ? data['sellerName'] ?? 'Seller'
            : data['buyerName'] ?? 'Buyer';
        _showLocalNotification(
          title: 'New chat from $senderName',
          body: data['lastMessage'] ?? 'You have a new message.',
          payload: 'chat',
        );
      }

      _chatBaselineReady = true;
    });

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        if (!_orderBaselineReady || _notifiedOrderIds.contains(change.doc.id)) {
          continue;
        }

        final data = change.doc.data();
        if (data == null) continue;

        _notifiedOrderIds.add(change.doc.id);
        final sellerIds = List<String>.from(data['sellerIds'] ?? []);
        final isIncomingOrder = sellerIds.contains(userId);
        _showLocalNotification(
          title: isIncomingOrder ? 'New order received' : 'Order placed',
          body: isIncomingOrder
              ? 'A buyer placed an order in your shop.'
              : 'Your MegaShop order was created successfully.',
          payload: 'order',
        );
      }

      _orderBaselineReady = true;
    });
  }

  static void _stopFirestoreNotificationListeners() {
    _chatSubscription?.cancel();
    _orderSubscription?.cancel();
    _chatSubscription = null;
    _orderSubscription = null;
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb) return;

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastFcmToken': token,
      'lastFcmPlatform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'notificationsEnabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static void _showForegroundMessage(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? 'MegaShop';
    final body = message.notification?.body ?? 'You have a new update.';

    _showLocalNotification(
      title: title,
      body: body,
      payload: message.data['type'] == 'chat' ? 'chat' : 'order',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title\n$body'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = message.data['type'];
    if (type == 'chat') {
      navigator.pushNamed('/chat');
    } else if (type == 'order') {
      navigator.pushNamed('/notifications');
    }
  }
}
