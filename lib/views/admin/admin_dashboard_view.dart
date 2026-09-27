import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/offer_model.dart';
import '../../models/publication_model.dart';
import '../../services/app_data_service.dart';
import '../../services/auth_service.dart';
import 'offer_form_dialog.dart';
import 'publication_form_dialog.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedTabIndex = 0; // 0: Overview, 1: Publications, 2: Offers, 3: Settings
  final TextEditingController _searchPubController = TextEditingController();
  final TextEditingController _searchOfferController = TextEditingController();
  String _filterPubCategory = 'Tous';
  String _filterPubDept = 'Tous';
  String _filterOfferDept = 'Tous';
  String _filterOfferType = 'Tous';
  bool _isSyncing = false;

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
  void dispose() {
    _searchPubController.dispose();
    _searchOfferController.dispose();
    super.dispose();
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
        return 'Paramètres & Configuration';
      default:
        return 'Administration';
    }
  }

  // --- Sidebar ---
  Widget _buildSidebar({bool isDrawer = false}) {
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
                _sidebarItem(0, Icons.dashboard_rounded, 'Vue d’ensemble'),
                _sidebarItem(1, Icons.article_rounded, 'Publications & Actus'),
                _sidebarItem(2, Icons.work_outline_rounded, 'Offres & Emploi'),
                _sidebarItem(3, Icons.settings_rounded, 'Paramètres'),
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
                            AuthService().currentUsername.isEmpty ? 'Administrateur' : AuthService().currentUsername,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text('Super Admin', style: TextStyle(color: Color(0xFF7CA0C2), fontSize: 11)),
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

  Widget _sidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedTabIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? AppTheme.accentBlue : Colors.transparent,
        leading: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF8BAFCF), size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFD3E4F4),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          setState(() => _selectedTabIndex = index);
          if (Navigator.of(context).canPop() && MediaQuery.sizeOf(context).width < 900) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  // --- Current Tab Router ---
  Widget _buildCurrentTab(AppDataService service) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(service);
      case 1:
        return _buildPublicationsTab(service);
      case 2:
        return _buildOffersTab(service);
      case 3:
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
    final totalViews = service.publications.fold<int>(0, (sum, p) => sum + p.viewsCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 600 ? double.infinity : (constraints.maxWidth - 36) / (constraints.maxWidth < 1100 ? 2 : 4);
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
                    'Offres Urgentes',
                    '$urgentOffers',
                    Icons.flash_on_rounded,
                    AppTheme.warningOrange,
                    'Priorité recrutement',
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    ...['Tous', 'Toutes les activités', 'GM Formation & Emploi', 'GM Parfum', 'GM Texa', 'GM Autosolution', 'GM Fondation'].map(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    ...['Tous', 'GM Formation & Emploi', 'GM Parfum', 'GM Texa', 'GM Autosolution', 'GM Fondation'].map(
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
  // TAB 3: PARAMÈTRES & CONFIGURATION
  // ==========================================
  Widget _buildSettingsTab(AppDataService service) {
    final whatsController = TextEditingController(text: service.whatsAppNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
}
