import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/offer_model.dart';
import '../../../services/app_data_service.dart';
import '../../../services/language_service.dart';

class OfferDetailDialog extends StatelessWidget {
  final Offer offer;

  const OfferDetailDialog({super.key, required this.offer});

  Future<void> _applyWhatsApp(BuildContext context) async {
    final whatsAppNumber = offer.customContactWhatsApp ?? AppDataService().whatsAppNumber;
    final message = 'Bonjour GREAT MINDS GROUP, je souhaite postuler / répondre à l’offre "${offer.title}" (${offer.department} - Réf: ${offer.id}).';
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
    final langService = LanguageService();
    final deadlineStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(offer.deadline);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer.department,
                      style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer.type,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (offer.isUrgent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.warningOrange),
                            const SizedBox(width: 6),
                            Text(
                              langService.t('offers_urgent_banner'),
                              style: const TextStyle(color: Color(0xFFC05600), fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Info Grid
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _infoItem(Icons.location_on_outlined, langService.t('offers_loc_label'), offer.location),
                          if (offer.salaryOrPrice != null)
                            _infoItem(Icons.monetization_on_outlined, langService.t('offers_price_label'), offer.salaryOrPrice!),
                          _infoItem(Icons.event_rounded, langService.t('offers_deadline_label'), deadlineStr),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Description
                    Text(langService.t('offers_desc_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    Text(
                      offer.description,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF334E68), height: 1.6),
                    ),
                    const SizedBox(height: 28),

                    // Requirements
                    if (offer.requirements.isNotEmpty) ...[
                      Text(langService.t('offers_reqs_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      ...offer.requirements.map(
                        (req) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.accentCyan, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(req, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Footer CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(langService.t('offers_close_btn')),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _applyWhatsApp(context),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: Text(langService.t('offers_apply_dialog_btn')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: AppTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.accentBlue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }
}
