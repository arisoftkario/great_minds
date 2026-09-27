import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/publication_model.dart';
import '../common/app_image_viewer.dart';

class PublicationFormDialog extends StatefulWidget {
  final Publication? publication;

  const PublicationFormDialog({super.key, this.publication});

  @override
  State<PublicationFormDialog> createState() => _PublicationFormDialogState();
}

class _PublicationFormDialogState extends State<PublicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _contentController;
  late TextEditingController _authorController;
  late TextEditingController _tagsController;
  late TextEditingController _priceController;
  late TextEditingController _urlInputController;

  String _selectedCategory = 'Actualité';
  String _selectedDepartment = 'Toutes les activités';
  bool _isPublished = true;
  List<String> _images = [];
  bool _isLoadingImages = false;

  final List<String> _departments = [
    'Toutes les activités',
    'GM Formation & Emploi',
    'GM Parfum',
    'GM Texa',
    'GM Autosolution',
    'GM Fondation',
  ];

  final List<String> _categories = [
    'Actualité',
    'Événement',
    'Opportunité',
    'Conseil',
    'Success Story',
    'Communiqué',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.publication;
    _titleController = TextEditingController(text: p?.title ?? '');
    _summaryController = TextEditingController(text: p?.summary ?? '');
    _contentController = TextEditingController(text: p?.content ?? '');
    _authorController = TextEditingController(text: p?.author ?? 'Direction GM GROUP');
    _tagsController = TextEditingController(text: p?.tags.join(', ') ?? 'Formation, Emploi');
    _priceController = TextEditingController(text: p?.price ?? '');
    _urlInputController = TextEditingController();
    _selectedCategory = p?.category ?? 'Actualité';
    _selectedDepartment = p?.department ?? 'Toutes les activités';
    _isPublished = p?.isPublished ?? true;
    _images = List<String>.from(p?.allImages ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    _tagsController.dispose();
    _priceController.dispose();
    _urlInputController.dispose();
    super.dispose();
  }

  Future<void> _pickMultipleImages() async {
    setState(() => _isLoadingImages = true);
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.image,
      );

      if (files.isNotEmpty) {
        final newImages = <String>[];
        for (final file in files) {
          try {
            final Uint8List bytes = await file.readAsBytes();
            if (bytes.isNotEmpty) {
              final ext = file.name.split('.').last.toLowerCase();
              final mimeType = ext == 'png'
                  ? 'image/png'
                  : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
              final base64Str = base64Encode(bytes);
              final dataUrl = 'data:$mimeType;base64,$base64Str';
              newImages.add(dataUrl);
            }
          } catch (_) {}
        }
        if (newImages.isNotEmpty) {
          setState(() {
            _images.addAll(newImages);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l’importation des images: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingImages = false);
    }
  }

  void _addImageFromUrl() {
    final url = _urlInputController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _images.add(url);
        _urlInputController.clear();
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _setAsPrimaryImage(int index) {
    if (index > 0 && index < _images.length) {
      setState(() {
        final img = _images.removeAt(index);
        _images.insert(0, img);
      });
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final newPub = Publication(
        id: widget.publication?.id ?? 'pub_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        category: _selectedCategory,
        department: _selectedDepartment,
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        author: _authorController.text.trim(),
        imageUrl: _images.isNotEmpty ? _images.first : null,
        images: _images,
        publishedDate: widget.publication?.publishedDate ?? DateTime.now(),
        isPublished: _isPublished,
        tags: tags,
        price: _priceController.text.trim().isNotEmpty ? _priceController.text.trim() : null,
        viewsCount: widget.publication?.viewsCount ?? 0,
        likesCount: widget.publication?.likesCount ?? 0,
        followersCount: widget.publication?.followersCount ?? 0,
      );

      Navigator.of(context).pop(newPub);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.publication != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.article_rounded, color: AppTheme.accentCyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    isEdit ? 'Modifier la Publication' : 'Nouvelle Publication',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      const Text('Titre de la publication *', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Lancement des nouvelles sessions de mentorat...',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir un titre' : null,
                      ),
                      const SizedBox(height: 18),

                      // Prix / Tarif & Catégorie
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text('Prix / Tarif du produit', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                    SizedBox(width: 6),
                                    Text('(Optionnel)', style: TextStyle(fontSize: 12, color: Colors.black45)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _priceController,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: 25 000 FCFA, 45 \$, 15 000 GNF...',
                                    prefixIcon: const Icon(Icons.sell_rounded, color: AppTheme.accentGold, size: 20),
                                    helperText: 'Active le bouton "Se procurer" pour l\'achat en ligne',
                                    helperStyle: TextStyle(fontSize: 11, color: AppTheme.accentGold.withValues(alpha: 0.9)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Catégorie *', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategory = val);
                                  },
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.category_rounded, color: AppTheme.accentCyan, size: 20),
                                  ),
                                ),
                                const SizedBox(height: 20), // align with helperText
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Activité / Département & Statut
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Activité / Département *', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _departments.contains(_selectedDepartment) ? _selectedDepartment : _departments.first,
                                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedDepartment = val);
                                  },
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.business_center_rounded, color: AppTheme.accentBlue, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Statut de publication', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.borderSubtle),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _isPublished ? 'En ligne' : 'Brouillon',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _isPublished ? AppTheme.successGreen : AppTheme.warningOrange,
                                        ),
                                      ),
                                      const Spacer(),
                                      Switch(
                                        value: _isPublished,
                                        activeThumbColor: AppTheme.accentCyan,
                                        onChanged: (val) => setState(() => _isPublished = val),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Auteur / Responsable
                      const Text('Auteur / Responsable', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _authorController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Direction GM GROUP, Équipe GM Texa...',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // SECTION IMPORTATION PHOTOS (MULTIPLE)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.photo_library_rounded, color: AppTheme.accentBlue, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Photos de la publication',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 15),
                              ),
                              if (_images.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_images.length} photo${_images.length > 1 ? "s" : ""}',
                                    style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoadingImages ? null : _pickMultipleImages,
                            icon: _isLoadingImages
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.add_photo_alternate_rounded, size: 18),
                            label: const Text('Importer des photos (Multi-sélection)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentCyan,
                              foregroundColor: const Color(0xFF061A2E),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Galerie des images importées
                      if (_images.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Glissez ou cliquez sur l\'étoile pour définir la photo de couverture principale.',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: List.generate(_images.length, (index) {
                                  final img = _images[index];
                                  final isPrimary = index == 0;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isPrimary ? AppTheme.accentCyan : Colors.grey.shade300,
                                            width: isPrimary ? 2.5 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: AppImageViewer(
                                            imageSource: img,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      // Badge Couverture Principale
                                      if (isPrimary)
                                        Positioned(
                                          top: 6,
                                          left: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentCyan,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Couverture',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF061A2E)),
                                            ),
                                          ),
                                        ),
                                      // Boutons Actions (Supprimer & Définir principale)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!isPrimary)
                                              InkWell(
                                                onTap: () => _setAsPrimaryImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE5A93C)),
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade600,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Option d'ajout manuel par URL / Chemin Asset
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _urlInputController,
                              decoration: const InputDecoration(
                                hintText: 'Ou coller une URL d\'image / chemin (assets/Imag.jpeg)...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _addImageFromUrl,
                            icon: const Icon(Icons.add_link_rounded, size: 18),
                            label: const Text('Ajouter URL'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Résumé
                      const Text('Court résumé / Extrait *', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _summaryController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Une à deux phrases pour donner envie de lire...',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir un résumé' : null,
                      ),
                      const SizedBox(height: 18),

                      // Contenu
                      const Text('Contenu complet de l’article *', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Rédigez ici les détails, les étapes, les contacts et les modalités...',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir le contenu' : null,
                      ),
                      const SizedBox(height: 18),

                      // Tags
                      const Text('Mots-clés / Tags (séparés par des virgules)', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          hintText: 'Emploi, Jeunesse, Innovation',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(isEdit ? 'Mettre à jour' : 'Publier l’article'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
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
