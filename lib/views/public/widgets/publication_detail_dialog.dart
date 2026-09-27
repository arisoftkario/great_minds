import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/publication_model.dart';
import '../../../services/app_data_service.dart';
import '../../../services/language_service.dart';
import '../../common/app_image_viewer.dart';
import 'order_checkout_dialog.dart';

class PublicationDetailDialog extends StatefulWidget {
  final Publication publication;
  final void Function(String department)? onOpenDepartment;

  const PublicationDetailDialog({
    super.key,
    required this.publication,
    this.onOpenDepartment,
  });

  @override
  State<PublicationDetailDialog> createState() => _PublicationDetailDialogState();
}

class _PublicationDetailDialogState extends State<PublicationDetailDialog> {
  int _selectedImageIndex = 0;
  final _commentAuthorController = TextEditingController();
  final _commentTextController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentAuthorController.dispose();
    _commentTextController.dispose();
    super.dispose();
  }

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

  void _submitComment(Publication pub) {
    final author = _commentAuthorController.text.trim();
    final text = _commentTextController.text.trim();

    if (author.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner votre nom et votre commentaire.'),
          backgroundColor: Color(0xFFC0392B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmittingComment = true);

    final newComment = PublicationComment(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      authorName: author,
      content: text,
      createdAt: DateTime.now(),
    );

    AppDataService().addCommentToPublication(pub.id, newComment);
    _commentTextController.clear();

    setState(() => _isSubmittingComment = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF59D6B6)),
            SizedBox(width: 8),
            Text('Merci ! Votre commentaire a été publié avec succès.'),
          ],
        ),
        backgroundColor: AppTheme.primaryNavy,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
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
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 900),
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
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onOpenDepartment?.call(publication.department);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
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
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.accentCyan),
                            ],
                          ),
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
                        // Galerie / Affichage Photos avec redirection au département lors du clic
                        if (allImages.isNotEmpty) ...[
                          Tooltip(
                            message: 'Toucher la photo pour visiter le département ${publication.department}',
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onOpenDepartment?.call(publication.department);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      height: 300,
                                      width: double.infinity,
                                      child: AppImageViewer(
                                        imageSource: allImages[_selectedImageIndex.clamp(0, allImages.length - 1)],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Badge "Explorer le département"
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryNavy.withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.storefront_rounded, size: 14, color: AppTheme.accentCyan),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Visiter le département ${publication.department} ➔',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                          ),
                                        ],
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
                            ),
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

                        // Interactive Department Discovery Banner
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onOpenDepartment?.call(publication.department);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEBF4FC), Color(0xFFE3F2FD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryNavy,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: AppTheme.accentCyan, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Département : ${publication.department}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryNavy),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Toucher ici pour voir tous les produits et services de ce département et faire votre choix.',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.accentBlue),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Prominent Price & "Se procurer" Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.sell_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Prix de l’article :',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      publication.displayPrice,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF064E3B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (_) => OrderCheckoutDialog(publication: publication),
                                  );
                                },
                                icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                                label: const Text(
                                  'Se procurer / Acheter',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF047857),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

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

                        // Stats & Metadata Row (Auteur, Date, Vues, Likes, Followers, Commentaires)
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF1B7AE6)),
                                const SizedBox(width: 6),
                                Text('${publication.comments.length} commentaire${publication.comments.length > 1 ? "s" : ""}', style: const TextStyle(fontSize: 13, color: Color(0xFF1B7AE6), fontWeight: FontWeight.w700)),
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
                        const SizedBox(height: 32),

                        // ==========================================
                        // SECTION COMMENTAIRES & AVIS DES VISITEURS
                        // ==========================================
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD3E2F4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B7AE6).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.forum_rounded, color: Color(0xFF1B7AE6), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Commentaires & Avis (${publication.comments.length})',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const Text(
                                          'Laissez votre avis ou posez une question sur ce produit / publication',
                                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Formulaire d'ajout de commentaire
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.borderSubtle),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _commentAuthorController,
                                      decoration: InputDecoration(
                                        labelText: 'Votre Nom ou Prénom *',
                                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.accentBlue),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFD),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFD0DFE8)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _commentTextController,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        labelText: 'Votre commentaire ou question sur ce produit... *',
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.only(bottom: 40),
                                          child: Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppTheme.accentBlue),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFD),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFD0DFE8)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed: _isSubmittingComment ? null : () => _submitComment(publication),
                                        icon: _isSubmittingComment
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Icon(Icons.send_rounded, size: 16),
                                        label: const Text('Publier mon commentaire', style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppTheme.primaryNavy,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Liste des commentaires existants
                              if (publication.comments.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.borderSubtle),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.mark_chat_unread_outlined, size: 36, color: AppTheme.textSecondary),
                                      SizedBox(height: 8),
                                      Text(
                                        'Aucun commentaire pour le moment.',
                                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Soyez le premier à donner votre avis sur cette publication !',
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: publication.comments.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    // Afficher du plus récent au plus ancien
                                    final comment = publication.comments[publication.comments.length - 1 - index];
                                    final commentDate = DateFormat('dd/MM/yyyy à HH:mm').format(comment.createdAt);

                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: AppTheme.primaryNavy,
                                            child: Text(
                                              comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : 'U',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      comment.authorName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 14,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                    ),
                                                    Text(
                                                      commentDate,
                                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  comment.content,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF2C435A),
                                                    height: 1.45,
                                                  ),
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
                      // Se procurer button in footer
                      FilledButton.icon(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => OrderCheckoutDialog(publication: publication),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag_rounded, size: 17),
                        label: const Text('Se procurer', style: TextStyle(fontWeight: FontWeight.w800)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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
