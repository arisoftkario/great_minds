import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_model.dart';
import '../../models/offer_model.dart';
import '../../models/publication_model.dart';
import '../../services/app_data_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/pwa_install_service.dart';
import '../admin/admin_dashboard_view.dart';
import '../admin/admin_login_view.dart';
import '../common/app_image_viewer.dart';
import 'widgets/offer_detail_dialog.dart';
import 'widgets/offers_section.dart';
import 'widgets/publication_detail_dialog.dart';
import 'widgets/publications_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _universKey = GlobalKey();
  final GlobalKey _offersKey = GlobalKey();
  final GlobalKey _newsKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _methodKey = GlobalKey();

  Future<void> _openWhatsApp([String? message]) async {
    final whatsAppNumber = AppDataService().whatsAppNumber;
    final whatsAppUri = Uri.https('wa.me', '/$whatsAppNumber', <String, String>{
      'text': message ??
          'Bonjour GREAT MINDS GROUP, je souhaite obtenir plus d’informations.',
    });

    if (!await launchUrl(whatsAppUri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _showMessage(
        'Impossible d’ouvrir WhatsApp. Contactez-nous au +$whatsAppNumber.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openAdminPortal() {
    if (AuthService().isAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const AdminDashboardView(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const AdminLoginView(),
        ),
      );
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleNavigate(String section) {
    switch (section) {
      case 'home':
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
        break;
      case 'services':
        _scrollToKey(_servicesKey);
        break;
      case 'univers':
        _scrollToKey(_universKey);
        break;
      case 'offers':
        _scrollToKey(_offersKey);
        break;
      case 'news':
        _scrollToKey(_newsKey);
        break;
      case 'about':
        _scrollToKey(_aboutKey);
        break;
      case 'method':
        _scrollToKey(_methodKey);
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: _MobileDrawer(
            onNavigate: _handleNavigate,
            onContact: _openWhatsApp,
            onAdminPortal: _openAdminPortal,
          ),
          backgroundColor: AppTheme.lightBg,
          floatingActionButton: ValueListenableBuilder<bool>(
            valueListenable: PwaInstallService.isInstalledNotifier,
            builder: (context, isInstalled, child) {
              if (isInstalled) return const SizedBox.shrink();
              return FloatingActionButton.extended(
                onPressed: () => PwaInstallService.promptInstall(context),
                backgroundColor: const Color(0xFFE5A93C),
                foregroundColor: Colors.black,
                elevation: 6,
                icon: const Icon(Icons.install_mobile_rounded, size: 20),
                label: Text(
                  LanguageService().t('nav_install'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              );
            },
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // 1. Hero & Navigation (Page d'accueil)
                _HeroSection(
                  onExplore: () => _scrollToKey(_newsKey),
                  onContact: _openWhatsApp,
                  onNavigate: _handleNavigate,
                  onAdminPortal: _openAdminPortal,
                  onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                ),

                // 2. Dynamic Publications & News Section (Actualités des publications directement sous l'accueil)
                Container(key: _newsKey, child: const PublicationsSection()),

                // 3. Dynamic Offers Section (Offres & Formations)
                Container(key: _offersKey, child: const OffersSection()),

                // 4. Stats
                const _StatsSection(),

                // 5. Services / Pôles
                Container(key: _servicesKey, child: const _ServicesSection()),

                // 6. Univers / Activities
                Container(
                  key: _universKey,
                  child: _BusinessActivitiesSection(
                    onOrder: (activity) => _openWhatsApp(
                      'Bonjour GREAT MINDS GROUP, je souhaite ${activity.requestMessage}.',
                    ),
                    onVisit: (activity) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => _DepartmentPage(
                          activity: activity,
                          onContact: () => _openWhatsApp(
                            'Bonjour GREAT MINDS GROUP, je souhaite ${activity.requestMessage}.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 7. About
                Container(key: _aboutKey, child: const _AboutSection()),

                // 8. Process / Method
                Container(key: _methodKey, child: const _ProcessSection()),

                // 9. CTA
                _CTASection(onContact: _openWhatsApp),

                // 10. Footer
                _Footer(
                  onContact: _openWhatsApp,
                  onAdminPortal: _openAdminPortal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// HERO & NAVIGATION
// ==========================================
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.onExplore,
    required this.onContact,
    required this.onNavigate,
    required this.onAdminPortal,
    this.onOpenMenu,
  });

  final VoidCallback onExplore;
  final VoidCallback onContact;
  final ValueChanged<String> onNavigate;
  final VoidCallback onAdminPortal;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 720),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF061A2E), Color(0xFF0B2F4F), Color(0xFF113C62)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _Navigation(
                  onContact: onContact,
                  onNavigate: onNavigate,
                  onAdminPortal: onAdminPortal,
                  onOpenMenu: onOpenMenu,
                ),
              ),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 18,
                        vertical: compact ? 12 : 24,
                      ),
                      child: compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._heroContent(onExplore, onContact, onAdminPortal, compact: true),
                                const SizedBox(height: 36),
                                const Center(
                                  child: _BusinessVisual(isCompact: true),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _heroContent(onExplore, onContact, onAdminPortal),
                                  ),
                                ),
                                const SizedBox(width: 28),
                                const _BusinessVisual(),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _heroContent(
    VoidCallback onExplore,
    VoidCallback onContact,
    VoidCallback onAdminPortal, {
    bool compact = false,
  }) => [
    const _HeroLogo(),
    const SizedBox(height: 26),
    Text(
      'GREAT MINDS\nGROUP',
      style: TextStyle(
        fontSize: compact ? 38 : 58,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFF5FAFF),
        height: 0.95,
        letterSpacing: compact ? -1 : -2,
      ),
    ),
    const SizedBox(height: 18),
    const Text(
      'GM GROUP',
      style: TextStyle(
        color: Color(0xFF8FD6FF),
        fontSize: 18,
        letterSpacing: 4,
        fontWeight: FontWeight.w800,
      ),
    ),
    const SizedBox(height: 22),
    SizedBox(
      width: compact ? double.infinity : 480,
      child: Text(
        LanguageService().t('hero_subtitle'),
        style: const TextStyle(color: Color(0xFFD7E7F7), fontSize: 17, height: 1.6),
      ),
    ),
    const SizedBox(height: 28),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Pill(label: LanguageService().t('hero_pill_emploi')),
        _Pill(label: LanguageService().t('hero_pill_parfum')),
        _Pill(label: LanguageService().t('hero_pill_texa')),
        _Pill(label: LanguageService().t('hero_pill_auto')),
        _Pill(label: LanguageService().t('hero_pill_fondation')),
      ],
    ),
    const SizedBox(height: 34),
    Wrap(
      spacing: 14,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: onContact,
          icon: const Icon(Icons.chat_rounded, size: 18),
          label: Text(LanguageService().t('hero_btn_contact')),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF59D6B6),
            foregroundColor: const Color(0xFF061A2E),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onExplore,
          icon: const Icon(Icons.arrow_downward_rounded, size: 18),
          label: Text(LanguageService().t('hero_btn_offers')),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFB7D9F1)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          ),
        ),
      ],
    ),
  ];
}

class _Navigation extends StatelessWidget {
  const _Navigation({
    required this.onContact,
    required this.onNavigate,
    required this.onAdminPortal,
    this.onOpenMenu,
  });

  final VoidCallback onContact;
  final ValueChanged<String> onNavigate;
  final VoidCallback onAdminPortal;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 760;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const _Brand(),
          const Spacer(),
          if (!isMobile) ...[
            TextButton(onPressed: () => onNavigate('news'), child: Text(LanguageService().t('nav_publications'), style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.w700))),
            TextButton(onPressed: () => onNavigate('offers'), child: Text(LanguageService().t('nav_offers'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => onNavigate('services'), child: Text(LanguageService().t('nav_activities'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => onNavigate('univers'), child: Text(LanguageService().t('nav_univers'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => onNavigate('about'), child: Text(LanguageService().t('nav_about'), style: const TextStyle(color: Colors.white70))),
            const SizedBox(width: 8),
          ],
          // Language Switcher Dropdown (Reactive)
          ListenableBuilder(
            listenable: LanguageService(),
            builder: (context, _) {
              final currentLang = LanguageService().currentLanguage;
              final currentModel = LanguageService().currentLanguageModel;
              return PopupMenuButton<String>(
                tooltip: 'Changer de langue / Change Language',
                onSelected: (String langCode) {
                  LanguageService().setLanguage(langCode);
                },
                offset: const Offset(0, 48),
                color: const Color(0xFF0D253A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF59D6B6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF59D6B6).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentModel.flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        currentLang.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF59D6B6),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF59D6B6), size: 18),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) {
                  return LanguageService().supportedLanguages.map((lang) {
                    final isSelected = lang.code == currentLang;
                    return PopupMenuItem<String>(
                      value: lang.code,
                      child: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            lang.name,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF59D6B6) : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          if (isSelected) ...[
                            const Spacer(),
                            const Icon(Icons.check_rounded, color: Color(0xFF59D6B6), size: 16),
                          ],
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
          const SizedBox(width: 6),
          // Install App Button
          ValueListenableBuilder<bool>(
            valueListenable: PwaInstallService.isInstalledNotifier,
            builder: (context, isInstalled, child) {
              if (isInstalled) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: isMobile
                    ? IconButton(
                        onPressed: () => PwaInstallService.promptInstall(context),
                        tooltip: LanguageService().t('nav_install'),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A93C),
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.install_mobile_rounded, size: 20),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => PwaInstallService.promptInstall(context),
                        icon: const Icon(Icons.install_mobile_rounded, size: 16),
                        label: Text(LanguageService().t('nav_install'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A93C),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              );
            },
          ),
          // Sync / Refresh Button (Auto-synchro 10s active)
          ListenableBuilder(
            listenable: AppDataService(),
            builder: (context, _) {
              final isSyncing = AppDataService().isSyncing;
              return IconButton(
                onPressed: () async {
                  await AppDataService().syncData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(LanguageService().t('nav_sync_success')),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                tooltip: LanguageService().t('nav_sync_tooltip'),
                style: IconButton.styleFrom(
                  backgroundColor: isSyncing 
                      ? const Color(0xFF59D6B6).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  foregroundColor: isSyncing ? const Color(0xFF59D6B6) : Colors.white70,
                ),
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF59D6B6)),
                      )
                    : const Icon(Icons.sync_rounded, size: 20),
              );
            },
          ),
          const SizedBox(width: 6),
          // Admin Access Button
          IconButton(
            onPressed: onAdminPortal,
            tooltip: LanguageService().t('nav_admin'),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: AppTheme.accentCyan,
            ),
            icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
          ),
          const SizedBox(width: 6),
          // Contact WhatsApp Button
          if (isMobile)
            IconButton(
              onPressed: onContact,
              tooltip: 'Contact WhatsApp',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF59D6B6),
                foregroundColor: const Color(0xFF061A2E),
              ),
              icon: const Icon(Icons.chat_rounded, size: 20),
            )
          else
            OutlinedButton(
              onPressed: onContact,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF59D6B6)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              child: Text(LanguageService().t('contact_btn_chat')),
            ),
          // Hamburger Menu Button (Mobile & Tablet)
          if (isMobile) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: onOpenMenu,
              tooltip: 'Menu',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF59D6B6).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFF59D6B6),
              ),
              icon: const Icon(Icons.menu_rounded, size: 22),
            ),
          ],
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF59D6B6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.business_center_rounded,
              color: Color(0xFF061A2E),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GREAT MINDS',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Colors.white,
              ),
            ),
            Text(
              'GROUP',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.2,
                color: Color(0xFF8FD6FF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroLogo extends StatelessWidget {
  const _HeroLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo GREAT MINDS GROUP',
      child: Container(
        width: 122,
        height: 122,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF6FE8CB), Color(0xFF3A9BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFC9F6EA), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/Image.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const _HeroLogoFallback(),
          ),
        ),
      ),
    );
  }
}

class _HeroLogoFallback extends StatelessWidget {
  const _HeroLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.auto_awesome_rounded, color: Color(0xCC061A2E), size: 84),
        Container(
          width: 82,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF061A2E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'GM',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF123B58),
        border: Border.all(color: const Color(0xFF87B9DE)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFF2F9FF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _BusinessVisual extends StatelessWidget {
  const _BusinessVisual({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? double.infinity : 360,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D253A), Color(0xFF071828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF59D6B6).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF59D6B6).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Visual Showcase Container
          Container(
            height: isCompact ? 170 : 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF133B5C), Color(0xFF0A2238)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Background Ambient Glow
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF59D6B6).withValues(alpha: 0.35),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                // Center Futuristic Icon with Orbit Ring
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF59D6B6), Color(0xFF2E8BFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF59D6B6).withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        size: 44,
                        color: Color(0xFF051726),
                      ),
                    ),
                  ),
                ),
                // Floating Badge Top-Left (+92% Insertion)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061A2E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF59D6B6).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Color(0xFF59D6B6), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          LanguageService().t('vision_stat_1'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Floating Badge Bottom-Right (2000+ Talents)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061A2E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5A93C).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFE5A93C), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          LanguageService().t('vision_stat_2'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Content & Description Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF59D6B6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF59D6B6),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      LanguageService().t('vision_title'),
                      style: const TextStyle(
                        color: Color(0xFFF3F9FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  LanguageService().t('vision_desc'),
                  style: const TextStyle(
                    color: Color(0xFFD5EAF7),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                // Micro Capsules
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPillarChip(LanguageService().t('vision_tag_1')),
                    _buildPillarChip(LanguageService().t('vision_tag_2')),
                    _buildPillarChip(LanguageService().t('vision_tag_3')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPillarChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF59D6B6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF59D6B6).withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF59D6B6),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ==========================================
// STATS SECTION
// ==========================================
class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat(number: LanguageService().t('stat_assisted_num'), label: LanguageService().t('stat_assisted_lbl')),
      _Stat(number: LanguageService().t('stat_partners_num'), label: LanguageService().t('stat_partners_lbl')),
      _Stat(number: LanguageService().t('stat_satisfaction_num'), label: LanguageService().t('stat_satisfaction_lbl')),
    ];

    return Container(
      color: const Color(0xFFF4F8FC),
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 18,
            children: stats.map((s) => SizedBox(width: 300, child: s)).toList(),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBF4)),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFF061A2E),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5A6E82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SERVICES SECTION
// ==========================================
class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ServiceCard(
        icon: Icons.work_history_rounded,
        title: LanguageService().t('service_1_title'),
        description: LanguageService().t('service_1_desc'),
      ),
      _ServiceCard(
        icon: Icons.auto_stories_rounded,
        title: LanguageService().t('service_2_title'),
        description: LanguageService().t('service_2_desc'),
      ),
      _ServiceCard(
        icon: Icons.support_agent_rounded,
        title: LanguageService().t('service_3_title'),
        description: LanguageService().t('service_3_desc'),
      ),
    ];

    return Container(
      color: const Color(0xFFF9FBFF),
      padding: const EdgeInsets.fromLTRB(24, 90, 24, 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageService().t('services_badge'),
                style: const TextStyle(
                  color: Color(0xFF1B7AE6),
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                LanguageService().t('services_title'),
                style: const TextStyle(
                  color: Color(0xFF061A2E),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 820;
                  final cards = items
                      .map(
                        (item) => compact
                            ? Container(margin: const EdgeInsets.only(bottom: 18), child: item)
                            : Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 18),
                                  child: item,
                                ),
                              ),
                      )
                      .toList();
                  return compact ? Column(children: cards) : Row(children: cards);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF1B7AE6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF0D335B), size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF061A2E),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF536D84), height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// BUSINESS ACTIVITIES (UNIVERS GM)
// ==========================================
class _BusinessActivitiesSection extends StatelessWidget {
  const _BusinessActivitiesSection({
    required this.onOrder,
    required this.onVisit,
  });

  final ValueChanged<BusinessActivity> onOrder;
  final ValueChanged<BusinessActivity> onVisit;

  @override
  Widget build(BuildContext context) {
    final activities = AppDataService.activities;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 90, 24, 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageService().t('univers_badge'),
                style: const TextStyle(
                  color: Color(0xFF1B7AE6),
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                LanguageService().t('univers_title'),
                style: const TextStyle(
                  color: Color(0xFF061A2E),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                LanguageService().t('univers_subtitle'),
                style: const TextStyle(
                  color: Color(0xFF536D84),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 820;
                  if (compact) {
                    return Column(
                      children: activities
                          .map(
                            (activity) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _BusinessActivityCard(
                                activity: activity,
                                onOrder: () => onOrder(activity),
                                onVisit: () => onVisit(activity),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: activities
                        .map(
                          (activity) => SizedBox(
                            width: (constraints.maxWidth - 18) / 2,
                            child: _BusinessActivityCard(
                              activity: activity,
                              onOrder: () => onOrder(activity),
                              onVisit: () => onVisit(activity),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessActivityCard extends StatelessWidget {
  const _BusinessActivityCard({
    required this.activity,
    required this.onOrder,
    required this.onVisit,
  });

  final BusinessActivity activity;
  final VoidCallback onOrder;
  final VoidCallback onVisit;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            image: true,
            label: activity.title,
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: activity.imageAsset == null
                  ? _ActivityImageFallback(icon: activity.fallbackIcon)
                  : Image.asset(
                      activity.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _ActivityImageFallback(icon: activity.fallbackIcon),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: Color(0xFF061A2E),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  activity.description,
                  style: const TextStyle(color: Color(0xFF536D84), height: 1.6),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onOrder,
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: Text(activity.actionLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0C3153),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onVisit,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(LanguageService().t('univers_visit_dept')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF073454),
                        backgroundColor: const Color(0xFF59D6B6),
                        side: const BorderSide(color: Color(0xFF073454), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityImageFallback extends StatelessWidget {
  const _ActivityImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C3153),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF59D6B6), size: 64),
    );
  }
}

// ==========================================
// DEPARTMENT PAGE
// ==========================================
class _DepartmentPage extends StatelessWidget {
  const _DepartmentPage({required this.activity, required this.onContact});

  final BusinessActivity activity;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF061A2E),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 68),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: Text(LanguageService().t('dept_back_btn')),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFB9DDF5)),
                        ),
                        const SizedBox(height: 42),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 700;
                            final identity = _DepartmentIdentity(activity: activity);
                            final details = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LanguageService().t('dept_header_badge'),
                                  style: const TextStyle(
                                    color: Color(0xFF59D6B6),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.8,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${LanguageService().t('dept_title_prefix')} ${activity.title}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 42,
                                    height: 1.08,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  activity.description,
                                  style: const TextStyle(color: Color(0xFFD7E7F7), height: 1.6, fontSize: 17),
                                ),
                                const SizedBox(height: 26),
                                FilledButton.icon(
                                  onPressed: onContact,
                                  icon: const Icon(Icons.chat_rounded),
                                  label: Text(activity.actionLabel),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF59D6B6),
                                    foregroundColor: const Color(0xFF061A2E),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                                  ),
                                ),
                              ],
                            );
                            return compact
                                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [identity, const SizedBox(height: 30), details])
                                : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [identity, const SizedBox(width: 44), Expanded(child: details)]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Dynamic Publications & Announcements Section for this department
              ListenableBuilder(
                listenable: AppDataService(),
                builder: (context, _) {
                  final pubs = AppDataService().publishedPublications.where((p) {
                    final dept = p.department.toLowerCase();
                    final actId = activity.id.toLowerCase();
                    if (actId == 'parfum') return dept.contains('parfum');
                    if (actId == 'texa') return dept.contains('texa') || dept.contains('visa') || dept.contains('passeport');
                    if (actId == 'autosolution') return dept.contains('auto');
                    if (actId == 'fondation') return dept.contains('fondation');
                    if (actId == 'emploi') return dept.contains('emploi') || dept.contains('formation');
                    return dept.contains(actId) || activity.title.toLowerCase().contains(dept);
                  }).toList();

                  if (pubs.isEmpty) return const SizedBox.shrink();

                  return Container(
                    color: const Color(0xFFF9FBFF),
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LanguageService().t('dept_pubs_badge'),
                                      style: const TextStyle(
                                        color: Color(0xFF1B7AE6),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.8,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${LanguageService().t('dept_pubs_title')} (${activity.title})',
                                      style: const TextStyle(
                                        color: Color(0xFF061A2E),
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B7AE6).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${pubs.length} publication${pubs.length > 1 ? "s" : ""}',
                                    style: const TextStyle(
                                      color: Color(0xFF1B7AE6),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 760;
                                return Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  children: pubs.map((pub) {
                                    return SizedBox(
                                      width: compact ? double.infinity : (constraints.maxWidth - 20) / 2,
                                      child: _DepartmentPublicationCard(
                                        publication: pub,
                                        activity: activity,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Dynamic Products & Opportunities Section for this department
              ListenableBuilder(
                listenable: AppDataService(),
                builder: (context, _) {
                  final offers = AppDataService().activeOffers.where((offer) {
                    final dept = offer.department.toLowerCase();
                    final actId = activity.id.toLowerCase();
                    if (actId == 'parfum') return dept.contains('parfum');
                    if (actId == 'texa') return dept.contains('texa') || dept.contains('visa') || dept.contains('passeport');
                    if (actId == 'autosolution') return dept.contains('auto');
                    if (actId == 'fondation') return dept.contains('fondation');
                    if (actId == 'emploi') return dept.contains('emploi') || dept.contains('formation');
                    return dept.contains(actId) || activity.title.toLowerCase().contains(dept);
                  }).toList();

                  if (offers.isEmpty) return const SizedBox.shrink();

                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LanguageService().t('dept_offers_badge'),
                                      style: const TextStyle(
                                        color: Color(0xFF1B7AE6),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.8,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${LanguageService().t('dept_offers_title')} (${activity.title})',
                                      style: const TextStyle(
                                        color: Color(0xFF061A2E),
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B7AE6).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${offers.length} active(s)',
                                    style: const TextStyle(
                                      color: Color(0xFF1B7AE6),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 760;
                                return Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  children: offers.map((offer) {
                                    return SizedBox(
                                      width: compact ? double.infinity : (constraints.maxWidth - 20) / 2,
                                      child: _DepartmentProductCard(
                                        offer: offer,
                                        activity: activity,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 78),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageService().t('dept_services_badge'),
                          style: const TextStyle(color: Color(0xFF1B7AE6), fontWeight: FontWeight.w800, letterSpacing: 1.8, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          LanguageService().t('dept_services_title'),
                          style: const TextStyle(color: Color(0xFF061A2E), fontSize: 34, fontWeight: FontWeight.w800, height: 1.1),
                        ),
                        const SizedBox(height: 32),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 760;
                            final cards = activity.offerings.map((offering) => _DepartmentOfferingCard(offering: offering)).toList();
                            return compact
                                ? Column(children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 16), child: card)).toList())
                                : Row(children: cards.map((card) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: card))).toList());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentPublicationCard extends StatelessWidget {
  const _DepartmentPublicationCard({
    required this.publication,
    required this.activity,
  });

  final Publication publication;
  final BusinessActivity activity;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(publication.publishedDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (publication.primaryImage != null)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: AppImageViewer(
                imageSource: publication.primaryImage,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B7AE6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        publication.category,
                        style: const TextStyle(
                          color: Color(0xFF1B7AE6),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  publication.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF061A2E),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  publication.summary,
                  style: const TextStyle(
                    color: Color(0xFF5A7184),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      publication.author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        AppDataService().incrementPublicationViews(publication.id);
                        showDialog<void>(
                          context: context,
                          builder: (context) => PublicationDetailDialog(publication: publication),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: Text(LanguageService().t('pubs_read_more')),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF061A2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentProductCard extends StatelessWidget {
  const _DepartmentProductCard({
    required this.offer,
    required this.activity,
  });

  final Offer offer;
  final BusinessActivity activity;

  Future<void> _orderViaWhatsApp(BuildContext context) async {
    final whatsAppNumber = offer.customContactWhatsApp ?? AppDataService().whatsAppNumber;
    final message = 'Bonjour GREAT MINDS GROUP, je souhaite commander / souscrire à "${offer.title}" (${offer.department} - Réf: ${offer.id}).';
    final uri = Uri.https('wa.me', '/$whatsAppNumber', {'text': message});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d’ouvrir WhatsApp. Contactez-nous au +$whatsAppNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color typeBg = const Color(0xFFE8F1FF);
    Color typeColor = const Color(0xFF1B7AE6);

    switch (offer.type) {
      case 'Promotion':
        typeBg = const Color(0xFFFFF0F5);
        typeColor = const Color(0xFFD63384);
        break;
      case 'Emploi':
        typeBg = const Color(0xFFE6F8F2);
        typeColor = const Color(0xFF0D9488);
        break;
      case 'Stage':
        typeBg = const Color(0xFFFFF8E6);
        typeColor = const Color(0xFFD97706);
        break;
      case 'Formation':
        typeBg = const Color(0xFFF3E8FF);
        typeColor = const Color(0xFF7C3AED);
        break;
      case 'Partenariat':
        typeBg = const Color(0xFFECFDF5);
        typeColor = const Color(0xFF059669);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E7F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: typeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (offer.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: Colors.red),
                      SizedBox(width: 3),
                      Text(
                        'VEDETTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offer.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.25,
            ),
          ),
          if (offer.salaryOrPrice != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF59D6B6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer.salaryOrPrice!,
                style: const TextStyle(
                  color: Color(0xFF095A48),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            offer.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          if (offer.requirements.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: offer.requirements.take(2).map((req) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF1B7AE6)),
                      const SizedBox(width: 4),
                      Text(
                        req.length > 35 ? '${req.substring(0, 32)}...' : req,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4A657E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(height: 1, color: Color(0xFFE8EFF6)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => OfferDetailDialog(offer: offer),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF061A2E),
                    side: const BorderSide(color: Color(0xFFB5CDE4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(LanguageService().t('dept_details_btn'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _orderViaWhatsApp(context),
                  icon: const Icon(Icons.shopping_bag_rounded, size: 15),
                  label: Text(LanguageService().t('dept_order_btn'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B7AE6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepartmentIdentity extends StatelessWidget {
  const _DepartmentIdentity({required this.activity});

  final BusinessActivity activity;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo ${activity.title}',
      child: Container(
        width: 190,
        height: 190,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF59D6B6), width: 2),
        ),
        child: activity.imageAsset == null
            ? _ActivityImageFallback(icon: activity.fallbackIcon)
            : Image.asset(
                activity.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _ActivityImageFallback(icon: activity.fallbackIcon),
              ),
      ),
    );
  }
}

class _DepartmentOfferingCard extends StatelessWidget {
  const _DepartmentOfferingCard({required this.offering});

  final DepartmentOffering offering;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(offering.icon, color: const Color(0xFF1B7AE6), size: 32),
          const Spacer(),
          Text(offering.title, style: const TextStyle(color: Color(0xFF061A2E), fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(offering.description, style: const TextStyle(color: Color(0xFF536D84), height: 1.5)),
        ],
      ),
    );
  }
}

// ==========================================
// ABOUT SECTION
// ==========================================
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C1F35),
      padding: const EdgeInsets.fromLTRB(24, 90, 24, 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageService().t('about_badge'),
                    style: const TextStyle(color: Color(0xFF59D6B6), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LanguageService().t('about_title'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 36 : 46,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    LanguageService().t('about_subtitle'),
                    style: const TextStyle(color: Color(0xFFCBDCEB), height: 1.7, fontSize: 17),
                  ),
                  const SizedBox(height: 24),
                  const _AboutList(),
                ],
              );

              if (compact) {
                return textBlock;
              }

              return Row(
                children: [
                  Expanded(child: textBlock),
                  const SizedBox(width: 28),
                  Container(
                    width: 320,
                    height: 360,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF59D6B6), Color(0xFF1B7AE6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Icon(Icons.groups_2_rounded, size: 100, color: Color(0xFF061A2E)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AboutList extends StatelessWidget {
  const _AboutList();

  @override
  Widget build(BuildContext context) {
    final items = [
      LanguageService().t('about_point_1'),
      LanguageService().t('about_point_2'),
      LanguageService().t('about_point_3'),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF59D6B6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item, style: const TextStyle(color: Color(0xFFEAF7FF), height: 1.6)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ==========================================
// PROCESS SECTION
// ==========================================
class _ProcessSection extends StatelessWidget {
  const _ProcessSection();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('01', LanguageService().t('step_1_title'), LanguageService().t('step_1_desc')),
      ('02', LanguageService().t('step_2_title'), LanguageService().t('step_2_desc')),
      ('03', LanguageService().t('step_3_title'), LanguageService().t('step_3_desc')),
    ];

    return Container(
      color: const Color(0xFFF4F8FC),
      padding: const EdgeInsets.fromLTRB(24, 90, 24, 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageService().t('process_badge'),
                style: const TextStyle(color: Color(0xFF1B7AE6), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Text(
                LanguageService().t('process_title'),
                style: const TextStyle(color: Color(0xFF061A2E), fontSize: 42, fontWeight: FontWeight.w800, height: 1.05),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 820;
                  return compact
                      ? Column(
                          children: steps
                              .map((step) => Padding(padding: const EdgeInsets.only(bottom: 18), child: _StepCard(step: step)))
                              .toList(),
                        )
                      : Row(
                          children: steps
                              .map((step) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 18), child: _StepCard(step: step))))
                              .toList(),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final (String, String, String) step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.$1, style: const TextStyle(color: Color(0xFF1B7AE6), fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Text(step.$2, style: const TextStyle(color: Color(0xFF061A2E), fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(step.$3, style: const TextStyle(color: Color(0xFF536D84), height: 1.6)),
        ],
      ),
    );
  }
}

// ==========================================
// CTA SECTION
// ==========================================
class _CTASection extends StatelessWidget {
  const _CTASection({required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF59D6B6),
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final text = Text(
                LanguageService().t('cta_title'),
                style: const TextStyle(color: Color(0xFF061A2E), fontSize: 42, fontWeight: FontWeight.w800, height: 1.1),
              );
              final button = FilledButton(
                onPressed: onContact,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF061A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                ),
                child: Text(LanguageService().t('cta_button')),
              );
              return compact
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 24), button])
                  : Row(children: [Expanded(child: text), button]);
            },
          ),
        ),
      ),
    );
  }
}

// ==========================================
// FOOTER
// ==========================================
class _Footer extends StatelessWidget {
  const _Footer({required this.onContact, required this.onAdminPortal});

  final VoidCallback onContact;
  final VoidCallback onAdminPortal;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF061A2E),
      padding: const EdgeInsets.fromLTRB(24, 38, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Brand(),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: PwaInstallService.isInstalledNotifier,
                    builder: (context, isInstalled, child) {
                      if (isInstalled) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: TextButton.icon(
                          onPressed: () => PwaInstallService.promptInstall(context),
                          icon: const Icon(Icons.install_mobile_rounded, size: 16, color: Color(0xFFE5A93C)),
                          label: Text(
                            LanguageService().t('nav_install'),
                            style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton.icon(
                    onPressed: onAdminPortal,
                    icon: const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF8FBCE4)),
                    label: Text(
                      LanguageService().t('nav_admin'),
                      style: const TextStyle(color: Color(0xFF8FBCE4), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 14),
                  TextButton(
                    onPressed: onContact,
                    child: Text(
                      LanguageService().t('contact_btn_chat'),
                      style: const TextStyle(color: Color(0xFF59D6B6), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Footer Language Selector
                  ListenableBuilder(
                    listenable: LanguageService(),
                    builder: (context, _) {
                      final currentLang = LanguageService().currentLanguage;
                      final currentModel = LanguageService().currentLanguageModel;
                      return PopupMenuButton<String>(
                        tooltip: 'Langue / Language',
                        onSelected: (String langCode) {
                          LanguageService().setLanguage(langCode);
                        },
                        offset: const Offset(0, -180),
                        color: const Color(0xFF0D253A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currentModel.flag, style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Text(
                                currentModel.name,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const Icon(Icons.arrow_drop_up_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                        itemBuilder: (BuildContext context) {
                          return LanguageService().supportedLanguages.map((lang) {
                            final isSelected = lang.code == currentLang;
                            return PopupMenuItem<String>(
                              value: lang.code,
                              child: Row(
                                children: [
                                  Text(lang.flag, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.name,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF59D6B6) : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const Spacer(),
                                    const Icon(Icons.check_rounded, color: Color(0xFF59D6B6), size: 16),
                                  ],
                                ],
                              ),
                            );
                          }).toList();
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(color: Color(0xFF1B3A5E)),
              const SizedBox(height: 18),
              Text(
                'WhatsApp : +${AppDataService().whatsAppNumber}',
                style: const TextStyle(color: Color(0xFF59D6B6), fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                LanguageService().t('footer_rights'),
                style: const TextStyle(color: Color(0xFFD9E8F8), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MOBILE DRAWER NAVIGATION
// ==========================================
class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.onNavigate,
    required this.onContact,
    required this.onAdminPortal,
  });

  final ValueChanged<String> onNavigate;
  final VoidCallback onContact;
  final VoidCallback onAdminPortal;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF061A2E),
      child: SafeArea(
        child: Column(
          children: [
            // Header with Logo, GM GROUP title and Close button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1B3A5E)),
                ),
              ),
              child: Row(
                children: [
                  const _HeroLogo(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GREAT MINDS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'GROUP',
                          style: TextStyle(
                            color: Color(0xFF59D6B6),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),

            // Language Selector Chips (Reactive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF0B253E),
              child: ListenableBuilder(
                listenable: LanguageService(),
                builder: (context, _) {
                  final currentLang = LanguageService().currentLanguage;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          'Langue / Language',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: LanguageService().supportedLanguages.map((lang) {
                            final isSelected = lang.code == currentLang;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(lang.flag, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Text(
                                      lang.name,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF061A2E) : Colors.white,
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF59D6B6),
                                backgroundColor: const Color(0xFF113C62),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF59D6B6)
                                      : Colors.white.withValues(alpha: 0.15),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (_) {
                                  LanguageService().setLanguage(lang.code);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  _drawerItem(
                    icon: Icons.home_rounded,
                    title: LanguageService().t('nav_home'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onNavigate('home');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.newspaper_rounded,
                    title: LanguageService().t('nav_publications'),
                    subtitle: LanguageService().t('drawer_news_subtitle'),
                    badge: LanguageService().t('nav_publications').toUpperCase(),
                    isAccent: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      onNavigate('news');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.work_rounded,
                    title: LanguageService().t('nav_offers'),
                    subtitle: LanguageService().t('drawer_offers_subtitle'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onNavigate('offers');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.business_center_rounded,
                    title: LanguageService().t('nav_activities'),
                    subtitle: LanguageService().t('drawer_services_subtitle'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onNavigate('services');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.domain_rounded,
                    title: LanguageService().t('nav_univers'),
                    subtitle: LanguageService().t('drawer_univers_subtitle'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onNavigate('univers');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.info_outline_rounded,
                    title: LanguageService().t('nav_about'),
                    subtitle: LanguageService().t('drawer_about_subtitle'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onNavigate('about');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.route_rounded,
                    title: LanguageService().t('nav_method'),
                    subtitle: LanguageService().t('drawer_method_subtitle'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onNavigate('method');
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFF1B3A5E)),
                  ),

                  // Actions in Drawer: Sync Data
                  ListenableBuilder(
                    listenable: AppDataService(),
                    builder: (context, _) {
                      final isSyncing = AppDataService().isSyncing;
                      return ListTile(
                        leading: isSyncing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF59D6B6),
                                ),
                              )
                            : const Icon(Icons.sync_rounded, color: Color(0xFF59D6B6), size: 22),
                        title: Text(
                          LanguageService().t('nav_sync_tooltip'),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          LanguageService().t('drawer_sync_subtitle'),
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        onTap: () async {
                          await AppDataService().syncData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService().t('nav_sync_success')),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),

                  // Admin Portal Tile
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentCyan, size: 22),
                    title: Text(
                      LanguageService().t('nav_admin'),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      LanguageService().t('drawer_admin_subtitle'),
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onAdminPortal();
                    },
                  ),
                ],
              ),
            ),

            // WhatsApp Contact Button at Bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF071E34),
                border: Border(top: BorderSide(color: Color(0xFF1B3A5E))),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onContact();
                      },
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: Text(LanguageService().t('contact_btn_chat')),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF59D6B6),
                        foregroundColor: const Color(0xFF061A2E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WhatsApp : +${AppDataService().whatsAppNumber}',
                    style: const TextStyle(color: Color(0xFF59D6B6), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    bool isAccent = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isAccent ? const Color(0xFF59D6B6).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isAccent
            ? Border.all(color: const Color(0xFF59D6B6).withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAccent
                ? const Color(0xFF59D6B6).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isAccent ? const Color(0xFF59D6B6) : Colors.white70,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isAccent ? const Color(0xFF59D6B6) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
        onTap: onTap,
      ),
    );
  }
}
