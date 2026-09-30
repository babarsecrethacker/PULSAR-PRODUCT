import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService _instance = FirebaseService._();

  factory FirebaseService() => _instance;

  // These are resolved lazily. Touching FirebaseAuth.instance in a field
  // initialiser makes merely *constructing* the service throw
  // "[core/no-app] No Firebase App '[DEFAULT]' has been created" on a
  // platform where Firebase initialisation was skipped, which crashed
  // the app on startup.
  FirebaseAuth? _authOrNull;
  FirebaseDatabase? _databaseOrNull;
  FirebaseMessaging? _messagingOrNull;

  FirebaseAuth get _auth {
    final FirebaseAuth? auth = _authOrNull;
    if (auth == null) {
      throw StateError(
        'Firebase is not initialised. Call initialize() first.',
      );
    }
    return auth;
  }

  FirebaseDatabase get _database {
    final FirebaseDatabase? db = _databaseOrNull;
    if (db == null) {
      throw StateError(
        'Firebase is not initialised. Call initialize() first.',
      );
    }
    return db;
  }

  FirebaseMessaging get _messaging {
    final FirebaseMessaging? m = _messagingOrNull;
    if (m == null) {
      throw StateError(
        'Firebase is not initialised. Call initialize() first.',
      );
    }
    return m;
  }

  User? get currentUser => _authOrNull?.currentUser;

  Stream<User?>? get authStateChanges {
    final FirebaseAuth? auth = _authOrNull;
    if (auth == null) return null;
    return auth.authStateChanges();
  }

  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _available;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Resolved here rather than in field initialisers so that a
      // platform without a configured Firebase app degrades to
      // "unavailable" instead of throwing during construction.
      _authOrNull = FirebaseAuth.instance;
      _databaseOrNull = FirebaseDatabase.instance;
      _messagingOrNull = FirebaseMessaging.instance;

      // Configure Firebase Database
      _database.setPersistenceEnabled(true);
      _database.setPersistenceCacheSizeBytes(10000000);

      // Request notification permissions
      await _requestNotificationPermissions();

      // Set up FCM background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _available = true;
      _initialized = true;
      debugPrint('🔥 FirebaseService initialized');
    } catch (e) {
      _available = false;
      _initialized = true;
      _authOrNull = null;
      _databaseOrNull = null;
      _messagingOrNull = null;
      debugPrint('⚠️ FirebaseService unavailable: $e');
    }
  }

  Future<void> _requestNotificationPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 FCM Permission: ${settings.authorizationStatus}');
  }

  // Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    if (!_available) {
      throw StateError('Firebase is not configured');
    }

    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential credential = await _auth.signInWithProvider(googleProvider);
      debugPrint('✅ Google Sign-In successful: ${credential.user?.email}');
      return credential;
    } catch (e) {
      debugPrint('❌ Google Sign-In failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_available) return;
    await _auth.signOut();
    await _setPresenceOffline();
    debugPrint('👋 Signed out from Firebase');
  }

  Future<void> saveUserProfile({
    required int userId,
    required String name,
    required String email,
    String? picture,
  }) async {
    if (!_available) return;

    final prefs = await SharedPreferences.getInstance();
    final firebaseUid = prefs.getString('pulsar_firebase_uid');
    if (firebaseUid == null) return;

    await _database.ref('users/$firebaseUid/profile').set({
      'id': userId,
      'name': name,
      'email': email,
      'picture': picture ?? '',
      'updatedAt': ServerValue.timestamp,
    });
  }

  // FCM Token Management
  Future<void> registerFCMToken() async {
    if (!_available) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
        await _saveFCMTokenToServer(token);
      }
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _saveFCMTokenToServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('pulsar_user_id');
    final firebaseUid = prefs.getString('pulsar_firebase_uid');

    if (userId != null && firebaseUid != null) {
      try {
        await _database.ref('users/$firebaseUid/profile').update({
          'fcmToken': token,
        });
        debugPrint('📱 FCM token saved to Firebase');
      } catch (e) {
        debugPrint('❌ Failed to save FCM token: $e');
      }
    }
  }

  // Get FCM Token
  Future<String?> getFCMToken() async {
    if (!_available) return null;
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
      return null;
    }
  }

  // Presence Management

  /// Held so it can actually be cancelled. The subscription used to be
  /// discarded, so leaving online mode left a live listener on the whole
  /// `users` node still pushing updates into disposed state.
  StreamSubscription<DatabaseEvent>? _presenceSubscription;

  Future<void> startPresenceListener(int currentUserId) async {
    if (!_available) return;
    final prefs = await SharedPreferences.getInstance();
    final firebaseUid = prefs.getString('pulsar_firebase_uid');
    
    if (firebaseUid == null) return;

    try {
      // Set own presence online
      await _setPresenceOnline(firebaseUid);

      // Listen to all users' presence
      await stopPresenceListener();

      _presenceSubscription =
          _database.ref('users').onValue.listen((event) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          // Update local presence cache
          _updatePresenceCache(data);
        }
      });

      debugPrint('👁️ Presence listener started');
    } catch (e) {
      debugPrint('❌ Failed to start presence listener: $e');
    }
  }

  /// Cancels the presence stream and marks the account offline so other
  /// clients stop showing it as active.
  Future<void> stopPresenceListener() async {
    final StreamSubscription<DatabaseEvent>? sub =
        _presenceSubscription;

    if (sub != null) {
      await sub.cancel();
      _presenceSubscription = null;
    }

    if (!_available) return;

    try {
      await _setPresenceOffline();
    } catch (e) {
      debugPrint('❌ Failed to clear presence: $e');
    }
  }

  Future<void> _setPresenceOnline(String firebaseUid) async {
    await _database.ref('users/$firebaseUid/presence').set({
      'online': true,
      'lastSeen': ServerValue.timestamp,
    });

    // Set up onDisconnect to mark offline
    await _database.ref('users/$firebaseUid/presence').onDisconnect().update({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> _setPresenceOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final firebaseUid = prefs.getString('pulsar_firebase_uid');
    
    if (firebaseUid != null) {
      await _database.ref('users/$firebaseUid/presence').update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
  }

  void _updatePresenceCache(Map<dynamic, dynamic> data) {
    // Presence data received - can be used to update UI
    debugPrint('👥 Presence update received: ${data.length} users');
  }

  // WebRTC Signaling via Firebase
  Future<void> sendOffer(String callId, String fromUid, String toUid, Map<String, dynamic> sdp) async {
    await _database.ref('users/$toUid/signaling/offers/$callId').set({
      'from': fromUid,
      'sdp': sdp,
      'type': 'offer',
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> sendAnswer(String callId, String fromUid, String toUid, Map<String, dynamic> sdp) async {
    await _database.ref('users/$toUid/signaling/answers/$callId').set({
      'from': fromUid,
      'sdp': sdp,
      'type': 'answer',
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> sendCandidate(String callId, String fromUid, String toUid, Map<String, dynamic> candidate) async {
    await _database.ref('users/$toUid/signaling/candidates/$callId').push().set({
      'from': fromUid,
      'candidate': candidate,
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<DatabaseEvent> listenForOffers(String firebaseUid) {
    return _database.ref('users/$firebaseUid/signaling/offers').onChildAdded;
  }

  Stream<DatabaseEvent> listenForAnswers(String firebaseUid) {
    return _database.ref('users/$firebaseUid/signaling/answers').onChildAdded;
  }

  Stream<DatabaseEvent> listenForCandidates(String firebaseUid) {
    return _database.ref('users/$firebaseUid/signaling/candidates').onChildAdded;
  }

  Future<void> clearSignalingData(String firebaseUid, String callId) async {
    await _database.ref('users/$firebaseUid/signaling/offers/$callId').remove();
    await _database.ref('users/$firebaseUid/signaling/answers/$callId').remove();
    await _database.ref('users/$firebaseUid/signaling/candidates/$callId').remove();
  }

  // Message Handling via Firebase (for P2P fallback)
  Future<void> sendMessageViaFirebase(String fromUid, String toUid, String text, String messageId) async {
    await _database.ref('users/$toUid/messages/$messageId').set({
      'from': fromUid,
      'text': text,
      'timestamp': ServerValue.timestamp,
      'status': 'sent',
    });
  }

  Stream<DatabaseEvent> listenForMessages(String firebaseUid) {
    return _database.ref('users/$firebaseUid/messages').onChildAdded;
  }

  Future<void> markMessageDelivered(String firebaseUid, String messageId) async {
    await _database.ref('users/$firebaseUid/messages/$messageId').update({
      'status': 'delivered',
    });
  }

  Future<void> markMessageRead(String firebaseUid, String messageId) async {
    await _database.ref('users/$firebaseUid/messages/$messageId').update({
      'status': 'read',
    });
  }

  // FCM Message Handlers
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('📱 Background FCM message: ${message.messageId}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground FCM message: ${message.data}');
    // Handle foreground notification - show in-app notification
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Notification tapped: ${message.data}');
    // Navigate to chat/conversation based on message data
  }

  void dispose() {
    _setPresenceOffline();
    _initialized = false;
  }
}