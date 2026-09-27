import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/publication_model.dart';
import '../../../services/app_data_service.dart';
import '../../../services/language_service.dart';
import '../../common/app_image_viewer.dart';

class PublicationDetailDialog extends StatefulWidget {
  final Publication publication;

  const PublicationDetailDialog({super.key, required this.publication});

  @override
  State<PublicationDetailDialog> createState() => _PublicationDetailDialogState();
}

class _PublicationDetailDialogState extends State<PublicationDetailDialog> {
  int _selectedImageIndex = 0;

  Future<void> _shareWhatsApp(BuildContext context) async {
    final whatsAppNumber = AppDataService().whatsAppNumber;
    final message =
        'Bonjour GREAT MINDS GROUP, j’ai lu votre article "${widget.publication.title}" et j’aimerais en savoir plus.';
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
    final dataService = AppDataService();
    final langService = LanguageService();
    return ListenableBuilder(
      listenable: Listenable.merge([dataService, langService]),
      builder: (context, _) {
        // Obtenir la publication à jour depuis le service
        final publication = dataService.publications.firstWhere(
          (p) => p.id == widget.publication.id,
          orElse: () => widget.publication,
        );
        final allImages = publication.allImages;
        final dateStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(publication.publishedDate);
        final isLiked = dataService.isPublicationLiked(publication.id);
        final isFollowed = dataService.isPublicationFollowed(publication.id);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780, maxHeight: 880),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business_center_rounded, size: 14, color: AppTheme.accentCyan),
                            const SizedBox(width: 6),
                            Text(
                              publication.department,
                              style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          publication.category,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
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

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Galerie / Affichage Photos
                        if (allImages.isNotEmpty) ...[
                          // Photo active agrandie
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  height: 280,
                                  width: double.infinity,
                                  child: AppImageViewer(
                                    imageSource: allImages[_selectedImageIndex.clamp(0, allImages.length - 1)],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (allImages.length > 1)
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Photo ${_selectedImageIndex + 1} / ${allImages.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Vignettes miniatures si plusieurs photos
                          if (allImages.length > 1) ...[
                            SizedBox(
                              height: 70,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: allImages.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final isSelected = index == _selectedImageIndex;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedImageIndex = index),
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.accentCyan : Colors.grey.shade300,
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: AppImageViewer(
                                          imageSource: allImages[index],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],

                        Text(
                          publication.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Stats & Metadata Row (Auteur, Date, Vues, Likes, Followers)
                        Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(publication.author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(dateStr, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.remove_red_eye_outlined, size: 15, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text('${publication.viewsCount} ${langService.t('pubs_reads')}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_rounded, size: 15, color: Color(0xFFE53935)),
                                const SizedBox(width: 6),
                                Text('${publication.likesCount} ${langService.t('pubs_likes')}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF00897B)),
                                const SizedBox(width: 6),
                                Text('${publication.followersCount} ${langService.t('pubs_followers')}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.borderSubtle),
                        const SizedBox(height: 20),

                        // Highlight summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(left: BorderSide(color: AppTheme.accentBlue, width: 4)),
                          ),
                          child: Text(
                            publication.summary,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Main Content Text
                        Text(
                          publication.content,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2C435A),
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Tags
                        if (publication.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: publication.tags
                                .map(
                                  (tag) => Chip(
                                    label: Text('#$tag', style: const TextStyle(fontSize: 12, color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
                                    backgroundColor: const Color(0xFFEAF3FB),
                                    side: BorderSide.none,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Interactive Engagement Bar (Like + Follow inside Dialog)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              // Like Action Button
                              ElevatedButton.icon(
                                onPressed: () => dataService.toggleLikePublication(publication.id),
                                icon: Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: isLiked ? Colors.white : const Color(0xFFE53935),
                                ),
                                label: Text(
                                  isLiked
                                      ? '${langService.t('pubs_liked')} (${publication.likesCount})'
                                      : '${langService.t('pubs_like')} (${publication.likesCount})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isLiked ? Colors.white : const Color(0xFFE53935),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLiked ? const Color(0xFFE53935) : Colors.white,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: const Color(0xFFE53935).withValues(alpha: isLiked ? 1 : 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Follow Action Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  final wasFollowed = isFollowed;
                                  dataService.toggleFollowPublication(publication.id);
                                  if (!wasFollowed && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(langService.t('pubs_follow_success')),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                  }
                                },
                                icon: Icon(
                                  isFollowed ? Icons.check_circle_rounded : Icons.person_add_alt_1_rounded,
                                  size: 18,
                                  color: isFollowed ? Colors.white : const Color(0xFF00897B),
                                ),
                                label: Text(
                                  isFollowed
                                      ? '${langService.t('pubs_following')} (${publication.followersCount})'
                                      : '${langService.t('pubs_follow')} (${publication.followersCount})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isFollowed ? Colors.white : const Color(0xFF00897B),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowed ? const Color(0xFF00897B) : Colors.white,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: const Color(0xFF00897B).withValues(alpha: isFollowed ? 1 : 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      Text(
                        langService.t('pubs_question_cta'),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _shareWhatsApp(context),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: Text(langService.t('pubs_chat_btn')),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentCyan,
                          foregroundColor: AppTheme.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
