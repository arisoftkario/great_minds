import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/publication_model.dart';
import '../models/offer_model.dart';
import '../models/activity_model.dart';
import '../models/subscriber_model.dart';
import '../models/admin_notification_model.dart';

class AppDataService extends ChangeNotifier {
  static final AppDataService _instance = AppDataService._internal();
  factory AppDataService() => _instance;
  AppDataService._internal();

  List<Publication> _publications = [];
  List<Offer> _offers = [];
  List<Subscriber> _subscribers = [];
  List<AdminNotification> _notifications = [];
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

      // Publications
      final pubJson = prefs.getString(_publicationsKey);
      if (pubJson != null && pubJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(pubJson);
        _publications = decoded.map((item) => Publication.fromJson(item)).toList();
      } else {
        _publications = _getDefaultPublications();
        await _savePublications();
      }

      // Offers
      final offerJson = prefs.getString(_offersKey);
      if (offerJson != null && offerJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(offerJson);
        _offers = decoded.map((item) => Offer.fromJson(item)).toList();
      } else {
        _offers = _getDefaultOffers();
        await _saveOffers();
      }

      // Subscribers
      final subJson = prefs.getString(_subscribersKey);
      if (subJson != null && subJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(subJson);
        _subscribers = decoded.map((item) => Subscriber.fromJson(item)).toList();
      } else {
        _subscribers = [];
      }

      // Notifications
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
    } catch (e) {
      debugPrint('Error loading AppDataService: $e');
      _publications = _getDefaultPublications();
      _offers = _getDefaultOffers();
      _subscribers = [];
      _notifications = [];
      _isInitialized = true;
      _lastSyncTime = DateTime.now();
      startAutoSync(); // Lance l'auto-synchronisation automatique toutes les 10 secondes
      notifyListeners();
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
  Future<void> syncData({bool silent = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    if (!silent) {
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      // WhatsApp Number
      final newWhatsApp = prefs.getString(_whatsAppKey) ?? AppConstants.whatsAppNumber;

      // Publications
      List<Publication> newPublications = _publications;
      final pubJson = prefs.getString(_publicationsKey);
      if (pubJson != null && pubJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(pubJson);
        newPublications = decoded.map((item) => Publication.fromJson(item)).toList();
      }

      // Offers
      List<Offer> newOffers = _offers;
      final offerJson = prefs.getString(_offersKey);
      if (offerJson != null && offerJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(offerJson);
        newOffers = decoded.map((item) => Offer.fromJson(item)).toList();
      }

      // Subscribers
      List<Subscriber> newSubscribers = _subscribers;
      final subJson = prefs.getString(_subscribersKey);
      if (subJson != null && subJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(subJson);
        newSubscribers = decoded.map((item) => Subscriber.fromJson(item)).toList();
      }

      // Notifications
      List<AdminNotification> newNotifications = _notifications;
      final notifJson = prefs.getString(_notificationsKey);
      if (notifJson != null && notifJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(notifJson);
        newNotifications = decoded.map((item) => AdminNotification.fromJson(item)).toList();
      }

      _whatsAppNumber = newWhatsApp;
      _publications = newPublications;
      _offers = newOffers;
      _subscribers = newSubscribers;
      _notifications = newNotifications;

      // Sauvegarde explicite pour persistance maximale
      await _savePublications();
      await _saveOffers();
      await _saveSubscribers();
      await _saveNotifications();

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

  Future<void> _saveSubscribers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_subscribers.map((s) => s.toJson()).toList());
      await prefs.setString(_subscribersKey, encoded);
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
  Future<void> _savePublications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_publications.map((p) => p.toJson()).toList());
      await prefs.setString(_publicationsKey, encoded);
    } catch (e) {
      debugPrint('Error saving publications: $e');
    }
  }

  Future<void> _saveOffers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_offers.map((o) => o.toJson()).toList());
      await prefs.setString(_offersKey, encoded);
    } catch (e) {
      debugPrint('Error saving offers: $e');
    }
  }

  // --- Preloaded Initial Professional Data ---
  List<Publication> _getDefaultPublications() {
    return [
      Publication(
        id: 'pub_1',
        title: 'Lancement du Programme d’Accélération Professionnelle 2026',
        category: 'Actualité',
        department: 'GM Formation & Emploi',
        summary: 'GREAT MINDS GROUP ouvre les candidatures pour son nouveau cycle intensif de formation et de placement pour 150 jeunes.',
        content: '''GREAT MINDS GROUP franchit une nouvelle étape dans son engagement pour l'employabilité des jeunes talents.\n\nCe programme intensif de 3 mois combine :\n• Des modules pratiques en compétences clés et leadership professionnel\n• Du coaching individuel avec des mentors issus du monde de l'entreprise\n• Un accompagnement sur-mesure pour l'accès à des stages et opportunités d'emploi.\n\nLes inscriptions sont ouvertes dès aujourd'hui. Contactez nos conseillers pour réserver votre place.''',
        author: 'Direction des Programmes GM',
        imageUrl: 'assets/Wh.jpeg',
        publishedDate: DateTime.now().subtract(const Duration(days: 2)),
        isPublished: true,
        tags: ['Formation', 'Emploi', 'Jeunesse', 'Insertion'],
        viewsCount: 342,
        likesCount: 64,
        followersCount: 148,
      ),
      Publication(
        id: 'pub_2',
        title: 'GM Texa : Simplification des démarches Visa et Titres de Voyage',
        category: 'Conseil',
        department: 'GM Texa',
        summary: 'Découvrez notre guide exclusif et notre service d’audit personnalisé pour optimiser vos dossiers de visa.',
        content: '''Préparer un voyage d'affaires, d'études ou de vacances nécessite une rigueur documentaire exemplaire.\n\nLe département GM Texa met à votre disposition un service d'accompagnement complet :\n1. Analyse préalable de l'éligibilité et audit des pièces justificatives\n2. Prise de rendez-vous et suivi des dossiers consulaires\n3. Conseils personnalisés pour maximiser les chances d'acceptation.\n\nPrenez contact avec nos experts pour un entretien préalable.''',
        author: 'Équipe GM Texa',
        imageUrl: 'assets/gm_texas.jpg',
        publishedDate: DateTime.now().subtract(const Duration(days: 6)),
        isPublished: true,
        tags: ['Voyage', 'Visa', 'Passeport', 'Accompagnement'],
        viewsCount: 215,
        likesCount: 42,
        followersCount: 96,
      ),
      Publication(
        id: 'pub_3',
        title: 'Arrivée de la Nouvelle Collection GM Parfum Prestige',
        category: 'Opportunité',
        department: 'GM Parfum',
        summary: 'Une gamme de fragrances haut de gamme sélectionnées pour l’élégance quotidienne et les grandes occasions.',
        content: '''GM Parfum a le plaisir de dévoiler sa nouvelle sélection exclusive de fragrances raffinées.\n\nDisponibles dès maintenant en coffrets cadeaux et formats personnalisés avec livraison rapide.\nCommandez directement via notre service WhatsApp dédié pour bénéficier des tarifs préférentiels de lancement.''',
        author: 'Département GM Parfum',
        imageUrl: 'assets/Imag.jpeg',
        publishedDate: DateTime.now().subtract(const Duration(days: 10)),
        isPublished: true,
        tags: ['Parfum', 'Prestige', 'Luxe', 'Catalogue'],
        viewsCount: 489,
        likesCount: 112,
        followersCount: 230,
      ),
      Publication(
        id: 'pub_4',
        title: 'Partenariat Stratégique avec les Acteurs Économiques Locaux',
        category: 'Communiqué',
        department: 'Toutes les activités',
        summary: 'Signature de conventions pour faciliter l’intégration directe de nos diplômés au sein des entreprises partenaires.',
        content: '''Dans le cadre de son plan de développement, GREAT MINDS GROUP a officialisé 5 nouveaux partenariats avec des leaders industriels et commerciaux.\n\nCes accords prévoient l'accueil régulier de nos stagiaires et l'ouverture de postes dédiés pour les profils qualifiés formés par GM GROUP.''',
        author: 'Direction Générale',
        publishedDate: DateTime.now().subtract(const Duration(days: 15)),
        isPublished: true,
        tags: ['Partenariats', 'Entreprises', 'Économie'],
        viewsCount: 178,
        likesCount: 35,
        followersCount: 84,
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
      title: 'GM Fondation',
      description: 'Des opérations d’accompagnement, de formation et d’insertion pour les jeunes.',
      imageAsset: 'assets/Wh.jpeg',
      fallbackIcon: Icons.volunteer_activism_rounded,
      actionLabel: 'Nous rejoindre',
      requestMessage: 'en savoir plus sur les opérations de GM Fondation',
      offerings: [
        DepartmentOffering(
          icon: Icons.volunteer_activism_rounded,
          title: 'Orientation emploi',
          description: 'Des repères pratiques pour avancer vers l’emploi.',
        ),
        DepartmentOffering(
          icon: Icons.school_rounded,
          title: 'Bourses & Formations',
          description: 'Des parcours 100% pris en charge pour développer des compétences utiles.',
        ),
        DepartmentOffering(
          icon: Icons.groups_rounded,
          title: 'Programmes jeunesse',
          description: 'Des actions concrètes favorisant l’autonomie et l’insertion.',
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
    if (name.contains('emploi') || name.contains('formation') || name.contains('recrutement') || name.contains('stage') || name.contains('carrière') || name.contains('carriere')) {
      return activities.firstWhere((a) => a.id == 'emploi');
    }
    if (name.contains('fondation') || name.contains('jeune') || name.contains('social') || name.contains('bourse')) {
      return activities.firstWhere((a) => a.id == 'fondation');
    }
    return activities.first;
  }
}
