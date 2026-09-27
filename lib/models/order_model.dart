class OrderItem {
  final String id;
  final String? publicationId;
  final String productTitle;
  final String department;
  final String unitPrice;
  final int quantity;
  final String totalAmount;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? city;
  final String deliveryAddress;
  final String paymentMethod; // 'mobile_money', 'card', 'cash_delivery', 'bank_transfer'
  final String status; // 'En attente', 'Confirmée', 'En cours de livraison', 'Livrée', 'Annulée'
  final String? notes;
  final DateTime createdAt;

  const OrderItem({
    required this.id,
    this.publicationId,
    required this.productTitle,
    required this.department,
    required this.unitPrice,
    this.quantity = 1,
    required this.totalAmount,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.city,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.status = 'En attente',
    this.notes,
    required this.createdAt,
  });

  String get reference {
    if (id.startsWith('cmd_')) {
      final sub = id.length > 10 ? id.substring(4, 10) : id.substring(4);
      return 'CMD-${sub.toUpperCase()}';
    }
    return 'CMD-${id.toUpperCase()}';
  }

  String get totalPrice => totalAmount;

  String get displayPaymentMethod {
    switch (paymentMethod) {
      case 'mobile_money':
        return 'Mobile Money (Orange / Wave / MTN / Moov / Airtel)';
      case 'card':
        return 'Carte Bancaire (Visa / Mastercard)';
      case 'cash_delivery':
        return 'Paiement Cash à la livraison';
      case 'bank_transfer':
        return 'Virement Bancaire';
      default:
        return paymentMethod;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicationId': publicationId,
        'productTitle': productTitle,
        'department': department,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'totalAmount': totalAmount,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'city': city,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'status': status,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        publicationId: json['publicationId'] as String?,
        productTitle: json['productTitle'] as String? ?? 'Produit GM GROUP',
        department: json['department'] as String? ?? 'Général',
        unitPrice: json['unitPrice'] as String? ?? '0',
        quantity: json['quantity'] as int? ?? 1,
        totalAmount: json['totalAmount'] as String? ?? '0',
        customerName: json['customerName'] as String? ?? 'Client',
        customerPhone: json['customerPhone'] as String? ?? '',
        customerEmail: json['customerEmail'] as String?,
        city: json['city'] as String?,
        deliveryAddress: json['deliveryAddress'] as String? ?? '',
        paymentMethod: json['paymentMethod'] as String? ?? 'mobile_money',
        status: json['status'] as String? ?? 'En attente',
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  OrderItem copyWith({
    String? id,
    String? publicationId,
    String? productTitle,
    String? department,
    String? unitPrice,
    int? quantity,
    String? totalAmount,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? city,
    String? deliveryAddress,
    String? paymentMethod,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      publicationId: publicationId ?? this.publicationId,
      productTitle: productTitle ?? this.productTitle,
      department: department ?? this.department,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      totalAmount: totalAmount ?? this.totalAmount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      city: city ?? this.city,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
