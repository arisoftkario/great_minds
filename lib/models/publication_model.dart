class PublicationComment {
  final String id;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const PublicationComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PublicationComment.fromJson(Map<String, dynamic> json) =>
      PublicationComment(
        id: json['id'] as String,
        authorName: (json['authorName'] as String?) ?? 'Visiteur',
        content: (json['content'] as String?) ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class Publication {
  final String id;
  final String title;
  final String category; // 'Actualité', 'Événement', 'Opportunité', 'Conseil', 'Success Story'
  final String department; // 'Toutes les activités', 'GM Formation & Emploi', 'GM Parfum', 'GM Texa', 'GM Autosolution', 'GM Fondation'
  final String summary;
  final String content;
  final String author;
  final String? price; // Ex: '25 000 FCFA', '50 USD', '15 000 FCFA', 'Sur devis'
  final String? imageUrl;
  final List<String> images;
  final DateTime publishedDate;
  final bool isPublished; // true = Publié, false = Brouillon
  final List<String> tags;
  final int viewsCount;
  final int likesCount;
  final int followersCount;
  final List<PublicationComment> comments;

  const Publication({
    required this.id,
    required this.title,
    required this.category,
    this.department = 'Toutes les activités',
    required this.summary,
    required this.content,
    required this.author,
    this.price,
    this.imageUrl,
    this.images = const [],
    required this.publishedDate,
    this.isPublished = true,
    this.tags = const [],
    this.viewsCount = 0,
    this.likesCount = 0,
    this.followersCount = 0,
    this.comments = const [],
  });

  /// Retourne le prix formaté ou un texte par défaut
  String get displayPrice => (price != null && price!.trim().isNotEmpty) ? price!.trim() : 'Sur devis';

  /// Indique si la publication a un prix défini
  bool get hasPrice => price != null && price!.trim().isNotEmpty;

  /// Retourne la liste complète des images (inclut imageUrl si non vide)
  List<String> get allImages {
    final list = <String>[];
    if (images.isNotEmpty) {
      list.addAll(images);
    } else if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      list.add(imageUrl!.trim());
    }
    return list;
  }

  /// Image principale
  String? get primaryImage => allImages.isNotEmpty ? allImages.first : imageUrl;

  Publication copyWith({
    String? id,
    String? title,
    String? category,
    String? department,
    String? summary,
    String? content,
    String? author,
    String? price,
    String? imageUrl,
    List<String>? images,
    DateTime? publishedDate,
    bool? isPublished,
    List<String>? tags,
    int? viewsCount,
    int? likesCount,
    int? followersCount,
    List<PublicationComment>? comments,
  }) {
    return Publication(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      department: department ?? this.department,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      author: author ?? this.author,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      publishedDate: publishedDate ?? this.publishedDate,
      isPublished: isPublished ?? this.isPublished,
      tags: tags ?? this.tags,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      followersCount: followersCount ?? this.followersCount,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'department': department,
      'summary': summary,
      'content': content,
      'author': author,
      'price': price,
      'imageUrl': primaryImage,
      'images': images,
      'publishedDate': publishedDate.toIso8601String(),
      'isPublished': isPublished,
      'tags': tags,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'followersCount': followersCount,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  factory Publication.fromJson(Map<String, dynamic> json) {
    final parsedImages = (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    final mainImage = json['imageUrl'] as String?;
    if (parsedImages.isEmpty && mainImage != null && mainImage.isNotEmpty) {
      parsedImages.add(mainImage);
    }

    final parsedComments = (json['comments'] as List<dynamic>?)
            ?.map((c) => PublicationComment.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    return Publication(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'Actualité',
      department: json['department'] as String? ?? 'Toutes les activités',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? 'Direction GM GROUP',
      price: json['price'] as String?,
      imageUrl: mainImage ?? (parsedImages.isNotEmpty ? parsedImages.first : null),
      images: parsedImages,
      publishedDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      isPublished: json['isPublished'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      viewsCount: json['viewsCount'] as int? ?? 0,
      likesCount: json['likesCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      comments: parsedComments,
    );
  }
}
