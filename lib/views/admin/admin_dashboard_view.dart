import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/admin_user_model.dart';
import '../../models/offer_model.dart';
import '../../models/order_model.dart';
import '../../models/publication_model.dart';
import '../../services/admin_users_service.dart';
import '../../services/api_client.dart';
import '../../services/app_data_service.dart';
import '../../services/auth_service.dart';
import 'admin_user_form_dialog.dart';
import 'offer_form_dialog.dart';
import 'publication_form_dialog.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedTabIndex = 0; // 0: Overview, 1: Publications, 2: Offers, 3: Orders, 4: Notifications, 5: Subscribers, 6: Settings
  final TextEditingController _searchPubController = TextEditingController();
  final TextEditingController _searchOfferController = TextEditingController();
  final TextEditingController _searchSubscriberController = TextEditingController();
  final TextEditingController _searchOrderController = TextEditingController();

  String _filterPubCategory = 'Tous';
  String _filterPubDept = 'Tous';
  String _filterOfferDept = 'Tous';
  String _filterOfferType = 'Tous';
  String _filterOrderStatus = 'Tous';
  bool _isSyncing = false;

  // Gestion utilisateurs (Paramètres)
  List<AdminUser> _adminUsers = [];
  bool _usersLoading = false;
  String? _usersError;
  bool _usersLoadedOnce = false;

  Future<void> _syncAllData() async {
    setState(() => _isSyncing = true);
    await AppDataService().syncData();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isSyncing = false);
      _showToast('✓ Données et contenus synchronisés avec succès sur le site !');
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureTabAllowed();
  }

  @override
  void dispose() {
    _searchPubController.dispose();
    _searchOfferController.dispose();
    _searchSubscriberController.dispose();
    _searchOrderController.dispose();
    super.dispose();
  }

  AdminModule _moduleForTab(int index) {
    switch (index) {
      case 0:
        return AdminModule.overview;
      case 1:
        return AdminModule.publications;
      case 2:
        return AdminModule.offers;
      case 3:
        return AdminModule.orders;
      case 4:
        return AdminModule.notifications;
      case 5:
        return AdminModule.subscribers;
      case 6:
        return AdminModule.settings;
      default:
        return AdminModule.overview;
    }
  }

  void _ensureTabAllowed() {
    if (!AuthService().canAccess(_moduleForTab(_selectedTabIndex))) {
      _selectedTabIndex = 0;
    }
  }

  Future<void> _loadAdminUsers({bool force = false}) async {
    if (!AuthService().canManageUsers) return;
    if (_usersLoading) return;
    if (_usersLoadedOnce && !force) return;

    setState(() {
      _usersLoading = true;
      _usersError = null;
    });

    try {
      final users = await AdminUsersService().listUsers();
      if (!mounted) return;
      setState(() {
        _adminUsers = users;
        _usersLoading = false;
        _usersLoadedOnce = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _usersLoading = false;
        _usersError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _usersLoading = false;
        _usersError = 'Impossible de charger les utilisateurs.';
      });
    }
  }

  Future<void> _openUserForm([AdminUser? user]) async {
    final auth = AuthService();
    if (user != null && !auth.isSuperAdmin && user.role != AdminRole.agent) {
      _showToast('Vous ne pouvez modifier que les comptes Agent.');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AdminUserFormDialog(user: user),
    );
    if (result == null || !mounted) return;

    try {
      if (user == null) {
        await AdminUsersService().createUser(
          email: result['email'] as String,
          fullName: result['full_name'] as String,
          password: result['password'] as String,
          role: result['role'] as AdminRole,
          status: result['status'] as AdminUserStatus,
        );
        _showToast('Utilisateur créé avec succès.');
      } else {
        await AdminUsersService().updateUser(
          userId: user.id,
          email: result['email'] as String,
          fullName: result['full_name'] as String,
          password: (result['password'] as String?)?.isNotEmpty == true
              ? result['password'] as String
              : null,
          role: result['role'] as AdminRole,
          status: result['status'] as AdminUserStatus,
        );
        _showToast('Utilisateur mis à jour.');
      }
      await _loadAdminUsers(force: true);
    } on ApiException catch (e) {
      _showToast(e.message);
    } catch (_) {
      _showToast('Une erreur est survenue.');
    }
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    final next = user.status == AdminUserStatus.active
        ? AdminUserStatus.suspended
        : AdminUserStatus.active;
    try {
      await AdminUsersService().setStatus(user.id, next);
      _showToast(next == AdminUserStatus.suspended
          ? 'Compte suspendu.'
          : 'Compte réactivé.');
      await _loadAdminUsers(force: true);
    } on ApiException catch (e) {
      _showToast(e.message);
    }
  }

  Future<void> _confirmDeleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l’utilisateur'),
        content: Text('Supprimer définitivement « ${user.fullName} » (${user.email}) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminUsersService().deleteUser(user.id);
      _showToast('Utilisateur supprimé.');
      await _loadAdminUsers(force: true);
    } on ApiException catch (e) {
      _showToast(e.message);
    }
  }

  Color _roleBadgeColor(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return const Color(0xFFE5A93C);
      case AdminRole.admin:
        return AppTheme.accentBlue;
      case AdminRole.agent:
        return const Color(0xFF10B981);
    }
  }

  void _openPublicationDialog([Publication? pub]) async {
    final result = await showDialog<Publication>(
      context: context,
      builder: (context) => PublicationFormDialog(publication: pub),
    );

    if (result != null) {
      final service = AppDataService();
      if (pub == null) {
        await service.addPublication(result);
        _showToast('Publication créée avec succès !');
      } else {
        await service.updatePublication(result);
        _showToast('Publication mise à jour !');
      }
    }
  }

  void _confirmDeletePublication(Publication pub) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la publication "${pub.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppDataService().deletePublication(pub.id);
              _showToast('Publication supprimée.');
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _openOfferDialog([Offer? offer]) async {
    final result = await showDialog<Offer>(
      context: context,
      builder: (context) => OfferFormDialog(offer: offer),
    );

    if (result != null) {
      final service = AppDataService();
      if (offer == null) {
        await service.addOffer(result);
        _showToast('Offre créée avec succès !');
      } else {
        await service.updateOffer(result);
        _showToast('Offre mise à jour !');
      }
    }
  }

  void _confirmDeleteOffer(Offer offer) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer l’offre "${offer.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppDataService().deleteOffer(offer.id);
              _showToast('Offre supprimée.');
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _openExportPublicationsDialog() {
    final jsonStr = AppDataService().exportPublicationsToJson();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppTheme.accentBlue),
            SizedBox(width: 8),
            Text('Exporter le Catalogue (JSON)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ce code JSON contient toutes vos publications et publicités. Vous pouvez le copier pour le transférer ou l\'importer sur un autre appareil :',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF071A2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF59D6B6)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(context).pop();
              _showToast('✓ Code du catalogue copié dans le presse-papier !');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copier le JSON'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCyan, foregroundColor: AppTheme.primaryNavy),
          ),
        ],
      ),
    );
  }

  void _openImportPublicationsDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_rounded, color: AppTheme.accentCyan),
            SizedBox(width: 8),
            Text('Importer des Publications (JSON)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collez ici le code JSON exporté depuis votre ordinateur pour charger toutes les publications sur ce téléphone / appareil :',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: '[ { "id": "pub_1", "title": "...", ... } ]',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final count = await AppDataService().importPublicationsFromJson(text);
              if (context.mounted) {
                Navigator.of(context).pop();
                _showToast('✓ $count publications importées et synchronisées !');
              }
            },
            icon: const Icon(Icons.file_download_done_rounded, size: 16),
            label: const Text('Importer & Activer'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentBlue),
          ),
        ],
      ),
    );
  }

  void _openExportOffersDialog() {
    final jsonStr = AppDataService().exportOffersToJson();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppTheme.accentBlue),
            SizedBox(width: 8),
            Text('Exporter les Offres (JSON)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ce code JSON contient toutes vos offres et opportunités :',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF071A2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF59D6B6)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(context).pop();
              _showToast('✓ Code des offres copié !');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copier'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCyan, foregroundColor: AppTheme.primaryNavy),
          ),
        ],
      ),
    );
  }

  void _openImportOffersDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_rounded, color: AppTheme.accentCyan),
            SizedBox(width: 8),
            Text('Importer des Offres (JSON)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collez ici le code JSON des offres à importer :',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: '[ { "id": "offer_1", "title": "...", ... } ]',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final count = await AppDataService().importOffersFromJson(text);
              if (context.mounted) {
                Navigator.of(context).pop();
                _showToast('✓ $count offres importées avec succès !');
              }
            },
            icon: const Icon(Icons.file_download_done_rounded, size: 16),
            label: const Text('Importer'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentBlue),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryNavy,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = AppDataService();
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Row(
            children: [
              // Sidebar
              if (isDesktop) _buildSidebar(),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isDesktop),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1300),
                          child: _buildCurrentTab(dataService),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          drawer: isDesktop ? null : Drawer(child: _buildSidebar(isDrawer: true)),
        );
      },
    );
  }

  // --- Top Navigation Bar ---
  Widget _buildTopBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTabTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Text(
                'Plateforme d’administration GREAT MINDS GROUP',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          // Bouton Synchroniser les mises à jour (Auto-synchro 10s active)
          FilledButton.icon(
            onPressed: _isSyncing ? null : _syncAllData,
            icon: _isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF061A2E)),
                  )
                : const Icon(Icons.sync_rounded, size: 18),
            label: Text(
              _isSyncing
                  ? 'Synchronisation...'
                  : (isDesktop ? 'Synchroniser (Auto 10s actif)' : 'Sync (Auto 10s)'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF59D6B6),
              foregroundColor: const Color(0xFF061A2E),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Voir le site web'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.15),
            child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentBlue, size: 20),
          ),
        ],
      ),
    );
  }

  String _getTabTitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Gestion des Publications';
      case 2:
        return 'Gestion des Offres & Opportunités';
      case 3:
        return 'Commandes & Ventes en ligne';
      case 4:
        return 'Centre de Notifications & Interactions';
      case 5:
        return 'Gestion des Abonnés & Communauté';
      case 6:
        return 'Paramètres & Configuration';
      default:
        return 'Administration';
    }
  }

  // --- Sidebar ---
  Widget _buildSidebar({bool isDrawer = false}) {
    final auth = AuthService();
    final unreadCount = AppDataService().unreadNotificationsCount;
    final totalSubscribers = AppDataService().subscribers.length;
    final pendingOrdersCount = AppDataService().orders.where((o) => o.status == 'En attente').length;

    return Container(
      width: 260,
      color: AppTheme.primaryNavy,
      child: Column(
        children: [
          // Logo GM Group
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.business_center_rounded, color: AppTheme.primaryNavy, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GREAT MINDS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      'ADMIN PORTAL',
                      style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF163B5D), height: 1),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                if (auth.canAccess(AdminModule.overview))
                  _sidebarItem(0, Icons.dashboard_rounded, 'Vue d’ensemble'),
                if (auth.canAccess(AdminModule.publications))
                  _sidebarItem(1, Icons.article_rounded, 'Publications & Actus'),
                if (auth.canAccess(AdminModule.offers))
                  _sidebarItem(2, Icons.work_outline_rounded, 'Offres & Emploi'),
                if (auth.canAccess(AdminModule.orders))
                  _sidebarItem(
                    3,
                    Icons.shopping_bag_rounded,
                    'Commandes & Ventes',
                    badgeCount: pendingOrdersCount,
                    badgeColor: const Color(0xFFF59E0B),
                  ),
                if (auth.canAccess(AdminModule.notifications))
                  _sidebarItem(
                    4,
                    Icons.notifications_active_rounded,
                    'Notifications & Likes',
                    badgeCount: unreadCount,
                  ),
                if (auth.canAccess(AdminModule.subscribers))
                  _sidebarItem(
                    5,
                    Icons.people_alt_rounded,
                    'Abonnés & Newsletter',
                    badgeCount: totalSubscribers,
                    badgeColor: const Color(0xFF10B981),
                  ),
                if (auth.canAccess(AdminModule.settings))
                  _sidebarItem(6, Icons.settings_rounded, 'Paramètres'),
              ],
            ),
          ),

          // User info & Logout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF163B5D))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF153F66),
                      child: Icon(Icons.person, color: AppTheme.accentCyan, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUsername.isEmpty
                                ? 'Administrateur'
                                : auth.currentUsername,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.currentRole.label,
                            style: const TextStyle(color: Color(0xFF7CA0C2), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().logout();
                      if (mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFFF8A80)),
                    label: const Text('Déconnexion', style: TextStyle(color: Color(0xFFFF8A80), fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    int index,
    IconData icon,
    String title, {
    int badgeCount = 0,
    Color badgeColor = const Color(0xFFEF4444),
  }) {
    final isSelected = _selectedTabIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? AppTheme.accentBlue : Colors.transparent,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF8BAFCF), size: 20),
            if (badgeCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFD3E4F4),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () {
          if (!AuthService().canAccess(_moduleForTab(index))) {
            _showToast('Accès non autorisé pour votre rôle.');
            return;
          }
          setState(() => _selectedTabIndex = index);
          if (index == 6) {
            _loadAdminUsers();
          }
          if (Navigator.of(context).canPop() && MediaQuery.sizeOf(context).width < 900) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  // --- Current Tab Router ---
  Widget _buildCurrentTab(AppDataService service) {
    _ensureTabAllowed();
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(service);
      case 1:
        return _buildPublicationsTab(service);
      case 2:
        return _buildOffersTab(service);
      case 3:
        return _buildOrdersTab(service);
      case 4:
        return _buildNotificationsTab(service);
      case 5:
        return _buildSubscribersTab(service);
      case 6:
        return _buildSettingsTab(service);
      default:
        return _buildOverviewTab(service);
    }
  }

  // ==========================================
  // TAB 0: VUE D'ENSEMBLE (OVERVIEW)
  // ==========================================
  Widget _buildOverviewTab(AppDataService service) {
    final totalPubs = service.publications.length;
    final publishedPubs = service.publishedPublications.length;
    final totalOffers = service.offers.length;
    final activeOffers = service.activeOffers.length;
    final urgentOffers = service.offers.where((o) => o.isUrgent && o.isActive).length;
    final totalOrders = service.orders.length;
    final pendingOrders = service.orders.where((o) => o.status == 'En attente').length;
    final totalViews = service.publications.fold<int>(0, (sum, p) => sum + p.viewsCount);
    final totalLikes = service.publications.fold<int>(0, (sum, p) => sum + p.likesCount);
    final totalSubscribers = service.subscribers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 600
                ? double.infinity
                : (constraints.maxWidth - 36) / (constraints.maxWidth < 1100 ? 2 : 3);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    'Publications en ligne',
                    '$publishedPubs / $totalPubs',
                    Icons.article_rounded,
                    AppTheme.accentBlue,
                    'Actives sur le site',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    'Commandes Clients',
                    '$totalOrders ($pendingOrders en attente)',
                    Icons.shopping_bag_rounded,
                    const Color(0xFFF59E0B),
                    'Bouton "Se procurer"',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    'Offres Actives',
                    '$activeOffers / $totalOffers',
                    Icons.work_outline_rounded,
                    AppTheme.accentCyan,
                    'Disponibles aux candidats',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    'Total Abonnés',
                    '$totalSubscribers',
                    Icons.people_alt_rounded,
                    const Color(0xFF10B981),
                    'Newsletter & Communauté',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    'Likes visiteurs',
                    '$totalLikes',
                    Icons.thumb_up_alt_rounded,
                    const Color(0xFFE11D48),
                    'Interactions enregistrées',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    'Lectures cumulées',
                    '$totalViews',
                    Icons.remove_red_eye_rounded,
                    const Color(0xFF8E44AD),
                    'Impact publications',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    'Offres Urgentes',
                    '$urgentOffers',
                    Icons.flash_on_rounded,
                    AppTheme.warningOrange,
                    'Priorité recrutement',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),

        // Quick Actions Banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF061A2E), Color(0xFF133F67)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF22527E)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Actions Rapides de Publication',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Créez et diffusez instantanément vos annonces, actualités et offres pour le public.',
                      style: TextStyle(color: Color(0xFFC0DAF2), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _openPublicationDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nouvelle Publication'),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCyan, foregroundColor: AppTheme.primaryNavy),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openOfferDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Créer une Offre'),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.accentBlue, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Two Column preview: Recent Publications & Recent Offers
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;
            return isCompact
                ? Column(
                    children: [
                      _recentPublicationsWidget(service),
                      const SizedBox(height: 24),
                      _recentOffersWidget(service),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _recentPublicationsWidget(service)),
                      const SizedBox(width: 24),
                      Expanded(child: _recentOffersWidget(service)),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(sub, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _recentPublicationsWidget(AppDataService service) {
    final recent = service.publications.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Dernières Publications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selectedTabIndex = 1),
                child: const Text('Tout voir'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune publication pour le moment.', style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            ...recent.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p.category, style: const TextStyle(color: AppTheme.accentBlue, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                      onPressed: () => _openPublicationDialog(p),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recentOffersWidget(AppDataService service) {
    final recent = service.offers.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Dernières Offres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selectedTabIndex = 2),
                child: const Text('Tout voir'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune offre pour le moment.', style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            ...recent.map(
              (o) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (o.isActive ? AppTheme.accentCyan : AppTheme.errorRed).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        o.type,
                        style: TextStyle(
                          color: o.isActive ? const Color(0xFF0C5645) : AppTheme.errorRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(o.department, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                      onPressed: () => _openOfferDialog(o),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: GESTION DES PUBLICATIONS (CMS)
  // ==========================================
  Widget _buildPublicationsTab(AppDataService service) {
    final query = _searchPubController.text.trim().toLowerCase();
    final pubs = service.publications.where((p) {
      final matchesSearch = query.isEmpty ||
          p.title.toLowerCase().contains(query) ||
          p.summary.toLowerCase().contains(query) ||
          p.author.toLowerCase().contains(query);
      final matchesCat = _filterPubCategory == 'Tous' || p.category == _filterPubCategory;
      final matchesDept = _filterPubDept == 'Tous' || p.department == _filterPubDept;
      return matchesSearch && matchesCat && matchesDept;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls Row
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchPubController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une publication par titre, contenu ou auteur...',
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    onPressed: () => _openPublicationDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Publier un article'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openExportPublicationsDialog,
                    icon: const Icon(Icons.cloud_download_rounded, size: 16),
                    label: const Text('Exporter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openImportPublicationsDialog,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: const Text('Importer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Department / Activity Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Activité : ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 8),
                    ...['Tous', 'Toutes les activités', 'GM Formation & Emploi', 'GM Parfum', 'GM Texa', 'GM Autosolution', 'GM Media & Production', 'GM Fondation'].map(
                      (dept) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: _filterPubDept == dept,
                          label: Text(dept),
                          selectedColor: AppTheme.accentCyan.withValues(alpha: 0.25),
                          onSelected: (val) => setState(() => _filterPubDept = dept),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Category Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Catégorie : ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 8),
                    ...['Tous', 'Actualité', 'Événement', 'Opportunité', 'Conseil', 'Success Story', 'Communiqué'].map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: _filterPubCategory == cat,
                          label: Text(cat),
                          selectedColor: AppTheme.accentBlue.withValues(alpha: 0.15),
                          onSelected: (val) => setState(() => _filterPubCategory = cat),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Publications List
        if (pubs.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Column(
              children: [
                Icon(Icons.article_outlined, size: 48, color: AppTheme.textSecondary),
                SizedBox(height: 12),
                Text('Aucune publication trouvée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                SizedBox(height: 6),
                Text('Modifiez vos critères ou cliquez sur "Publier un article".', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          )
        else
          ...pubs.map((p) => _buildPublicationItem(p)),
      ],
    );
  }

  Widget _buildPublicationItem(Publication p) {
    final dateFormatted = DateFormat('dd MMMM yyyy', 'fr_FR').format(p.publishedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_center_rounded, size: 13, color: Color(0xFF0C5645)),
                    const SizedBox(width: 4),
                    Text(
                      p.department,
                      style: const TextStyle(color: Color(0xFF0C5645), fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.category,
                  style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (p.isPublished ? AppTheme.successGreen : AppTheme.warningOrange).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.isPublished ? 'En ligne' : 'Brouillon',
                  style: TextStyle(
                    color: p.isPublished ? AppTheme.successGreen : AppTheme.warningOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(dateFormatted, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppTheme.accentBlue, size: 20),
                tooltip: 'Modifier',
                onPressed: () => _openPublicationDialog(p),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 20),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDeletePublication(p),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            p.summary,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(p.author, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('${p.viewsCount} vues', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, size: 15, color: Color(0xFFE53935)),
                  const SizedBox(width: 6),
                  Text('${p.likesCount} j\'aimes', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF00897B)),
                  const SizedBox(width: 6),
                  Text('${p.followersCount} abonnés', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.share_rounded, size: 15, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text('${p.sharesCount} partages', style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w700)),
                ],
              ),
              if (p.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: p.tags.map((t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 10, color: Color(0xFF1E3A5A))),
                    backgroundColor: const Color(0xFFE8F1FA),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: GESTION DES OFFRES & OPPORTUNITÉS
  // ==========================================
  Widget _buildOffersTab(AppDataService service) {
    final query = _searchOfferController.text.trim().toLowerCase();
    final offers = service.offers.where((o) {
      final matchesSearch = query.isEmpty ||
          o.title.toLowerCase().contains(query) ||
          o.description.toLowerCase().contains(query) ||
          o.location.toLowerCase().contains(query);
      final matchesDept = _filterOfferDept == 'Tous' || o.department == _filterOfferDept;
      final matchesType = _filterOfferType == 'Tous' || o.type == _filterOfferType;
      return matchesSearch && matchesDept && matchesType;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls Row
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchOfferController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une offre, un poste, un stage, une promotion...',
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    onPressed: () => _openOfferDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Créer une Offre'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openExportOffersDialog,
                    icon: const Icon(Icons.cloud_download_rounded, size: 16),
                    label: const Text('Exporter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openImportOffersDialog,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: const Text('Importer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Department Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Département : ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 6),
                    ...['Tous', 'GM Formation & Emploi', 'GM Parfum', 'GM Texa', 'GM Autosolution', 'GM Media & Production', 'GM Fondation'].map(
                      (dept) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: _filterOfferDept == dept,
                          label: Text(dept),
                          selectedColor: AppTheme.accentCyan.withValues(alpha: 0.2),
                          onSelected: (val) => setState(() => _filterOfferDept = dept),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Type Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Type d’offre : ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 6),
                    ...['Tous', 'Emploi', 'Stage', 'Formation', 'Promotion', 'Partenariat', 'Service'].map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: _filterOfferType == t,
                          label: Text(t),
                          selectedColor: AppTheme.accentBlue.withValues(alpha: 0.15),
                          onSelected: (val) => setState(() => _filterOfferType = t),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Offers List
        if (offers.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Column(
              children: [
                Icon(Icons.work_off_outlined, size: 48, color: AppTheme.textSecondary),
                SizedBox(height: 12),
                Text('Aucune offre trouvée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                SizedBox(height: 6),
                Text('Créez une nouvelle offre pour commencer.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          )
        else
          ...offers.map((o) => _buildOfferItem(o, service)),
      ],
    );
  }

  Widget _buildOfferItem(Offer o, AppDataService service) {
    final deadlineStr = DateFormat('dd/MM/yyyy').format(o.deadline);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: o.isUrgent ? AppTheme.warningOrange.withValues(alpha: 0.5) : AppTheme.borderSubtle),
        boxShadow: o.isUrgent ? [BoxShadow(color: AppTheme.warningOrange.withValues(alpha: 0.08), blurRadius: 10)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(o.department, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(o.type, style: const TextStyle(color: Color(0xFF0A4F40), fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              if (o.isUrgent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Urgent', style: TextStyle(color: Color(0xFFC05600), fontWeight: FontWeight.w800, fontSize: 11)),
                ),
              ],
              const Spacer(),
              // Active toggle
              Row(
                children: [
                  Text(o.isActive ? 'Active' : 'Désactivée', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: o.isActive ? AppTheme.successGreen : AppTheme.errorRed)),
                  Switch(
                    value: o.isActive,
                    activeThumbColor: AppTheme.successGreen,
                    onChanged: (_) => service.toggleOfferStatus(o.id),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppTheme.accentBlue, size: 20),
                tooltip: 'Modifier',
                onPressed: () => _openOfferDialog(o),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 20),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDeleteOffer(o),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(o.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(o.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 14)),
          if (o.requirements.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: o.requirements.map((req) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.accentBlue),
                  const SizedBox(width: 4),
                  Text(req, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                ],
              )).toList(),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: AppTheme.borderSubtle),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(o.location, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              if (o.salaryOrPrice != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.monetization_on_outlined, size: 16, color: AppTheme.accentCyan),
                const SizedBox(width: 4),
                Text(o.salaryOrPrice!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ],
              const Spacer(),
              const Icon(Icons.event_rounded, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('Date limite : $deadlineStr', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 6: PARAMÈTRES & CONFIGURATION
  // ==========================================
  Widget _buildSettingsTab(AppDataService service) {
    final whatsController = TextEditingController(text: service.whatsAppNumber);
    final auth = AuthService();

    // Charger les utilisateurs à l'ouverture de l'onglet
    if (auth.canManageUsers && !_usersLoadedOnce && !_usersLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAdminUsers());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (auth.canManageUsers) ...[
          _buildUsersManagementSection(),
          const SizedBox(height: 24),
        ],

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Coordonnées & Canaux de Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text('Numéro WhatsApp central utilisé pour les boutons de contact du site.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: whatsController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro WhatsApp (sans le +)',
                        prefixIcon: Icon(Icons.chat_rounded, color: AppTheme.accentCyan),
                        hintText: '243994673769',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton(
                    onPressed: () {
                      service.setWhatsAppNumber(whatsController.text.trim());
                      _showToast('Numéro WhatsApp mis à jour !');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Univers GM Overview
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Univers & Pôles d’Activité GREAT MINDS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text('Les 4 départements opérationnels connectés aux offres dynamiques.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 18),
              ...AppDataService.activities.map(
                (act) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(act.fallbackIcon, color: AppTheme.accentCyan, size: 20),
                  ),
                  title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  subtitle: Text(act.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${act.offerings.length} services', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentBlue)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Reset Data Box
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Réinitialisation des données de démonstration', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Recharge les articles et offres d’exemple fournis par défaut.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  service.resetToDemoData();
                  _showToast('Données réinitialisées avec succès.');
                },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.errorRed),
                label: const Text('Réinitialiser les données', style: TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorRed)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersManagementSection() {
    final auth = AuthService();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestion des utilisateurs & agents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      auth.isSuperAdmin
                          ? 'Créez des comptes avec rôles Super Admin, Admin ou Agent. Chaque agent dispose de ses propres identifiants.'
                          : 'Créez et gérez les comptes Agent avec identifiant (email) et mot de passe.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _usersLoading ? null : () => _loadAdminUsers(force: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Actualiser'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _openUserForm(),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Nouvel utilisateur'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Autorisations par rôle',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary),
                ),
                SizedBox(height: 8),
                Text(
                  '• Super Admin — accès total + suppression d’utilisateurs\n'
                  '• Admin — tous les modules + création d’Agents\n'
                  '• Agent — Vue d’ensemble, Publications, Offres, Notifications',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_usersLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_usersError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_usersError!, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _loadAdminUsers(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (_adminUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aucun utilisateur trouvé.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _adminUsers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = _adminUsers[index];
                final isSelf = user.id == auth.currentUserId;
                final roleColor = _roleBadgeColor(user.role);
                final isActive = user.status == AdminUserStatus.active;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: roleColor.withValues(alpha: 0.15),
                        child: Icon(Icons.person_rounded, color: roleColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelf) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentCyan.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Vous',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(user.email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.role.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: roleColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : AppTheme.errorRed.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.status.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isActive ? const Color(0xFF059669) : AppTheme.errorRed,
                                    ),
                                  ),
                                ),
                                Text(
                                  user.lastLoginAt != null
                                      ? 'Dernière connexion : ${dateFmt.format(user.lastLoginAt!.toLocal())}'
                                      : 'Jamais connecté',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Modifier',
                        onPressed: (!auth.isSuperAdmin && user.role != AdminRole.agent)
                            ? null
                            : () => _openUserForm(user),
                        icon: Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: (!auth.isSuperAdmin && user.role != AdminRole.agent)
                              ? AppTheme.textSecondary.withValues(alpha: 0.4)
                              : AppTheme.accentBlue,
                        ),
                      ),
                      if (!isSelf && (auth.isSuperAdmin || user.role == AdminRole.agent))
                        IconButton(
                          tooltip: isActive ? 'Suspendre' : 'Réactiver',
                          onPressed: () => _toggleUserStatus(user),
                          icon: Icon(
                            isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                            size: 20,
                            color: isActive ? AppTheme.errorRed : const Color(0xFF10B981),
                          ),
                        ),
                      if (auth.isSuperAdmin && !isSelf)
                        IconButton(
                          tooltip: 'Supprimer',
                          onPressed: () => _confirmDeleteUser(user),
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorRed),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: CENTRE DE NOTIFICATIONS (NOTIFICATIONS & LIKES)
  // ==========================================
  Widget _buildNotificationsTab(AppDataService service) {
    final notifs = service.notifications;
    final unreadCount = service.unreadNotificationsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Centre de Notifications & Likes',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount non lue${unreadCount > 1 ? 's' : ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Alertes en temps réel à chaque nouvel abonné ou like sur le site.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
            Row(
              children: [
                if (unreadCount > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      service.markAllNotificationsAsRead();
                      _showToast('Toutes les notifications ont été marquées comme lues.');
                    },
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Tout marquer comme lu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentBlue,
                      side: const BorderSide(color: AppTheme.accentBlue),
                    ),
                  ),
                const SizedBox(width: 8),
                if (notifs.isNotEmpty)
                  IconButton(
                    tooltip: 'Effacer l’historique',
                    icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.textSecondary),
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Effacer les notifications'),
                          content: const Text('Voulez-vous vraiment vider tout l’historique des notifications ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                service.clearNotifications();
                                _showToast('Historique des notifications effacé.');
                              },
                              style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
                              child: const Text('Effacer'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Notifications List
        if (notifs.isEmpty)
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.accentBlue),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune notification pour le moment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dès qu’un visiteur s’abonne ou aime une publication, une notification apparaîtra ici.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = notifs[index];
              final isLike = notif.type == 'like';
              final isSub = notif.type == 'subscription';

              final icon = isSub
                  ? Icons.celebration_rounded
                  : (isLike ? Icons.thumb_up_alt_rounded : Icons.notifications_rounded);
              final iconBg = isSub
                  ? const Color(0xFF10B981)
                  : (isLike ? const Color(0xFFE11D48) : AppTheme.accentBlue);

              return InkWell(
                onTap: () => service.markNotificationAsRead(notif.id),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notif.isRead ? Colors.white : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: notif.isRead ? AppTheme.borderSubtle : const Color(0xFF93C5FD),
                      width: notif.isRead ? 1 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBg.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: iconBg, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(notif.createdAt),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: notif.isRead ? AppTheme.textSecondary : const Color(0xFF1E293B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!notif.isRead) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ==========================================
  // TAB 4: GESTION DES ABONNÉS (COMMUNAUTÉ)
  // ==========================================
  Widget _buildSubscribersTab(AppDataService service) {
    final query = _searchSubscriberController.text.trim().toLowerCase();
    final allSubscribers = service.subscribers;
    final filtered = query.isEmpty
        ? allSubscribers
        : allSubscribers.where((s) {
            final email = s.email.toLowerCase();
            final name = (s.fullName ?? '').toLowerCase();
            final phone = (s.phone ?? '').toLowerCase();
            return email.contains(query) || name.contains(query) || phone.contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Gestion des Abonnés & Newsletter',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${allSubscribers.length} Abonnés',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Liste des visiteurs et candidats inscrits pour recevoir vos opportunités et actualités.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
            if (allSubscribers.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  final emails = allSubscribers.map((s) => s.email).join(', ');
                  Clipboard.setData(ClipboardData(text: emails));
                  _showToast('📋 ${allSubscribers.length} adresses emails copiées dans le presse-papier !');
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copier les emails'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: TextField(
            controller: _searchSubscriberController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              icon: const Icon(Icons.search, color: AppTheme.textSecondary),
              hintText: 'Rechercher par email, nom ou téléphone...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              border: InputBorder.none,
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchSubscriberController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Subscribers Table / List
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    query.isEmpty ? 'Aucun abonné enregistré' : 'Aucun résultat trouvé pour "$query"',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Les nouveaux abonnés inscrits depuis le formulaire s’afficheront directement ici.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sub = filtered[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                      child: Text(
                        (sub.fullName?.isNotEmpty == true ? sub.fullName![0] : sub.email[0]).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                sub.fullName?.isNotEmpty == true ? sub.fullName! : 'Abonné(e)',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lang: ${sub.language.toUpperCase()}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(sub.email, style: const TextStyle(fontSize: 13, color: AppTheme.accentBlue)),
                              if (sub.phone?.isNotEmpty == true) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(sub.phone!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(sub.subscribedAt),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 18),
                      tooltip: 'Supprimer cet abonné',
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Supprimer l’abonné'),
                            content: Text('Voulez-vous supprimer ${sub.email} de la liste ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  service.deleteSubscriber(sub.id);
                                  _showToast('Abonné supprimé.');
                                },
                                style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ==========================================
  // TAB 3: GESTION DES COMMANDES & VENTES EN LIGNE
  // ==========================================
  Widget _buildOrdersTab(AppDataService service) {
    final query = _searchOrderController.text.trim().toLowerCase();
    final allOrders = service.orders;

    final filtered = allOrders.where((order) {
      final matchesQuery = query.isEmpty ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerPhone.toLowerCase().contains(query) ||
          order.productTitle.toLowerCase().contains(query) ||
          order.id.toLowerCase().contains(query) ||
          order.reference.toLowerCase().contains(query) ||
          order.deliveryAddress.toLowerCase().contains(query) ||
          (order.city?.toLowerCase().contains(query) ?? false);

      final matchesStatus = _filterOrderStatus == 'Tous' || order.status == _filterOrderStatus;

      return matchesQuery && matchesStatus;
    }).toList();

    final pendingCount = allOrders.where((o) => o.status == 'En attente').length;
    final confirmedCount = allOrders.where((o) => o.status == 'Confirmée').length;
    final deliveryCount = allOrders.where((o) => o.status == 'En cours de livraison').length;
    final deliveredCount = allOrders.where((o) => o.status == 'Livrée').length;
    final cancelledCount = allOrders.where((o) => o.status == 'Annulée').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner / Statistics summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2A4A), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFFF59E0B), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commandes & Ventes en Ligne (Bouton "Se procurer")',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gérez les achats passés par les visiteurs sur chaque publication et produit.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Status summary pills
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _orderStatPill('Total', '${allOrders.length}', const Color(0xFF94A3B8), 'Tous'),
                  _orderStatPill('En attente', '$pendingCount', const Color(0xFFF59E0B), 'En attente'),
                  _orderStatPill('Confirmées', '$confirmedCount', const Color(0xFF3B82F6), 'Confirmée'),
                  _orderStatPill('En livraison', '$deliveryCount', const Color(0xFF8B5CF6), 'En cours de livraison'),
                  _orderStatPill('Livrées', '$deliveredCount', const Color(0xFF10B981), 'Livrée'),
                  _orderStatPill('Annulées', '$cancelledCount', const Color(0xFFEF4444), 'Annulée'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Search & Filter row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchOrderController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par client, téléphone, produit, ville ou réf (#CMD)...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchOrderController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchOrderController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              // Filter status dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterOrderStatus,
                    icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppTheme.accentBlue),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'Tous', child: Text('Tous les statuts')),
                      DropdownMenuItem(value: 'En attente', child: Text('En attente')),
                      DropdownMenuItem(value: 'Confirmée', child: Text('Confirmée')),
                      DropdownMenuItem(value: 'En cours de livraison', child: Text('En livraison')),
                      DropdownMenuItem(value: 'Livrée', child: Text('Livrée')),
                      DropdownMenuItem(value: 'Annulée', child: Text('Annulée')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _filterOrderStatus = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Orders list
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 48, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    query.isEmpty ? 'Aucune commande enregistrée pour le moment' : 'Aucun résultat trouvé pour "$query"',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Les commandes passées par les visiteurs via le bouton "Se procurer" apparaîtront ici avec toutes les coordonnées.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = filtered[index];
              final statusColor = _getOrderStatusColor(order.status);
              final statusIcon = _getOrderStatusIcon(order.status);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: order.status == 'En attente'
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                        : AppTheme.borderSubtle,
                    width: order.status == 'En attente' ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header of order card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: const Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.reference,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy à HH:mm').format(order.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  order.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product & Pricing info
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.sell_rounded, color: Color(0xFF059669), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.productTitle,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF064E3B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Prix unitaire: ${order.unitPrice} | Quantité: ${order.quantity}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Total: ${order.totalPrice}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Customer details grid
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 650;
                              return isCompact
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildCustomerSection(order),
                                        const SizedBox(height: 14),
                                        _buildDeliverySection(order),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildCustomerSection(order)),
                                        const SizedBox(width: 20),
                                        Expanded(child: _buildDeliverySection(order)),
                                      ],
                                    );
                            },
                          ),

                          if (order.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.note_alt_outlined, color: Color(0xFFD97706), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Note client : "${order.notes}"',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Statut de la commande :',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: order.status,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                items: const [
                                  DropdownMenuItem(value: 'En attente', child: Text('⏳ En attente')),
                                  DropdownMenuItem(value: 'Confirmée', child: Text('✓ Confirmée')),
                                  DropdownMenuItem(value: 'En cours de livraison', child: Text('🚚 En cours de livraison')),
                                  DropdownMenuItem(value: 'Livrée', child: Text('🎉 Livrée')),
                                  DropdownMenuItem(value: 'Annulée', child: Text('✕ Annulée')),
                                ],
                                onChanged: (newStatus) {
                                  if (newStatus != null && newStatus != order.status) {
                                    service.updateOrderStatus(order.id, newStatus);
                                    _showToast('Statut mis à jour : $newStatus');
                                  }
                                },
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                            tooltip: 'Supprimer la commande',
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer la commande'),
                                  content: Text('Voulez-vous supprimer définitivement la commande ${order.reference} ?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        service.deleteOrder(order.id);
                                        _showToast('Commande supprimée.');
                                      },
                                      style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCustomerSection(OrderItem order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CLIENT & CONTACT',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person_rounded, size: 16, color: AppTheme.accentBlue),
            const SizedBox(width: 8),
            Text(
              order.customerName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            SelectableText(
              order.customerPhone,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F766E)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.grey),
              tooltip: 'Copier le numéro',
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: order.customerPhone));
                _showToast('Numéro copié : ${order.customerPhone}');
              },
            ),
          ],
        ),
        if (order.customerEmail?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                order.customerEmail!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDeliverySection(OrderItem order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVRAISON & PAIEMENT',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.payment_rounded, size: 16, color: AppTheme.accentGold),
            const SizedBox(width: 8),
            Text(
              order.paymentMethod,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${order.city ?? 'Ville non précisée'} : ${order.deliveryAddress.isNotEmpty ? order.deliveryAddress : 'Adresse non précisée'}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _orderStatPill(String label, String count, Color color, String filterValue) {
    final isSelected = _filterOrderStatus == filterValue;
    return InkWell(
      onTap: () => setState(() => _filterOrderStatus = filterValue),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0F2A4A) : Colors.white,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0F2A4A) : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return const Color(0xFFF59E0B);
      case 'Confirmée':
        return const Color(0xFF3B82F6);
      case 'En cours de livraison':
        return const Color(0xFF8B5CF6);
      case 'Livrée':
        return const Color(0xFF10B981);
      case 'Annulée':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'En attente':
        return Icons.hourglass_top_rounded;
      case 'Confirmée':
        return Icons.check_circle_outline_rounded;
      case 'En cours de livraison':
        return Icons.local_shipping_rounded;
      case 'Livrée':
        return Icons.verified_rounded;
      case 'Annulée':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
