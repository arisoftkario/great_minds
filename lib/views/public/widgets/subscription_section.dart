import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/subscriber_model.dart';
import '../../../services/app_data_service.dart';
import '../../../services/language_service.dart';

class SubscriptionSection extends StatefulWidget {
  const SubscriptionSection({super.key});

  @override
  State<SubscriptionSection> createState() => _SubscriptionSectionState();
}

class _SubscriptionSectionState extends State<SubscriptionSection> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitSubscription(String lang) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'fr'
                ? 'Veuillez entrer une adresse email valide.'
                : 'Please enter a valid email address.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final subscriber = Subscriber(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      language: lang,
      subscribedAt: DateTime.now(),
    );

    final success = await AppDataService().addSubscriber(subscriber);

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        _emailController.clear();
        _nameController.clear();
        _phoneController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang == 'fr'
                        ? '🎉 Félicitations ! Vous êtes désormais abonné(e) à Great Minds Group.'
                        : '🎉 Congratulations! You are now subscribed to Great Minds Group.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'fr'
                  ? 'ℹ️ Cette adresse email est déjà inscrite dans notre communauté.'
                  : 'ℹ️ This email address is already subscribed.',
            ),
            backgroundColor: const Color(0xFF3B82F6),
          ),
        );
      }
    }
  }

  void _shareOnWhatsApp(String text, String url) async {
    final encoded = Uri.encodeComponent('$text\n$url');
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareOnFacebook(String url) async {
    final uri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareOnLinkedIn(String url) async {
    final uri = Uri.parse('https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(url)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareOnX(String text, String url) async {
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(url)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyLink(String url, String lang) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang == 'fr' ? '🔗 Lien copié dans le presse-papier !' : '🔗 Link copied to clipboard!',
        ),
        backgroundColor: AppTheme.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService(),
      builder: (context, _) {
        final lang = LanguageService().currentLanguage;
        final siteUrl = 'https://arisoftkario.github.io/great_minds/';
        final shareMessage = lang == 'fr'
            ? 'Découvrez GREAT MINDS GROUP — Formations professionnelles certifiantes, offres d’emploi et opportunités !'
            : 'Discover GREAT MINDS GROUP — Professional certified training, job offers and empowerment!';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2744), Color(0xFF07192C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 750;

                    final leftCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mark_email_read_outlined, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Text(
                                lang == 'fr' ? 'COMMUNAUTÉ & OPPORTUNITÉS' : 'COMMUNITY & OPPORTUNITIES',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang == 'fr'
                              ? 'Ne manquez aucune opportunité ni bourse de formation'
                              : 'Never miss any job opportunity or training scholarship',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lang == 'fr'
                              ? 'Rejoignez notre réseau de plus de 2000 abonnés. Recevez en direct nos offres d\'emploi, bourses et actualités exclusives.'
                              : 'Join our network of over 2000 subscribers. Receive real-time job openings, scholarships and exclusive updates.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Social Share Shortcuts
                        Text(
                          lang == 'fr' ? 'Partager avec vos proches :' : 'Share with your network:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildShareChip(
                              icon: Icons.chat,
                              label: 'WhatsApp',
                              color: const Color(0xFF25D366),
                              onTap: () => _shareOnWhatsApp(shareMessage, siteUrl),
                            ),
                            _buildShareChip(
                              icon: Icons.facebook,
                              label: 'Facebook',
                              color: const Color(0xFF1877F2),
                              onTap: () => _shareOnFacebook(siteUrl),
                            ),
                            _buildShareChip(
                              icon: Icons.business,
                              label: 'LinkedIn',
                              color: const Color(0xFF0A66C2),
                              onTap: () => _shareOnLinkedIn(siteUrl),
                            ),
                            _buildShareChip(
                              icon: Icons.alternate_email,
                              label: 'X (Twitter)',
                              color: const Color(0xFF38BDF8),
                              onTap: () => _shareOnX(shareMessage, siteUrl),
                            ),
                            _buildShareChip(
                              icon: Icons.link,
                              label: lang == 'fr' ? 'Copier le lien' : 'Copy link',
                              color: const Color(0xFF94A3B8),
                              onTap: () => _copyLink(siteUrl, lang),
                            ),
                          ],
                        ),
                      ],
                    );

                    final rightCol = Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'fr' ? 'S\'abonner gratuitement' : 'Subscribe for Free',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Email Field (Mandatory)
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
                              hintText: lang == 'fr' ? 'Adresse email (*obligatoire)' : 'Email address (*required)',
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Name Field (Optional)
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8), size: 20),
                              hintText: lang == 'fr' ? 'Nom complet (optionnel)' : 'Full Name (optional)',
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // WhatsApp / Phone Field (Optional)
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              prefixIcon: const Icon(Icons.phone_iphone, color: Color(0xFF94A3B8), size: 20),
                              hintText: lang == 'fr' ? 'Numéro WhatsApp (optionnel)' : 'WhatsApp Number (optional)',
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : () => _submitSubscription(lang),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.send_rounded, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          lang == 'fr' ? 'M\'abonner maintenant' : 'Subscribe Now',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 6),
                              Text(
                                lang == 'fr'
                                    ? 'Vos données sont protégées. Désabonnement à tout moment.'
                                    : 'Your data is protected. Unsubscribe anytime.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 5, child: leftCol),
                          const SizedBox(width: 36),
                          Expanded(flex: 4, child: rightCol),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          leftCol,
                          const SizedBox(height: 28),
                          rightCol,
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
