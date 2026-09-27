import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/offer_model.dart';
import '../../../services/app_data_service.dart';
import '../../../services/language_service.dart';
import 'offer_detail_dialog.dart';

class OffersSection extends StatefulWidget {
  const OffersSection({super.key});

  @override
  State<OffersSection> createState() => _OffersSectionState();
}

class _OffersSectionState extends State<OffersSection> {
  String _selectedDepartment = 'Tous';
  String _selectedType = 'Tous';

  void _openOfferDetail(Offer offer) {
    showDialog<void>(
      context: context,
      builder: (context) => OfferDetailDialog(offer: offer),
    );
  }

  Future<void> _quickApplyWhatsApp(Offer offer) async {
    final whatsAppNumber = offer.customContactWhatsApp ?? AppDataService().whatsAppNumber;
    final message = 'Bonjour GREAT MINDS GROUP, je souhaite postuler / obtenir plus d’informations pour l’offre "${offer.title}" (${offer.department}).';
    final uri = Uri.https('wa.me', '/$whatsAppNumber', {'text': message});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d’ouvrir WhatsApp. Contactez-nous au +$whatsAppNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = AppDataService();
    final langService = LanguageService();

    return ListenableBuilder(
      listenable: Listenable.merge([dataService, langService]),
      builder: (context, _) {
        final allOffers = dataService.activeOffers;
        final filteredOffers = allOffers.where((o) {
          final matchesDept = _selectedDepartment == 'Tous' || o.department == _selectedDepartment;
          final matchesType = _selectedType == 'Tous' || o.type == _selectedType;
          return matchesDept && matchesType;
        }).toList();

        final departments = ['Tous', ...allOffers.map((o) => o.department).toSet()];
        final types = ['Tous', ...allOffers.map((o) => o.type).toSet()];

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 90, 24, 90),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    langService.t('offers_section_badge'),
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    langService.t('offers_section_title'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    langService.t('offers_section_subtitle'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Filter Row
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAFD),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Department Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text(
                                langService.t('offers_filter_pole'),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              ...departments.map((dept) {
                                final isSelected = _selectedDepartment == dept;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(dept),
                                    selected: isSelected,
                                    selectedColor: AppTheme.primaryNavy,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: isSelected ? AppTheme.primaryNavy : AppTheme.borderSubtle),
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedDepartment = dept);
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Type Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text(
                                langService.t('offers_filter_type'),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              ...types.map((t) {
                                final isSelected = _selectedType == t;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    label: Text(t),
                                    selected: isSelected,
                                    selectedColor: AppTheme.accentCyan.withValues(alpha: 0.3),
                                    labelStyle: TextStyle(
                                      color: isSelected ? const Color(0xFF07473B) : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: isSelected ? AppTheme.accentCyan : AppTheme.borderSubtle),
                                    onSelected: (val) {
                                      setState(() => _selectedType = val ? t : 'Tous');
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Offers Cards List
                  if (filteredOffers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.work_off_rounded, size: 48, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            langService.t('offers_empty'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 800;
                        return Column(
                          children: filteredOffers.map((offer) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _buildOfferCard(offer, isCompact),
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
    );
  }

  Widget _buildOfferCard(Offer offer, bool isCompact) {
    final deadlineStr = DateFormat('dd/MM/yyyy').format(offer.deadline);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: offer.isUrgent ? const Color(0xFFFFB74D) : const Color(0xFFE2EBF4),
          width: offer.isUrgent ? 1.5 : 1,
        ),
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
          // Badges row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.department,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.type,
                  style: const TextStyle(color: Color(0xFF0C5645), fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              if (offer.isUrgent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFFE65100)),
                      const SizedBox(width: 2),
                      Text(langService.t('offers_urgent_badge'), style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w800, fontSize: 11)),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (!isCompact) ...[
                const Icon(Icons.event_rounded, size: 15, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text('${langService.t('offers_deadline_prefix')}$deadlineStr', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Title & Description
          Text(
            offer.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            offer.description,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),

          // Details row & Actions
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOfferMeta(offer),
                const SizedBox(height: 16),
                _buildOfferActions(offer),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildOfferMeta(offer)),
                _buildOfferActions(offer),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOfferMeta(Offer offer) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.accentBlue),
            const SizedBox(width: 4),
            Text(offer.location, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
        if (offer.salaryOrPrice != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_outlined, size: 16, color: AppTheme.accentCyan),
              const SizedBox(width: 4),
              Text(offer.salaryOrPrice!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
      ],
    );
  }

  Widget _buildOfferActions(Offer offer) {
    final langService = LanguageService();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => _openOfferDetail(offer),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(langService.t('offers_view_details')),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: () => _quickApplyWhatsApp(offer),
          icon: const Icon(Icons.chat_rounded, size: 16),
          label: Text(langService.t('offers_apply_whatsapp')),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }
}
