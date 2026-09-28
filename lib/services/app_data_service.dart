import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/publication_model.dart';
import '../models/offer_model.dart';
import '../models/activity_model.dart';
import '../models/subscriber_model.dart';
import '../models/admin_notification_model.dart';
import '../models/order_model.dart';

class AppDataService extends ChangeNotifier {
  static final AppDataService _instance = AppDataService._internal();
  factory AppDataService() => _instance;
  AppDataService._internal();

  // Cloud Synchronization Endpoint (Partage en temps réel entre PC, téléphones et tous visiteurs)
  static const String _cloudBaseUrl = 'https://kvdb.io/6Ecw5eC7W6g1m2pG9G2J5Y';

  List<Publication> _publications = [];
  List<Offer> _offers = [];
  List<Subscriber> _subscribers = [];
  List<AdminNotification> _notifications = [];
  List<OrderItem> _orders = [];
  String _whatsAppNumber = AppConstants.whatsAppNumber;
  bool _isInitialized = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;
  bool _isAutoSyncEnabled = true;
  bool _isSyncing = false;

  List<Publication> get publications => List.unmodifiable(_publications);
  List<Offer> get offers => List.unmodifiable(_offers);
  List<Subscriber> get subscribers => List.unmodifiable(_subscribers);
  List<AdminNotification> get notifications => List.unmodifiable(_notifications);
  List<OrderItem> get orders => List.unmodifiable(_orders);
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;
  String get whatsAppNumber => _whatsAppNumber;
  bool get isInitialized => _isInitialized;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;
  bool get isSyncing => _isSyncing;

  List<Publication> get publishedPublications =>
      _publications.where((p) => p.isPublished).toList()
        ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));

  List<Offer> get activeOffers =>
      _offers.where((o) => o.isActive).toList()
        ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));

  static const String _publicationsKey = 'gm_publications_data_v1';
  static const String _offersKey = 'gm_offers_data_v1';
  static const String _subscribersKey = 'gm_subscribers_data_v1';
  static const String _notificationsKey = 'gm_admin_notifications_v1';
  static const String _ordersKey = 'gm_orders_data_v1';
  static const String _whatsAppKey = 'gm_whatsapp_number_v1';
  static const String _likedPubsKey = 'gm_liked_publications_v1';
  static const String _followedPubsKey = 'gm_followed_publications_v1';

  final Set<String> _likedPublicationIds = {};
  final Set<String> _followedPublicationIds = {};

  bool isPublicationLiked(String id) => _likedPublicationIds.contains(id);
  bool isPublicationFollowed(String id) => _followedPublicationIds.contains(id);

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // WhatsApp Number
      _whatsAppNumber = prefs.getString(_whatsAppKey) ?? AppConstants.whatsAppNumber;

      // Publications (Non-destructive merge: keep all stored, add new default system publications)
      final pubJson = prefs.getString(_publicationsKey);
      if (pubJson != null && pubJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(pubJson);
        final storedPubs = decoded.map((item) => Publication.fromJson(item)).toList();
        final storedIds = storedPubs.map((p) => p.id).toSet();
        final defaultPubs = _getDefaultPublications();
        final newDefaults = defaultPubs.where((p) => !storedIds.contains(p.id)).toList();
        _publications = [...storedPubs, ...newDefaults];
        await _savePublications();
      } else {
        _publications = _getDefaultPublications();
        await _savePublications();
      }

      // Offers (Non-destructive merge: keep all stored, add new default system offers)
      final offerJson = prefs.getString(_offersKey);
      if (offerJson != null && offerJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(offerJson);
        final storedOffers = decoded.map((item) => Offer.fromJson(item)).toList();
        final storedIds = storedOffers.map((o) => o.id).toSet();
        final defaultOffers = _getDefaultOffers();
        final newDefaults = defaultOffers.where((o) => !storedIds.contains(o.id)).toList();
        _offers = [...storedOffers, ...newDefaults];
        await _saveOffers();
      } else {
        _offers = _getDefaultOffers();
        await _saveOffers();
      }

      // Subscribers (Preserve all existing subscriptions)
      final subJson = prefs.getString(_subscribersKey);
      if (subJson != null && subJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(subJson);
        _subscribers = decoded.map((item) => Subscriber.fromJson(item)).toList();
      } else {
        _subscribers = [];
      }

      // Orders (Preserve all existing client orders)
      final orderJson = prefs.getString(_ordersKey);
      if (orderJson != null && orderJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(orderJson);
        _orders = decoded.map((item) => OrderItem.fromJson(item)).toList();
      } else {
        _orders = [];
      }

      // Notifications (Preserve all existing admin notifications)
      final notifJson = prefs.getString(_notificationsKey);
      if (notifJson != null && notifJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(notifJson);
        _notifications = decoded.map((item) => AdminNotification.fromJson(item)).toList();
      } else {
        _notifications = [];
      }

      // Liked & Followed Sets
      final likedList = prefs.getStringList(_likedPubsKey);
      if (likedList != null) {
        _likedPublicationIds.addAll(likedList);
      }
      final followedList = prefs.getStringList(_followedPubsKey);
      if (followedList != null) {
        _followedPublicationIds.addAll(followedList);
      }

      _isInitialized = true;
      _lastSyncTime = DateTime.now();
      startAutoSync(); // Lance l'auto-synchronisation automatique toutes les 10 secondes
      notifyListeners();

      // Synchronisation Cloud immédiate en arrière-plan pour récupérer les données publiées depuis d'autres appareils (PC / mobiles)
      unawaited(_pullFromCloud(notify: true));
    } catch (e) {
      debugPrint('Error loading AppDataService: $e');
      _publications = _getDefaultPublications();
      _offers = _getDefaultOffers();
      _subscribers = [];
      _notifications = [];
      _orders = [];
      _isInitialized = true;
      _lastSyncTime = DateTime.now();
      startAutoSync();
      notifyListeners();
      unawaited(_pullFromCloud(notify: true));
    }
  }

  /// Démarre la recherche automatique des mises à jour toutes les 10 secondes
  void startAutoSync({Duration interval = const Duration(seconds: 10)}) {
    _autoSyncTimer?.cancel();
    _isAutoSyncEnabled = true;
    _autoSyncTimer = Timer.periodic(interval, (_) async {
      await syncData(silent: true);
    });
  }

  /// Arrête la recherche automatique des mises à jour
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _isAutoSyncEnabled = false;
  }

  /// Force ou exécute la synchronisation et la sauvegarde globale des données
  /// sans JAMAIS supprimer les publications ou données existantes.
  Future<void> syncData({bool silent = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    if (!silent) {
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      // 1. Récupération Cloud (Cross-device real-time sync)
      await _pullFromCloud(notify: false);

      // 2. WhatsApp Number
      final newWhatsApp = prefs.getString(_whatsAppKey) ?? AppConstants.whatsAppNumber;

      // 3. Publications: Non-destructive merge between in-memory and stored data
      final pubJson = prefs.getString(_publicationsKey);
      if (pubJson != null && pubJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(pubJson);
        final storedPubs = decoded.map((item) => Publication.fromJson(item)).toList();
        final Map<String, Publication> mergedMap = {};
        for (final p in storedPubs) {
          mergedMap[p.id] = p;
        }
        for (final p in _publications) {
          mergedMap[p.id] = p;
        }
        _publications = mergedMap.values.toList();
      }

      // 4. Offers: Non-destructive merge
      final offerJson = prefs.getString(_offersKey);
      if (offerJson != null && offerJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(offerJson);
        final storedOffers = decoded.map((item) => Offer.fromJson(item)).toList();
        final Map<String, Offer> mergedOffers = {};
        for (final o in storedOffers) {
          mergedOffers[o.id] = o;
        }
        for (final o in _offers) {
          mergedOffers[o.id] = o;
        }
        _offers = mergedOffers.values.toList();
      }

      // 5. Subscribers: Non-destructive merge
      final subJson = prefs.getString(_subscribersKey);
      if (subJson != null && subJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(subJson);
        final storedSubs = decoded.map((item) => Subscriber.fromJson(item)).toList();
        final Map<String, Subscriber> mergedSubs = {};
        for (final s in storedSubs) {
          mergedSubs[s.id] = s;
        }
        for (final s in _subscribers) {
          mergedSubs[s.id] = s;
        }
        _subscribers = mergedSubs.values.toList();
      }

      // 6. Orders: Non-destructive merge
      final orderJson = prefs.getString(_ordersKey);
      if (orderJson != null && orderJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(orderJson);
        final storedOrders = decoded.map((item) => OrderItem.fromJson(item)).toList();
        final Map<String, OrderItem> mergedOrders = {};
        for (final o in storedOrders) {
          mergedOrders[o.id] = o;
        }
        for (final o in _orders) {
          mergedOrders[o.id] = o;
        }
        _orders = mergedOrders.values.toList();
      }

      // 7. Notifications: Non-destructive merge
      final notifJson = prefs.getString(_notificationsKey);
      if (notifJson != null && notifJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(notifJson);
        final storedNotifs = decoded.map((item) => AdminNotification.fromJson(item)).toList();
        final Map<String, AdminNotification> mergedNotifs = {};
        for (final n in storedNotifs) {
          mergedNotifs[n.id] = n;
        }
        for (final n in _notifications) {
          mergedNotifs[n.id] = n;
        }
        _notifications = mergedNotifs.values.toList();
      }

      _whatsAppNumber = newWhatsApp;

      // Sauvegarde explicite locale
      await _savePublications(pushToCloud: false);
      await _saveOffers(pushToCloud: false);
      await _saveSubscribers(pushToCloud: false);
      await _saveNotifications();
      await _saveOrders(pushToCloud: false);

      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during syncData: $e');
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();
    }
  }

  // --- Cloud Synchronization Methods (kvdb.io over HTTPS) ---
  Future<void> _pushToCloud(String key, String jsonBody) async {
    try {
      final url = Uri.parse('$_cloudBaseUrl/$key');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonBody,
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Cloud sync push error for $key: $e');
    }
  }

  Future<void> _pullFromCloud({bool notify = false}) async {
    bool hasChanges = false;
    final prefs = await SharedPreferences.getInstance();

    // 1. Publications
    try {
      final pubUrl = Uri.parse('$_cloudBaseUrl/gm_publications_v1');
      final res = await http.get(pubUrl).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty && res.body != 'null') {
        final List<dynamic> decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final cloudPubs = decoded.map((item) => Publication.fromJson(item)).toList();
        final Map<String, Publication> map = {};
        for (final p in _publications) {
          map[p.id] = p;
        }
        for (final p in cloudPubs) {
          map[p.id] = p;
        }
        final merged = map.values.toList();
        if (merged.length != _publications.length || jsonEncode(merged) != jsonEncode(_publications)) {
          _publications = merged;
          hasChanges = true;
          await prefs.setString(_publicationsKey, jsonEncode(_publications.map((p) => p.toJson()).toList()));
        }
      }
    } catch (e) {
      debugPrint('Cloud pull publications error: $e');
    }

    // 2. Offers
    try {
      final offUrl = Uri.parse('$_cloudBaseUrl/gm_offers_v1');
      final res = await http.get(offUrl).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty && res.body != 'null') {
        final List<dynamic> decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final cloudOffers = decoded.map((item) => Offer.fromJson(item)).toList();
        final Map<String, Offer> map = {};
        for (final o in _offers) {
          map[o.id] = o;
        }
        for (final o in cloudOffers) {
          map[o.id] = o;
        }
        final merged = map.values.toList();
        if (merged.length != _offers.length || jsonEncode(merged) != jsonEncode(_offers)) {
          _offers = merged;
          hasChanges = true;
          await prefs.setString(_offersKey, jsonEncode(_offers.map((o) => o.toJson()).toList()));
        }
      }
    } catch (e) {
      debugPrint('Cloud pull offers error: $e');
    }

    // 3. Orders
    try {
      final ordUrl = Uri.parse('$_cloudBaseUrl/gm_orders_v1');
      final res = await http.get(ordUrl).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty && res.body != 'null') {
        final List<dynamic> decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final cloudOrders = decoded.map((item) => OrderItem.fromJson(item)).toList();
        final Map<String, OrderItem> map = {};
        for (final o in _orders) {
          map[o.id] = o;
        }
        for (final o in cloudOrders) {
          map[o.id] = o;
        }
        final merged = map.values.toList();
        if (merged.length != _orders.length) {
          _orders = merged;
          hasChanges = true;
          await prefs.setString(_ordersKey, jsonEncode(_orders.map((o) => o.toJson()).toList()));
        }
      }
    } catch (e) {
      debugPrint('Cloud pull orders error: $e');
    }

    // 4. WhatsApp
    try {
      final whatsUrl = Uri.parse('$_cloudBaseUrl/gm_whatsapp_v1');
      final res = await http.get(whatsUrl).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty && res.body != 'null') {
        final cloudWhatsApp = res.body.trim();
        if (cloudWhatsApp != _whatsAppNumber) {
          _whatsAppNumber = cloudWhatsApp;
          hasChanges = true;
          await prefs.setString(_whatsAppKey, _whatsAppNumber);
        }
      }
    } catch (e) {
      debugPrint('Cloud pull whatsapp error: $e');
    }

    if (hasChanges && notify) {
      notifyListeners();
    }
  }

  // --- Publications CRUD ---
  Future<void> addPublication(Publication publication) async {
    _publications.insert(0, publication);
    await _savePublications();
    notifyListeners();
  }

  Future<void> updatePublication(Publication updated) async {
    final index = _publications.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _publications[index] = updated;
      await _savePublications();
      notifyListeners();
    }
  }

  Future<void> deletePublication(String id) async {
    _publications.removeWhere((p) => p.id == id);
    await _savePublications();
    notifyListeners();
  }

  /// Exporte toutes les publications au format JSON textuel
  String exportPublicationsToJson() {
    return const JsonEncoder.withIndent('  ').convert(
      _publications.map((p) => p.toJson()).toList(),
    );
  }

  /// Importe des publications depuis du JSON et les fusionne sans doublons
  Future<int> importPublicationsFromJson(String jsonString) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final List<Publication> imported = decoded.map((item) => Publication.fromJson(item)).toList();
      final Map<String, Publication> map = {};
      for (final p in _publications) {
        map[p.id] = p;
      }
      for (final p in imported) {
        map[p.id] = p;
      }
      _publications = map.values.toList();
      await _savePublications();
      notifyListeners();
      return imported.length;
    } catch (e) {
      debugPrint('Error importing publications: $e');
      return 0;
    }
  }

  /// Exporte toutes les offres au format JSON textuel
  String exportOffersToJson() {
    return const JsonEncoder.withIndent('  ').convert(
      _offers.map((o) => o.toJson()).toList(),
    );
  }

  /// Importe des offres depuis du JSON et les fusionne sans doublons
  Future<int> importOffersFromJson(String jsonString) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final List<Offer> imported = decoded.map((item) => Offer.fromJson(item)).toList();
      final Map<String, Offer> map = {};
      for (final o in _offers) {
        map[o.id] = o;
      }
      for (final o in imported) {
        map[o.id] = o;
      }
      _offers = map.values.toList();
      await _saveOffers();
      notifyListeners();
      return imported.length;
    } catch (e) {
      debugPrint('Error importing offers: $e');
      return 0;
    }
  }

  Future<void> incrementPublicationViews(String id) async {
    final index = _publications.indexWhere((p) => p.id == id);
    if (index != -1) {
      final pub = _publications[index];
      _publications[index] = pub.copyWith(viewsCount: pub.viewsCount + 1);
      await _savePublications();
      notifyListeners();
    }
  }

  Future<void> addCommentToPublication(String publicationId, PublicationComment comment) async {
    final index = _publications.indexWhere((p) => p.id == publicationId);
    if (index != -1) {
      final pub = _publications[index];
      final updatedComments = [comment, ...pub.comments];
      _publications[index] = pub.copyWith(comments: updatedComments);
      await _savePublications();

      // Notification pour l'administrateur
      final notif = AdminNotification(
        id: 'notif_cmt_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Nouveau Commentaire 💬',
        message: '${comment.authorName} a commenté : "${pub.title}"\n« ${comment.content} »',
        type: 'comment',
        createdAt: DateTime.now(),
        data: {
          'publicationId': pub.id,
          'commentId': comment.id,
          'author': comment.authorName,
          'content': comment.content,
        },
      );
      await addNotification(notif);
      notifyListeners();
    }
  }

  Future<void> toggleLikePublication(String id) async {
    final index = _publications.indexWhere((p) => p.id == id);
    if (index != -1) {
      final pub = _publications[index];
      final isLiked = _likedPublicationIds.contains(id);
      int newLikes = pub.likesCount;
      if (isLiked) {
        _likedPublicationIds.remove(id);
        newLikes = (newLikes - 1).clamp(0, 999999);
      } else {
        _likedPublicationIds.add(id);
        newLikes = newLikes + 1;
        // Créer une notification pour l'administrateur
        addNotification(AdminNotification(
          id: 'notif_like_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Nouveau Like 👍',
          message: 'Un visiteur a aimé la publication : "${pub.title}"',
          type: 'like',
          createdAt: DateTime.now(),
          data: {'publicationId': pub.id, 'title': pub.title},
        ));
      }
      _publications[index] = pub.copyWith(likesCount: newLikes);
      await _savePublications();
      await _saveLikedAndFollowed();
      notifyListeners();
    }
  }

  Future<void> toggleFollowPublication(String id) async {
    final index = _publications.indexWhere((p) => p.id == id);
    if (index != -1) {
      final pub = _publications[index];
      final isFollowed = _followedPublicationIds.contains(id);
      int newFollowers = pub.followersCount;
      if (isFollowed) {
        _followedPublicationIds.remove(id);
        newFollowers = (newFollowers - 1).clamp(0, 999999);
      } else {
        _followedPublicationIds.add(id);
        newFollowers = newFollowers + 1;
      }
      _publications[index] = pub.copyWith(followersCount: newFollowers);
      await _savePublications();
      await _saveLikedAndFollowed();
      notifyListeners();
    }
  }

  Future<void> incrementPublicationShares(String id) async {
    final index = _publications.indexWhere((p) => p.id == id);
    if (index != -1) {
      final pub = _publications[index];
      final newShares = pub.sharesCount + 1;
      _publications[index] = pub.copyWith(sharesCount: newShares);
      await _savePublications();

      // Notification pour l'administrateur
      final notif = AdminNotification(
        id: 'notif_share_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Nouveau Partage 📢',
        message: 'Un visiteur a partagé : "${pub.title}" ($newShares partages au total)',
        type: 'share',
        createdAt: DateTime.now(),
        data: {'publicationId': pub.id, 'title': pub.title, 'sharesCount': newShares},
      );
      await addNotification(notif);
      notifyListeners();
    }
  }

  Future<void> _saveLikedAndFollowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_likedPubsKey, _likedPublicationIds.toList());
      await prefs.setStringList(_followedPubsKey, _followedPublicationIds.toList());
    } catch (e) {
      debugPrint('Error saving liked/followed: $e');
    }
  }

  // --- Subscribers ---
  Future<bool> addSubscriber(Subscriber subscriber) async {
    final exists = _subscribers.any(
      (s) => s.email.trim().toLowerCase() == subscriber.email.trim().toLowerCase(),
    );
    if (exists) {
      return false;
    }
    _subscribers.insert(0, subscriber);
    await _saveSubscribers();

    // Auto-create Admin Notification
    final notif = AdminNotification(
      id: 'notif_sub_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Nouvel Abonné 🎉',
      message: '${subscriber.fullName?.isNotEmpty == true ? subscriber.fullName : subscriber.email} vient de s\'abonner à Great Minds Group (${subscriber.email}).',
      type: 'subscription',
      createdAt: DateTime.now(),
      data: subscriber.toJson(),
    );
    await addNotification(notif);
    notifyListeners();
    return true;
  }

  Future<void> deleteSubscriber(String id) async {
    _subscribers.removeWhere((s) => s.id == id);
    await _saveSubscribers();
    notifyListeners();
  }

  Future<void> _saveSubscribers({bool pushToCloud = true}) async {
    try {
      final encoded = jsonEncode(_subscribers.map((s) => s.toJson()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscribersKey, encoded);
      if (pushToCloud) {
        unawaited(_pushToCloud('gm_subscribers_v1', encoded));
      }
    } catch (e) {
      debugPrint('Error saving subscribers: $e');
    }
  }

  // --- Admin Notifications ---
  Future<void> addNotification(AdminNotification notification) async {
    _notifications.insert(0, notification);
    if (_notifications.length > 200) {
      _notifications = _notifications.sublist(0, 200);
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_notificationsKey, encoded);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  // --- Orders & E-commerce Payments ---
  Future<void> addOrder(OrderItem order) async {
    _orders.insert(0, order);
    await _saveOrders();

    // Notification instantanée pour l'administrateur
    final notif = AdminNotification(
      id: 'notif_ord_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Nouvelle Commande 🛍️ (${order.totalAmount})',
      message: '${order.customerName} a commandé ${order.quantity}x "${order.productTitle}" (${order.totalAmount}).\nTél: ${order.customerPhone} | Adresse: ${order.deliveryAddress}',
      type: 'order',
      createdAt: DateTime.now(),
      data: order.toJson(),
    );
    await addNotification(notif);
    notifyListeners();
  }

  Future<void> updateOrderStatus(String id, String status) async {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: status);
      await _saveOrders();
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String id) async {
    _orders.removeWhere((o) => o.id == id);
    await _saveOrders();
    notifyListeners();
  }

  Future<void> _saveOrders({bool pushToCloud = true}) async {
    try {
      final encoded = jsonEncode(_orders.map((o) => o.toJson()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ordersKey, encoded);
      if (pushToCloud) {
        unawaited(_pushToCloud('gm_orders_v1', encoded));
      }
    } catch (e) {
      debugPrint('Error saving orders: $e');
    }
  }

  // --- Offers CRUD ---
  Future<void> addOffer(Offer offer) async {
    _offers.insert(0, offer);
    await _saveOffers();
    notifyListeners();
  }

  Future<void> updateOffer(Offer updated) async {
    final index = _offers.indexWhere((o) => o.id == updated.id);
    if (index != -1) {
      _offers[index] = updated;
      await _saveOffers();
      notifyListeners();
    }
  }

  Future<void> toggleOfferStatus(String id) async {
    final index = _offers.indexWhere((o) => o.id == id);
    if (index != -1) {
      final offer = _offers[index];
      _offers[index] = offer.copyWith(isActive: !offer.isActive);
      await _saveOffers();
      notifyListeners();
    }
  }

  Future<void> deleteOffer(String id) async {
    _offers.removeWhere((o) => o.id == id);
    await _saveOffers();
    notifyListeners();
  }

  // --- WhatsApp & Config ---
  Future<void> setWhatsAppNumber(String number) async {
    _whatsAppNumber = number.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_whatsKey, _whatsAppNumber);
      unawaited(_pushToCloud('gm_whatsapp_v1', _whatsAppNumber));
    } catch (e) {
      debugPrint('Error saving whatsapp: $e');
    }
    notifyListeners();
  }

  static const String _whatsKey = 'gm_whatsapp_number_v1';

  Future<void> resetToDemoData() async {
    _publications = _getDefaultPublications();
    _offers = _getDefaultOffers();
    _whatsAppNumber = AppConstants.whatsAppNumber;
    await _savePublications();
    await _saveOffers();
    notifyListeners();
  }

  // --- Persistence helpers ---
  Future<void> _savePublications({bool pushToCloud = true}) async {
    try {
      final encoded = jsonEncode(_publications.map((p) => p.toJson()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_publicationsKey, encoded);
      if (pushToCloud) {
        unawaited(_pushToCloud('gm_publications_v1', encoded));
      }
    } catch (e) {
      debugPrint('Error saving publications: $e');
    }
  }

  Future<void> _saveOffers({bool pushToCloud = true}) async {
    try {
      final encoded = jsonEncode(_offers.map((o) => o.toJson()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_offersKey, encoded);
      if (pushToCloud) {
        unawaited(_pushToCloud('gm_offers_v1', encoded));
      }
    } catch (e) {
      debugPrint('Error saving offers: $e');
    }
  }

  // --- Preloaded Initial Professional Data ---
  List<Publication> _getDefaultPublications() {
    return [
      Publication(
        id: 'pub_video_1',
        title: 'GM Media & Production : Présentation Institutionnelle & Création de Contenus',
        category: 'Actualité',
        department: 'GM Media & Production',
        summary: 'Découvrez en vidéo les coulisses de nos studios de production audiovisuelle, couverture médiatique et valorisation des talents.',
        content: '''GM Media & Production est la branche dédiée à la communication, à la création de contenus percutants, à la production audiovisuelle et à la mise en lumière des talents.\n\nNos services incluent :\n• Conception et réalisation de spots publicitaires, reportages et documentaires\n• Stratégie de marque et communication digitale 360°\n• Couverture d'événements et diffusion haute définition\n• Formation aux métiers des médias, du cadrage et du montage.\n\nVisionnez notre vidéo de présentation pour découvrir notre univers créatif !''',
        author: 'Direction GM Media',
        price: 'Sur devis',
        imageUrl: 'assets/Imag.jpeg',
        videoUrl: 'https://www.youtube.com/watch?v=LXb3EKWsInQ',
        publishedDate: DateTime.now().subtract(const Duration(hours: 12)),
        isPublished: true,
        tags: ['Vidéo', 'Media', 'Production', 'Création', 'Audiovisuel'],
        viewsCount: 520,
        likesCount: 98,
        followersCount: 185,
        sharesCount: 42,
      ),
      Publication(
        id: 'pub_auto_1',
        title: 'GM Auto Solutions : Vente & Importation de Véhicules Certifiés et Pièces d’Origine',
        category: 'Opportunité',
        department: 'GM Autosolution',
        summary: 'Découvrez notre catalogue exclusif de SUV, berlines et pick-ups révisés, avec garantie mécanique et livraison sécurisée.',
        content: '''GM Auto Solutions accompagne particuliers et entreprises dans l'achat, l'importation sur-mesure et l'entretien de véhicules haut de gamme et utilitaires.\n\nNos garanties :\n• Inspection technique et historique complet avant livraison\n• Dédouanement et immatriculation clés en main\n• Stock permanent de pièces de rechange certifiées constructeur (Toyota, Nissan, Hyundai, Mercedes)\n• Service après-vente et diagnostic électronique complet.\n\nContactez notre équipe commerciale pour obtenir un devis ou planifier un essai.''',
        author: 'Service Commercial GM Auto',
        price: 'À partir de 12 500 \$',
        imageUrl: 'assets/gm_auto.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=7LHqA26W3q4',
        publishedDate: DateTime.now().subtract(const Duration(days: 1)),
        isPublished: true,
        tags: ['Automobile', 'Vente', 'Importation', 'Entretien', 'Pièces'],
        viewsCount: 430,
        likesCount: 88,
        followersCount: 172,
        sharesCount: 38,
      ),
      Publication(
        id: 'pub_1',
        title: 'GM Formation & Emploi : Lancement du Programme d’Accélération Professionnelle 2026',
        category: 'Actualité',
        department: 'GM Formation & Emploi',
        summary: 'GREAT MINDS GROUP ouvre les candidatures pour son nouveau cycle intensif de formation et de placement pour 150 jeunes.',
        content: '''GREAT MINDS GROUP franchit une nouvelle étape dans son engagement pour l'employabilité des jeunes talents.\n\nCe programme intensif de 3 mois combine :\n• Des modules pratiques en compétences clés et leadership professionnel\n• Du coaching individuel avec des mentors issus du monde de l'entreprise\n• Un accompagnement sur-mesure pour l'accès à des stages et opportunités d'emploi.\n\nLes inscriptions sont ouvertes dès aujourd'hui. Contactez nos conseillers pour réserver votre place.''',
        author: 'Direction des Programmes GM',
        price: '150 \$ (Bourses disponibles)',
        imageUrl: 'assets/Wh.jpeg',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        publishedDate: DateTime.now().subtract(const Duration(days: 2)),
        isPublished: true,
        tags: ['Formation', 'Emploi', 'Jeunesse', 'Insertion'],
        viewsCount: 342,
        likesCount: 64,
        followersCount: 148,
        sharesCount: 29,
      ),
      Publication(
        id: 'pub_fondation_1',
        title: 'GM Fondation : Programme de Solidarité & Bourses d’Études 2026',
        category: 'Communiqué',
        department: 'GM Fondation',
        summary: 'La Fondation Great Minds lance son appel à projets pour soutenir l’éducation des jeunes vulnérables et l’entrepreneuriat social.',
        content: '''Fidèle à sa mission philanthropique « Construire l’excellence – Faire grandir le peu », GM Fondation déploie son plan d'action communautaire 2026.\n\nAxes d'intervention prioritaires :\n• Octroi de 50 bourses scolaires et universitaires complètes\n• Financement de micro-projets pour femmes entrepreneures\n• Ateliers gratuits d'initiation au numérique et aux métiers pratiques.\n\nRejoignez nos actions en tant que partenaire, bénévole ou donateur.''',
        author: 'Comité GM Fondation',
        price: 'Engagement Citoyen',
        imageUrl: 'assets/gm_fondation.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=3nQNiWdeH2Q',
        publishedDate: DateTime.now().subtract(const Duration(days: 3)),
        isPublished: true,
        tags: ['Fondation', 'Solidarité', 'Bourses', 'Éducation', 'Social'],
        viewsCount: 310,
        likesCount: 95,
        followersCount: 210,
        sharesCount: 50,
      ),
      Publication(
        id: 'pub_2',
        title: 'GM Texas : Simplification des démarches Visa et Titres de Voyage',
        category: 'Conseil',
        department: 'GM Texa',
        summary: 'Découvrez notre guide exclusif et notre service d’audit personnalisé pour optimiser vos dossiers de visa.',
        content: '''Préparer un voyage d'affaires, d'études ou de vacances nécessite une rigueur documentaire exemplaire.\n\nLe département GM Texa met à votre disposition un service d'accompagnement complet :\n1. Analyse préalable de l'éligibilité et audit des pièces justificatives\n2. Prise de rendez-vous et suivi des dossiers consulaires\n3. Conseils personnalisés pour maximiser les chances d'acceptation.\n\nPrenez contact avec nos experts pour un entretien préalable.''',
        author: 'Équipe GM Texa',
        price: '75 \$ (Audit & Montage)',
        imageUrl: 'assets/gm_texas.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=fJ9rUzIMcZQ',
        publishedDate: DateTime.now().subtract(const Duration(days: 6)),
        isPublished: true,
        tags: ['Voyage', 'Visa', 'Passeport', 'Accompagnement'],
        viewsCount: 215,
        likesCount: 42,
        followersCount: 96,
        sharesCount: 18,
      ),
      Publication(
        id: 'pub_3',
        title: 'GM Parfum : Arrivée de la Nouvelle Collection GM Parfum Prestige',
        category: 'Opportunité',
        department: 'GM Parfum',
        summary: 'Une gamme de fragrances haut de gamme sélectionnées pour l’élégance quotidienne et les grandes occasions.',
        content: '''GM Parfum a le plaisir de dévoiler sa nouvelle sélection exclusive de fragrances raffinées.\n\nDisponibles dès maintenant en coffrets cadeaux et formats personnalisés avec livraison rapide.\nCommandez directement via notre service WhatsApp dédié pour bénéficier des tarifs préférentiels de lancement.''',
        author: 'Département GM Parfum',
        price: '45 \$ (Flacon Signature)',
        imageUrl: 'assets/Imag.jpeg',
        publishedDate: DateTime.now().subtract(const Duration(days: 10)),
        isPublished: true,
        tags: ['Parfum', 'Prestige', 'Luxe', 'Catalogue'],
        viewsCount: 489,
        likesCount: 112,
        followersCount: 230,
        sharesCount: 54,
      ),
      Publication(
        id: 'pub_media_2',
        title: 'GM Media : Pack Couverture Événementielle & Shooting Commercial 4K',
        category: 'Opportunité',
        department: 'GM Media & Production',
        summary: 'Confiez la visibilité de vos événements d’entreprise, lancements et mariages à notre équipe de cadreurs et photographes experts.',
        content: '''Donnez une dimension cinématographique à vos événements d'entreprise, conférences, mariages et campagnes publicitaires avec les équipes GM Media & Production.\n\nLe pack comprend :\n• Équipe de 2 cadreurs 4K avec drones homologués\n• Prise de son studio et éclairage dynamique professionnel\n• Montage rapide sous 72h avec teaser optimisé pour les réseaux sociaux\n• Remise des fichiers bruts en haute définition sur clé sécurisée.''',
        author: 'Production GM Media',
        price: 'À partir de 250 \$',
        imageUrl: 'assets/Imag.jpeg',
        videoUrl: 'https://www.youtube.com/watch?v=LXb3EKWsInQ',
        publishedDate: DateTime.now().subtract(const Duration(days: 12)),
        isPublished: true,
        tags: ['Vidéo', 'Media', 'Shooting', '4K', 'Événement'],
        viewsCount: 395,
        likesCount: 77,
        followersCount: 160,
        sharesCount: 35,
      ),
      Publication(
        id: 'pub_4',
        title: 'Partenariat Stratégique avec les Acteurs Économiques Locaux',
        category: 'Communiqué',
        department: 'Toutes les activités',
        summary: 'Signature de conventions pour faciliter l’intégration directe de nos diplômés au sein des entreprises partenaires.',
        content: '''Dans le cadre de son plan de développement, GREAT MINDS GROUP a officialisé 5 nouveaux partenariats avec des leaders industriels et commerciaux.\n\nCes accords prévoient l'accueil régulier de nos stagiaires et l'ouverture de postes dédiés pour les profils qualifiés formés par GM GROUP.''',
        author: 'Direction Générale',
        price: 'Sur devis',
        imageUrl: 'assets/Wh.jpeg',
        publishedDate: DateTime.now().subtract(const Duration(days: 15)),
        isPublished: true,
        tags: ['Partenariats', 'Entreprises', 'Économie'],
        viewsCount: 178,
        likesCount: 35,
        followersCount: 84,
        sharesCount: 12,
      ),
    ];
  }

  List<Offer> _getDefaultOffers() {
    return [
      // --- GM PARFUM ---
      Offer(
        id: 'parfum_1',
        title: 'Coffret Prestige "Royal Oud & Ambre Intense"',
        department: 'GM Parfum',
        type: 'Promotion',
        location: 'Livraison express à Kinshasa & Provinces',
        salaryOrPrice: '65 \$ (Flacon 100ml + Miniature)',
        description: 'Une fragrance orientale d’exception aux notes boisées, ambrées et d’oud noble. Idéale pour les réceptions prestigieuses et soirées habillées. Tenue longue durée garantie 24h.',
        requirements: [
          'Flacon de luxe en verre taillé 100ml',
          'Miniature de voyage 15ml offerte',
          'Emballage cadeau signature GM Parfum inclus',
          'Paiement à la livraison possible à Kinshasa',
        ],
        deadline: DateTime.now().add(const Duration(days: 45)),
        publishedDate: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
        isUrgent: true,
      ),
      Offer(
        id: 'parfum_2',
        title: 'Eau de Parfum "Élégance Florale" (Pour Femme)',
        department: 'GM Parfum',
        type: 'Promotion',
        location: 'Kinshasa',
        salaryOrPrice: '45 \$ (Flacon 80ml)',
        description: 'Un bouquet floral raffiné alliant jasmin d’Arabie, rose de mai et fleur d’oranger avec un fond musqué poudré pour un sillage frais et envoûtant au quotidien.',
        requirements: [
          'Eau de parfum concentrée à 20%',
          'Convient à un usage quotidien ou professionnel',
          'Livraison sécurisée sous 24h',
        ],
        deadline: DateTime.now().add(const Duration(days: 60)),
        publishedDate: DateTime.now().subtract(const Duration(days: 3)),
        isActive: true,
        isUrgent: false,
      ),
      Offer(
        id: 'parfum_3',
        title: 'Pack Découverte : 5 Fragrances Exclusives GM',
        department: 'GM Parfum',
        type: 'Promotion',
        location: 'Kinshasa / RDC',
        salaryOrPrice: '25 \$ le coffret testeur',
        description: 'Explorez toute la collection GM Parfum avant de choisir votre fragrance favorite. Contient 5 vaporisateurs de 10ml (Oud, Floral, Boisé, Cuir, Fruité).',
        requirements: [
          '5 atomiseurs de poche rechargeables',
          'Bon de réduction de 10% inclus pour votre prochain achat',
          'Stock limité',
        ],
        deadline: DateTime.now().add(const Duration(days: 30)),
        publishedDate: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
        isUrgent: false,
      ),
      Offer(
        id: 'parfum_4',
        title: 'Coffrets Cadeaux Corporatifs & Événements',
        department: 'GM Parfum',
        type: 'Partenariat',
        location: 'Kinshasa / Commandes B2B',
        salaryOrPrice: 'Tarifs dégressifs dès 10 unités',
        description: 'Personnalisez vos cadeaux d’affaires pour entreprises, mariages, conférences ou fêtes de fin d’année avec les parfums et coffrets GM de haute facture.',
        requirements: [
          'Personnalisation avec logo ou message sur mesure',
          'Accompagnement commercial dédié',
          'Devis et échantillonnage sous 48h',
        ],
        deadline: DateTime.now().add(const Duration(days: 90)),
        publishedDate: DateTime.now().subtract(const Duration(days: 7)),
        isActive: true,
        isUrgent: false,
      ),

      // --- GM TEXA (VISA & PASSEPORT) ---
      Offer(
        id: 'texa_1',
        title: 'Pack Accompagnement Visa Études (Europe & Canada)',
        department: 'GM Texa',
        type: 'Service',
        location: 'Agence GM Texa Kinshasa / Suivi en ligne',
        salaryOrPrice: 'Forfait assistance intégrale',
        description: 'Un service clé en main pour étudiants et chercheurs : audit des relevés, garanties financières, conformité du dossier consulaire et simulation d’entretien.',
        requirements: [
          'Vérification exhaustive des pièces justificatives',
          'Assistance pour prise de rendez-vous consulaire',
          'Coaching individuel pour l’entretien de visa',
        ],
        deadline: DateTime.now().add(const Duration(days: 40)),
        publishedDate: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
        isUrgent: true,
      ),
      Offer(
        id: 'texa_2',
        title: 'Assistance Passeport & Titres de Séjour',
        department: 'GM Texa',
        type: 'Service',
        location: 'Kinshasa',
        salaryOrPrice: 'Devis clair et transparent',
        description: 'Accélérez et sécurisez vos démarches d’obtention ou de renouvellement de passeport avec un suivi rigoureux de chaque étape administrative.',
        requirements: [
          'Constitution préalable du dossier conforme',
          'Suivi de la procédure d’enregistrement biométrique',
          'Assistance directe sur WhatsApp',
        ],
        deadline: DateTime.now().add(const Duration(days: 60)),
        publishedDate: DateTime.now().subtract(const Duration(days: 4)),
        isActive: true,
        isUrgent: false,
      ),
      Offer(
        id: 'texa_3',
        title: 'Stage Professionnel en Administration & Logistique Voyage',
        department: 'GM Texa',
        type: 'Stage',
        location: 'Kinshasa (Gombe)',
        salaryOrPrice: 'Indemnité de stage mensuelle',
        description: 'Stage rémunéré de 3 à 6 mois pour assister les conseillers GM Texa dans le traitement documentaire et l’accueil des clients voyageurs.',
        requirements: [
          'Diplôme ou cursus en Droit, Relations Internationales ou Gestion',
          'Excellente maîtrise du français et sens de la discrétion',
          'Possibilité de recrutement en CDI à l’issue du stage',
        ],
        deadline: DateTime.now().add(const Duration(days: 15)),
        publishedDate: DateTime.now().subtract(const Duration(days: 3)),
        isActive: true,
        isUrgent: true,
      ),

      // --- GM AUTOSOLUTION ---
      Offer(
        id: 'auto_1',
        title: 'Packs Pneumatiques Neufs & Freinage Haute Sécurité',
        department: 'GM Autosolution',
        type: 'Promotion',
        location: 'Kinshasa / Atelier partenaire GM',
        salaryOrPrice: 'À partir de 65 \$ / pneu',
        description: 'Vente et montage de pneus neufs certifiés pour berlines, SUV et pick-up toutes marques (Michelin, Bridgestone, Goodyear, Dunlop). Disques et plaquettes disponibles.',
        requirements: [
          'Pneus neufs garantis contre les défauts de fabrication',
          'Équilibrage offert pour l’achat d’un train de 4 pneus',
          'Livraison possible sur site ou au garage de votre choix',
        ],
        deadline: DateTime.now().add(const Duration(days: 30)),
        publishedDate: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
        isUrgent: false,
      ),
      Offer(
        id: 'auto_2',
        title: 'Diagnostic Électronique Embarqué & Recharge Climatisation',
        department: 'GM Autosolution',
        type: 'Service',
        location: 'Kinshasa',
        salaryOrPrice: '35 \$ la séance de scan complet',
        description: 'Détection précise des anomalies moteur, transmission, ABS/Airbag à la valise OBD professionnelle avec rapport imprimé et conseils mécaniques.',
        requirements: [
          'Prise en charge de toutes marques européennes, asiatiques et américaines',
          'Technicien qualifié avec équipement de pointe',
          'Sur rendez-vous rapide via WhatsApp',
        ],
        deadline: DateTime.now().add(const Duration(days: 45)),
        publishedDate: DateTime.now().subtract(const Duration(days: 6)),
        isActive: true,
        isUrgent: false,
      ),
      Offer(
        id: 'auto_3',
        title: 'Commande Express de Pièces Mécaniques d’Origine',
        department: 'GM Autosolution',
        type: 'Service',
        location: 'Kinshasa / Import express',
        salaryOrPrice: 'Devis sous 24h avec garantie constructeur',
        description: 'Recherche et expédition rapide de pièces d’origine neuves ou révisées : amortisseurs, injecteurs, alternateurs, turbos, kits de distribution.',
        requirements: [
          'Transmettez votre carte grise ou numéro de châssis (VIN)',
          'Délai de livraison de 5 à 10 jours ouvrés',
          'Garantie de compatibilité totale',
        ],
        deadline: DateTime.now().add(const Duration(days: 60)),
        publishedDate: DateTime.now().subtract(const Duration(days: 8)),
        isActive: true,
        isUrgent: false,
      ),

      // --- GM FONDATION ---
      Offer(
        id: 'fondation_1',
        title: 'Bourses d’Études & Formation Pro pour 150 Jeunes',
        department: 'GM Fondation',
        type: 'Formation',
        location: 'Kinshasa / Centre GM Fondation',
        salaryOrPrice: '100% financé par GM Fondation',
        description: 'Programme d’insertion sociale offrant des formations qualifiantes intensives en technologies, gestion de projets et métiers d’artisanat.',
        requirements: [
          'Jeunes âgés de 18 à 30 ans résidant à Kinshasa',
          'Dossier de candidature simple : lettre de motivation et pièce d’identité',
          'Suivi et accompagnement vers un premier emploi',
        ],
        deadline: DateTime.now().add(const Duration(days: 25)),
        publishedDate: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
        isUrgent: true,
      ),
      Offer(
        id: 'fondation_2',
        title: 'Appel à Projets : Entrepreneuriat & Impact Communautaire',
        department: 'GM Fondation',
        type: 'Partenariat',
        location: 'Kinshasa / RDC',
        salaryOrPrice: 'Subvention jusqu’à 2 500 \$ + Mentorat',
        description: 'Soutien aux micro-entrepreneurs et porteurs de projets innovants dans l’agriculture, le recyclage, l’artisanat et les services numériques.',
        requirements: [
          'Projet avec un impact direct sur l’emploi des jeunes ou des femmes',
          'Sélection sur dossier puis pitch devant le jury GM',
          'Accompagnement managérial de 6 mois pour les lauréats',
        ],
        deadline: DateTime.now().add(const Duration(days: 45)),
        publishedDate: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
        isUrgent: false,
      ),

      // --- GM FORMATION & EMPLOI ---
      Offer(
        id: 'emploi_1',
        title: 'Conseiller(e) Commercial(e) B2B & Grands Comptes',
        department: 'GM Formation & Emploi',
        type: 'Emploi',
        location: 'Kinshasa (Gombe)',
        salaryOrPrice: 'Salaire fixe attractif + Commissions',
        description: 'Recrutement pour le compte d’un groupe partenaire : développement de portefeuille clients, prospection et fidélisation des comptes entreprises.',
        requirements: [
          'Niveau Bac+3 en Commerce, Marketing ou Gestion',
          'Minimum 2 ans d’expérience en vente B2B réussie',
          'Dynamisme, aisance relationnelle et rigueur',
        ],
        deadline: DateTime.now().add(const Duration(days: 18)),
        publishedDate: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
        isUrgent: true,
      ),
      Offer(
        id: 'emploi_2',
        title: 'Formation Certifiante : Excel Avancé, Gestion & Outils IA',
        department: 'GM Formation & Emploi',
        type: 'Formation',
        location: 'En présentiel (Kinshasa) & En ligne',
        salaryOrPrice: 'Session complète avec certification',
        description: 'Programme pratique de 4 semaines orienté business : automatisation des tableaux de bord, analyse de données et utilisation des outils d’IA pour décupler sa productivité.',
        requirements: [
          'Ouvert aux professionnels, étudiants et demandeurs d’emploi',
          'Supports de cours interactifs et exercices réels',
          'Horaires flexibles en soirée et week-ends',
        ],
        deadline: DateTime.now().add(const Duration(days: 20)),
        publishedDate: DateTime.now().subtract(const Duration(days: 4)),
        isActive: true,
        isUrgent: false,
      ),

      // --- GM MEDIA & PRODUCTION ---
      Offer(
        id: 'media_1',
        title: 'Production Audiovisuelle & Couverture d’Événements 4K',
        department: 'GM Media & Production',
        type: 'Service',
        location: 'Kinshasa / Déplacement possible',
        salaryOrPrice: 'Sur devis personnalisé',
        description: 'Réalisation complète de spots publicitaires, documentaires, captation multicaméras en direct et création de contenus vidéo professionnels pour entreprises et particuliers.',
        requirements: [
          'Équipe de tournage et matériel 4K / Haute Définition',
          'Montage, étalonnage et mixage sonore inclus',
          'Livraison rapide sur support numérique et réseaux sociaux',
        ],
        deadline: DateTime.now().add(const Duration(days: 90)),
        publishedDate: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
        isUrgent: true,
      ),
      Offer(
        id: 'media_2',
        title: 'Stratégie de Communication Digitale & Image de Marque 360°',
        department: 'GM Media & Production',
        type: 'Service',
        location: 'Kinshasa / Accompagnement à distance',
        salaryOrPrice: 'Forfaits mensuels sur mesure',
        description: 'Gestion de vos réseaux sociaux, création de visuels percutants, rédaction de contenus et déploiement de campagnes publicitaires sponsorisées pour booster votre visibilité.',
        requirements: [
          'Audit préalable de votre communication actuelle',
          'Calendrier éditorial et création de contenu régulier',
          'Rapports mensuels de performance et d’audience',
        ],
        deadline: DateTime.now().add(const Duration(days: 60)),
        publishedDate: DateTime.now().subtract(const Duration(days: 3)),
        isActive: true,
        isUrgent: false,
      ),
      Offer(
        id: 'media_3',
        title: 'Formation Pratique : Cadrage Vidéo, Montage & Storytelling',
        department: 'GM Media & Production',
        type: 'Formation',
        location: 'Studios GM Media Kinshasa',
        salaryOrPrice: 'Session intensive certifiante',
        description: 'Apprenez les bases et techniques avancées de la réalisation vidéo, du maniement caméra, de la prise de son et du montage sur Premiere Pro / DaVinci Resolve.',
        requirements: [
          'Accessible aux débutants et créateurs de contenu',
          'Pratique directe sur matériel professionnel en studio',
          'Attestation de formation et possibilité de stage interne',
        ],
        deadline: DateTime.now().add(const Duration(days: 30)),
        publishedDate: DateTime.now().subtract(const Duration(days: 4)),
        isActive: true,
        isUrgent: false,
      ),
    ];
  }

  // --- Static Activities list (univers) ---
  static List<BusinessActivity> get activities => [
    const BusinessActivity(
      id: 'parfum',
      title: 'GM Parfum',
      description: 'Une sélection raffinée de parfums disponibles sur commande en ligne.',
      imageAsset: 'assets/Imag.jpeg',
      fallbackIcon: Icons.local_florist_rounded,
      actionLabel: 'Passer commande',
      requestMessage: 'passer une commande de parfum',
      offerings: [
        DepartmentOffering(
          icon: Icons.spa_rounded,
          title: 'Parfums signature',
          description: 'Des fragrances sélectionnées pour offrir ou se démarquer.',
        ),
        DepartmentOffering(
          icon: Icons.card_giftcard_rounded,
          title: 'Coffrets cadeaux',
          description: 'Des compositions élégantes pour chaque occasion.',
        ),
        DepartmentOffering(
          icon: Icons.local_shipping_rounded,
          title: 'Commande accompagnée',
          description: 'Une prise de commande simple via WhatsApp.',
        ),
      ],
    ),
    const BusinessActivity(
      id: 'texa',
      title: 'GM Texa — Visa & Billets d’avions',
      description: 'Un accompagnement rigoureux pour préparer vos démarches de visa, passeport et réservation de billets d’avions.',
      imageAsset: 'assets/gm_texas.jpg',
      fallbackIcon: Icons.flight_takeoff_rounded,
      actionLabel: 'Faire une demande',
      requestMessage: 'obtenir un accompagnement pour visa, passeport et billets d’avions',
      offerings: [
        DepartmentOffering(
          icon: Icons.assignment_turned_in_rounded,
          title: 'Préparation du dossier',
          description: 'Liste personnalisée des pièces nécessaires à votre projet.',
        ),
        DepartmentOffering(
          icon: Icons.badge_rounded,
          title: 'Visa & passeport',
          description: 'Orientation pratique pour les démarches de voyage.',
        ),
        DepartmentOffering(
          icon: Icons.flight_rounded,
          title: 'Billets d’avions',
          description: 'Réservation de billets et optimisation de vos itinéraires.',
        ),
      ],
    ),
    const BusinessActivity(
      id: 'autosolution',
      title: 'GM Autosolution',
      description: 'Des solutions adaptées pour les véhicules, pièces et besoins automobiles.',
      imageAsset: 'assets/Image (2).jpeg',
      fallbackIcon: Icons.directions_car_filled_rounded,
      actionLabel: 'Demander un devis',
      requestMessage: 'obtenir un devis pour des pièces automobiles',
      offerings: [
        DepartmentOffering(
          icon: Icons.settings_rounded,
          title: 'Pièces automobiles',
          description: 'Recherche de pièces adaptées à votre véhicule.',
        ),
        DepartmentOffering(
          icon: Icons.car_repair_rounded,
          title: 'Conseil technique',
          description: 'Orientation vers une solution fiable selon votre besoin.',
        ),
        DepartmentOffering(
          icon: Icons.request_quote_rounded,
          title: 'Devis personnalisé',
          description: 'Une proposition claire avant toute commande.',
        ),
      ],
    ),
    const BusinessActivity(
      id: 'emploi',
      title: 'GM Formation & Emploi',
      description: 'Cabinet de recrutement, formations professionnelles certifiantes et accompagnement de carrière.',
      fallbackIcon: Icons.psychology_rounded,
      actionLabel: 'Découvrir les opportunités',
      requestMessage: 'obtenir des informations sur les formations et offres d’emploi de GM Formation & Emploi',
      offerings: [
        DepartmentOffering(
          icon: Icons.work_rounded,
          title: 'Recrutement & Placement',
          description: 'Mise en relation directe entre talents qualifiés et entreprises.',
        ),
        DepartmentOffering(
          icon: Icons.model_training_rounded,
          title: 'Formations Pro Certifiantes',
          description: 'Modules intensifs en bureautique avancée, IA, vente et management.',
        ),
        DepartmentOffering(
          icon: Icons.co_present_rounded,
          title: 'Coaching de Carrière',
          description: 'Optimisation de CV, simulation d’entretiens et stratégie d’évolution.',
        ),
      ],
    ),
    const BusinessActivity(
      id: 'fondation',
      title: 'GM Foundation Company LTD',
      description: 'Initiatives sociales, humanitaires, culturelles, éducatives et soutien aux personnes vulnérables et à la jeunesse.',
      imageAsset: 'assets/Wh.jpeg',
      fallbackIcon: Icons.volunteer_activism_rounded,
      actionLabel: 'Découvrir nos actions',
      requestMessage: 'en savoir plus sur les initiatives de GM Foundation Company LTD',
      offerings: [
        DepartmentOffering(
          icon: Icons.volunteer_activism_rounded,
          title: 'Solidarité & Communauté',
          description: 'Soutien direct aux personnes vulnérables et actions de solidarité citoyenne.',
        ),
        DepartmentOffering(
          icon: Icons.school_rounded,
          title: 'Bourses & Éducation',
          description: 'Des parcours de formation pris en charge pour développer des compétences utiles.',
        ),
        DepartmentOffering(
          icon: Icons.groups_rounded,
          title: 'Programmes Jeunesse',
          description: 'Des actions concrètes favorisant l’autonomie, la culture et l’insertion.',
        ),
      ],
    ),
    const BusinessActivity(
      id: 'media',
      title: 'GM Media & Production',
      description: 'Communication, création de contenus, production audiovisuelle, promotion de projets et valorisation des talents.',
      imageAsset: 'assets/gm_media.jpg',
      fallbackIcon: Icons.movie_filter_rounded,
      actionLabel: 'Nos Réalisations',
      requestMessage: 'collaborer avec GM Media & Production pour un projet audiovisuel ou de communication',
      offerings: [
        DepartmentOffering(
          icon: Icons.videocam_rounded,
          title: 'Production Audiovisuelle',
          description: 'Spots publicitaires, reportages institutionnels, podcasts et captation événementielle.',
        ),
        DepartmentOffering(
          icon: Icons.campaign_rounded,
          title: 'Stratégie de Communication',
          description: 'Création de contenus impactants, image de marque et campagnes digitales.',
        ),
        DepartmentOffering(
          icon: Icons.star_rounded,
          title: 'Valorisation des Talents',
          description: 'Mise en lumière des porteurs de projets, artistes, créateurs et jeunes innovateurs.',
        ),
      ],
    ),
  ];

  static BusinessActivity findActivityForDepartment(String departmentName) {
    final name = departmentName.toLowerCase().trim();
    for (final act in activities) {
      final actId = act.id.toLowerCase();
      final actTitle = act.title.toLowerCase();
      if (name == actId || name == actTitle || actTitle.contains(name) || name.contains(actTitle)) {
        return act;
      }
    }
    if (name.contains('parfum')) return activities.firstWhere((a) => a.id == 'parfum');
    if (name.contains('texa') || name.contains('visa') || name.contains('billet') || name.contains('passeport') || name.contains('voyage')) {
      return activities.firstWhere((a) => a.id == 'texa');
    }
    if (name.contains('auto') || name.contains('véhicule') || name.contains('vehicule') || name.contains('pièce') || name.contains('piece')) {
      return activities.firstWhere((a) => a.id == 'autosolution');
    }
    if (name.contains('media') || name.contains('médias') || name.contains('production') || name.contains('audiovisuel') || name.contains('contenu')) {
      return activities.firstWhere((a) => a.id == 'media');
    }
    if (name.contains('fondation') || name.contains('foundation') || name.contains('social') || name.contains('humanitaire')) {
      return activities.firstWhere((a) => a.id == 'fondation');
    }
    if (name.contains('emploi') || name.contains('formation') || name.contains('recrutement') || name.contains('stage') || name.contains('carrière') || name.contains('carriere')) {
      return activities.firstWhere((a) => a.id == 'emploi');
    }
    return activities.first;
  }
}
