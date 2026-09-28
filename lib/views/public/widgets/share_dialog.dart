import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/publication_model.dart';
import '../../../services/app_data_service.dart';

class SharePublicationDialog extends StatefulWidget {
  final Publication publication;

  const SharePublicationDialog({
    super.key,
    required this.publication,
  });

  static Future<void> show(BuildContext context, Publication publication) {
    return showDialog<void>(
      context: context,
      builder: (context) => SharePublicationDialog(publication: publication),
    );
  }

  @override
  State<SharePublicationDialog> createState() => _SharePublicationDialogState();
}

class _SharePublicationDialogState extends State<SharePublicationDialog> {
  bool _copied = false;

  String get _siteUrl => 'https://arisoftkario.github.io/great_minds/';

  String get _shareText {
    final title = widget.publication.title;
    final dept = widget.publication.department;
    final priceStr = widget.publication.hasPrice ? ' | Prix : ${widget.publication.displayPrice}' : '';
    return '🌟 *$title* ($dept$priceStr)\n\n${widget.publication.summary}\n\n👉 Découvrez ce produit sur le site officiel de GREAT MINDS GROUP :\n$_siteUrl';
  }

  Future<void> _recordShare() async {
    await AppDataService().incrementPublicationShares(widget.publication.id);
  }

  Future<void> _launchShareUrl(String url) async {
    await _recordShare();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareToWhatsApp() async {
    final encodedText = Uri.encodeComponent(_shareText);
    await _launchShareUrl('https://api.whatsapp.com/send?text=$encodedText');
  }

  Future<void> _shareToFacebook() async {
    final encodedUrl = Uri.encodeComponent(_siteUrl);
    await _launchShareUrl('https://www.facebook.com/sharer/sharer.php?u=$encodedUrl');
  }

  Future<void> _shareToTwitter() async {
    final text = '🌟 ${widget.publication.title} - GREAT MINDS GROUP';
    final encodedText = Uri.encodeComponent(text);
    final encodedUrl = Uri.encodeComponent(_siteUrl);
    await _launchShareUrl('https://twitter.com/intent/tweet?text=$encodedText&url=$encodedUrl');
  }

  Future<void> _shareToLinkedIn() async {
    final encodedUrl = Uri.encodeComponent(_siteUrl);
    await _launchShareUrl('https://www.linkedin.com/sharing/share-offsite/?url=$encodedUrl');
  }

  Future<void> _shareToTelegram() async {
    final encodedText = Uri.encodeComponent(_shareText);
    final encodedUrl = Uri.encodeComponent(_siteUrl);
    await _launchShareUrl('https://t.me/share/url?url=$encodedUrl&text=$encodedText');
  }

  Future<void> _shareViaEmail() async {
    final subject = Uri.encodeComponent('${widget.publication.title} - GREAT MINDS GROUP');
    final body = Uri.encodeComponent(_shareText);
    await _launchShareUrl('mailto:?subject=$subject&body=$body');
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: '$_shareText\n$_siteUrl'));
    await _recordShare();
    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('✓ Lien et texte copiés dans le presse-papiers !'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pub = widget.publication;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: Color(0xFF047857),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Partager ce produit / publication',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Diffusez l’opportunité auprès de votre réseau',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.borderSubtle),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: const Icon(
                                Icons.article_rounded,
                                color: AppTheme.accentBlue,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentCyan.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          pub.department,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0C5645),
                                          ),
                                        ),
                                      ),
                                      if (pub.hasPrice) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            pub.displayPrice,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF047857),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    pub.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.share_rounded, size: 13, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${pub.sharesCount} partages enregistrés',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Partager directement sur :',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Social Buttons Grid
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildSocialButton(
                            icon: Icons.chat_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: _shareToWhatsApp,
                          ),
                          _buildSocialButton(
                            icon: Icons.facebook_rounded,
                            label: 'Facebook',
                            color: const Color(0xFF1877F2),
                            onTap: _shareToFacebook,
                          ),
                          _buildSocialButton(
                            icon: Icons.tag_rounded,
                            label: 'X (Twitter)',
                            color: const Color(0xFF0F1419),
                            onTap: _shareToTwitter,
                          ),
                          _buildSocialButton(
                            icon: Icons.work_outline_rounded,
                            label: 'LinkedIn',
                            color: const Color(0xFF0A66C2),
                            onTap: _shareToLinkedIn,
                          ),
                          _buildSocialButton(
                            icon: Icons.send_rounded,
                            label: 'Telegram',
                            color: const Color(0xFF229ED9),
                            onTap: _shareToTelegram,
                          ),
                          _buildSocialButton(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            color: const Color(0xFFEA4335),
                            onTap: _shareViaEmail,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Divider(color: AppTheme.borderSubtle),
                      const SizedBox(height: 14),

                      // Copy Link Section
                      const Text(
                        'Ou copier le lien direct :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 18, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _siteUrl,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _copyLink,
                              icon: Icon(
                                _copied ? Icons.check_rounded : Icons.copy_rounded,
                                size: 14,
                              ),
                              label: Text(
                                _copied ? 'Copié !' : 'Copier',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _copied ? const Color(0xFF10B981) : AppTheme.accentBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
