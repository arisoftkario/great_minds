class Subscriber {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String language;
  final DateTime subscribedAt;
  final bool isActive;

  const Subscriber({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.language = 'fr',
    required this.subscribedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'language': language,
        'subscribedAt': subscribedAt.toIso8601String(),
        'isActive': isActive,
      };

  factory Subscriber.fromJson(Map<String, dynamic> json) => Subscriber(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String?,
        phone: json['phone'] as String?,
        language: (json['language'] as String?) ?? 'fr',
        subscribedAt: DateTime.parse(json['subscribedAt'] as String),
        isActive: (json['isActive'] as bool?) ?? true,
      );

  Subscriber copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? language,
    DateTime? subscribedAt,
    bool? isActive,
  }) {
    return Subscriber(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
