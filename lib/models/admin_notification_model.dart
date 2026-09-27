class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'subscription', 'like', 'offer_apply', 'contact'
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'data': data,
      };

  factory AdminNotification.fromJson(Map<String, dynamic> json) =>
      AdminNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        type: (json['type'] as String?) ?? 'subscription',
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: (json['isRead'] as bool?) ?? false,
        data: json['data'] as Map<String, dynamic>?,
      );

  AdminNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AdminNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}
