import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/publication_model.dart';
import 'app_image_viewer.dart';

class AppVideoPlayer extends StatelessWidget {
  final Publication publication;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showControls;

  const AppVideoPlayer({
    super.key,
    required this.publication,
    this.height = 300,
    this.borderRadius,
    this.showControls = true,
  });

  Future<void> _launchVideo(BuildContext context) async {
    final videoUrl = publication.videoUrl?.trim();
    if (videoUrl == null || videoUrl.isEmpty) return;

    final uri = Uri.tryParse(videoUrl);
    if (uri != null) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir la vidéo : $videoUrl'),
              backgroundColor: const Color(0xFFC0392B),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!publication.hasVideo) return const SizedBox.shrink();

    final isYouTube = publication.youtubeVideoId != null;
    final thumbnail = publication.videoThumbnail ?? publication.primaryImage;
    final rRadius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: rRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: rRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Miniature vidéo
            AppImageViewer(
              imageSource: thumbnail,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: const Color(0xFF071424),
                child: const Center(
                  child: Icon(Icons.videocam_rounded, color: Colors.white30, size: 64),
                ),
              ),
            ),

            // Gradient sombre pour faire ressortir le bouton lecture et les textes
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Badge Plateforme (YouTube / Vidéo HD)
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isYouTube ? const Color(0xFFFF0000) : AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isYouTube ? Icons.play_circle_fill_rounded : Icons.videocam_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isYouTube ? 'YOUTUBE VIDÉO' : 'VIDÉO HD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton de lecture central avec animation pulsée
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchVideo(context),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isYouTube
                          ? const Color(0xFFFF0000).withValues(alpha: 0.95)
                          : AppTheme.accentCyan.withValues(alpha: 0.95),
                      boxShadow: [
                        BoxShadow(
                          color: (isYouTube ? const Color(0xFFFF0000) : AppTheme.accentCyan)
                              .withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 42,
                      color: isYouTube ? Colors.white : const Color(0xFF071424),
                    ),
                  ),
                ),
              ),
            ),

            // Barre d'informations & Action en bas
            if (showControls)
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            publication.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Cliquez pour regarder la vidéo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => _launchVideo(context),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('Lire la vidéo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      style: FilledButton.styleFrom(
                        backgroundColor: isYouTube ? const Color(0xFFFF0000) : AppTheme.accentCyan,
                        foregroundColor: isYouTube ? Colors.white : const Color(0xFF071424),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
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
}
