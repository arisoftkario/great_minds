import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/publication_model.dart';
import '../../../services/app_data_service.dart';
import '../../../services/language_service.dart';
import '../../common/app_image_viewer.dart';
import 'publication_detail_dialog.dart';

class PublicationsSection extends StatefulWidget {
  final void Function(String department)? onOpenDepartment;

  const PublicationsSection({super.key, this.onOpenDepartment});

  @override
  State<PublicationsSection> createState() => _PublicationsSectionState();
}

class _PublicationsSectionState extends State<PublicationsSection> {
  String _selectedCategory = 'Tous';
  String _selectedDepartment = 'Tous';

  void _openPublicationDetail(Publication pub) {
    AppDataService().incrementPublicationViews(pub.id);
    showDialog<void>(
      context: context,
      builder: (context) => PublicationDetailDialog(
        publication: pub,
        onOpenDepartment: widget.onOpenDepartment,
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
        final allPubs = dataService.publishedPublications;
        final filteredPubs = allPubs.where((p) {
          final matchCat = _selectedCategory == 'Tous' || p.category == _selectedCategory;
          final matchDept = _selectedDepartment == 'Tous' || p.department == _selectedDepartment;
          return matchCat && matchDept;
        }).toList();

        final departments = [
          'Tous',
          'Toutes les activités',
          'GM Formation & Emploi',
          'GM Parfum',
          'GM Texa',
          'GM Autosolution',
          'GM Fondation',
        ];

        final categories = ['Tous', ...allPubs.map((p) => p.category).toSet()];

        return Container(
          color: const Color(0xFFF9FBFF),
          padding: const EdgeInsets.fromLTRB(24, 90, 24, 90),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Text(
                    langService.t('pubs_section_badge'),
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    langService.t('pubs_section_title'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    langService.t('pubs_section_subtitle'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Department Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: departments.map((dept) {
                        final isSelected = _selectedDepartment == dept;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(dept),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryNavy,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryNavy
                                  : AppTheme.borderSubtle,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedDepartment = dept);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: AppTheme.accentBlue,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFFEFF5FC),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.accentBlue
                                  : Colors.transparent,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = cat);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Publications Grid
                  if (filteredPubs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.newspaper_rounded,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            langService.t('pubs_empty'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 780;
                        final isMedium = constraints.maxWidth < 1100;
                        final columns = isCompact ? 1 : (isMedium ? 2 : 3);
                        final itemWidth =
                            (constraints.maxWidth - (18 * (columns - 1))) /
                            columns;

                        return Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: filteredPubs.map((pub) {
                            return SizedBox(
                              width: itemWidth,
                              child: _buildPublicationCard(pub),
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

  Widget _buildPublicationCard(Publication pub) {
    final dateStr = DateFormat(
      'dd MMM yyyy',
      'fr_FR',
    ).format(pub.publishedDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image with direct click to Department
          Tooltip(
            message: 'Toucher la photo pour voir tous les produits du département ${pub.department}',
            child: InkWell(
              onTap: () {
                if (widget.onOpenDepartment != null) {
                  widget.onOpenDepartment!(pub.department);
                } else {
                  _openPublicationDetail(pub);
                }
              },
              child: Stack(
                children: [
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: AppImageViewer(
                      imageSource: pub.primaryImage,
                      fit: BoxFit.cover,
                      errorWidget: _buildCardImagePlaceholder(pub),
                    ),
                  ),
                  // Overlay badge "Voir tous les produits du département"
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 12, color: AppTheme.accentCyan),
                          const SizedBox(width: 4),
                          Text(
                            'Voir département ${pub.department} ➔',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (pub.allImages.length > 1)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${pub.allImages.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (widget.onOpenDepartment != null) {
                          widget.onOpenDepartment!(pub.department);
                        } else {
                          _openPublicationDetail(pub);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business_center_rounded, size: 12, color: Color(0xFF0C5645)),
                            const SizedBox(width: 4),
                            Text(
                              pub.department,
                              style: const TextStyle(
                                color: Color(0xFF0C5645),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pub.category,
                        style: const TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  pub.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  pub.summary,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pub.author,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppTheme.borderSubtle, height: 1),
                const SizedBox(height: 12),

                // Interactive Likes, Followers, Comments & Details Row
                Row(
                  children: [
                    // Like button
                    _buildLikeButton(pub),
                    const SizedBox(width: 6),
                    // Comment button
                    _buildCommentButton(pub),
                    const SizedBox(width: 6),
                    // Follow button
                    _buildFollowButton(pub),
                    const Spacer(),
                    // Read more button
                    TextButton.icon(
                      onPressed: () => _openPublicationDetail(pub),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                      label: Text(LanguageService().t('pubs_read_more')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
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

  Widget _buildLikeButton(Publication pub) {
    final isLiked = AppDataService().isPublicationLiked(pub.id);
    return Tooltip(
      message: isLiked ? LanguageService().t('pubs_liked') : LanguageService().t('pubs_like'),
      child: InkWell(
        onTap: () {
          AppDataService().toggleLikePublication(pub.id);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isLiked ? const Color(0xFFFFEBEE) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLiked ? const Color(0xFFE53935).withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: isLiked ? const Color(0xFFE53935) : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                '${pub.likesCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLiked ? const Color(0xFFE53935) : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentButton(Publication pub) {
    return Tooltip(
      message: 'Commentaires & avis (${pub.comments.length})',
      child: InkWell(
        onTap: () => _openPublicationDetail(pub),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: Color(0xFF1B7AE6),
              ),
              const SizedBox(width: 5),
              Text(
                '${pub.comments.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B7AE6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(Publication pub) {
    final isFollowed = AppDataService().isPublicationFollowed(pub.id);
    return Tooltip(
      message: isFollowed ? LanguageService().t('pubs_following') : LanguageService().t('pubs_follow'),
      child: InkWell(
        onTap: () {
          final wasFollowed = isFollowed;
          AppDataService().toggleFollowPublication(pub.id);
          if (!wasFollowed && mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF59D6B6), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(LanguageService().t('pubs_follow_success'))),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isFollowed ? const Color(0xFFE6F8F3) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFollowed ? const Color(0xFF00BFA5).withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFollowed ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
                size: 15,
                color: isFollowed ? const Color(0xFF00897B) : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                isFollowed
                    ? '${pub.followersCount} ${LanguageService().t('pubs_following')}'
                    : '+ ${LanguageService().t('pubs_follow')} (${pub.followersCount})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isFollowed ? const Color(0xFF00897B) : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImagePlaceholder(Publication pub) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C2C4D), Color(0xFF1E5285)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.article_rounded,
          size: 48,
          color: AppTheme.accentCyan.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
