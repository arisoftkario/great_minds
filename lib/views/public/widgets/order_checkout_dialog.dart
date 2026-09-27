import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../models/publication_model.dart';
import '../../../services/app_data_service.dart';
import '../../common/app_image_viewer.dart';

class OrderCheckoutDialog extends StatefulWidget {
  final Publication publication;

  const OrderCheckoutDialog({
    super.key,
    required this.publication,
  });

  @override
  State<OrderCheckoutDialog> createState() => _OrderCheckoutDialogState();
}

class _OrderCheckoutDialogState extends State<OrderCheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  int _quantity = 1;
  String _paymentMethod = 'mobile_money';
  bool _isSubmitting = false;
  OrderItem? _createdOrder;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _calculateTotalAmount() {
    final priceStr = widget.publication.price?.trim();
    if (priceStr == null || priceStr.isEmpty || priceStr.toLowerCase().contains('devis') || priceStr.toLowerCase().contains('gratuit')) {
      return widget.publication.displayPrice;
    }

    // Extraction de la valeur numérique si présente
    final numericRegex = RegExp(r'(\d+[\s\d]*)');
    final match = numericRegex.firstMatch(priceStr);
    if (match != null) {
      final cleanNumStr = match.group(1)!.replaceAll(' ', '');
      final parsedNum = int.tryParse(cleanNumStr);
      if (parsedNum != null) {
        final total = parsedNum * _quantity;
        // Remplacer le nombre original par le total calculé
        final formattedTotal = _formatThousands(total);
        return priceStr.replaceRange(match.start, match.end, formattedTotal);
      }
    }
    return '${_quantity}x $priceStr';
  }

  String _formatThousands(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final orderId = 'GM-CMD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final totalAmount = _calculateTotalAmount();

    final order = OrderItem(
      id: orderId,
      publicationId: widget.publication.id,
      productTitle: widget.publication.title,
      department: widget.publication.department,
      unitPrice: widget.publication.displayPrice,
      quantity: _quantity,
      totalAmount: totalAmount,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      deliveryAddress: _addressController.text.trim(),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: DateTime.now(),
    );

    await AppDataService().addOrder(order);

    setState(() {
      _isSubmitting = false;
      _createdOrder = order;
    });
  }

  Future<void> _openWhatsAppConfirmation(OrderItem order) async {
    final whatsAppNumber = AppDataService().whatsAppNumber;
    final message = '''*NOUVELLE COMMANDE GREAT MINDS GROUP* 🛍️
━━━━━━━━━━━━━━━━━━━━
📦 *Réf. Commande :* ${order.id}
📌 *Article :* ${order.productTitle}
🏢 *Département :* ${order.department}
🔢 *Quantité :* ${order.quantity}
💰 *Total :* ${order.totalAmount}
👤 *Client :* ${order.customerName}
📞 *Téléphone :* ${order.customerPhone}
📍 *Adresse :* ${order.deliveryAddress}
💳 *Mode de paiement :* ${_getPaymentMethodLabel(order.paymentMethod)}
${order.notes != null ? '📝 *Notes :* ${order.notes}\n' : ''}━━━━━━━━━━━━━━━━━━━━
Bonjour, je viens de passer cette commande sur votre site et je souhaite la finaliser.''';

    final uri = Uri.https('wa.me', '/$whatsAppNumber', {'text': message});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d’ouvrir WhatsApp. Contactez-nous au +$whatsAppNumber')),
        );
      }
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'mobile_money':
        return 'Mobile Money (M-Pesa, Airtel Money, Orange Money, Wave)';
      case 'card':
        return 'Carte Bancaire (Visa / Mastercard)';
      case 'cash_delivery':
        return 'Paiement à la livraison (Cash à la réception)';
      case 'bank_transfer':
        return 'Virement Bancaire';
      default:
        return 'Mobile Money';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 850),
        child: _createdOrder != null ? _buildSuccessView(_createdOrder!) : _buildOrderFormView(),
      ),
    );
  }

  Widget _buildOrderFormView() {
    final totalAmount = _calculateTotalAmount();

    return Column(
      children: [
        // Top Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: AppTheme.primaryNavy,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.accentCyan, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commander & Acheter en Ligne',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      'Remplissez vos informations pour vous procurer cet article',
                      style: TextStyle(color: Color(0xFFB9DDF5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Scrollable Form Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD3E2F4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: AppImageViewer(
                              imageSource: widget.publication.primaryImage,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                color: AppTheme.primaryNavy,
                                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.publication.department,
                                  style: const TextStyle(
                                    color: AppTheme.accentBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.publication.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Prix unitaire : ${widget.publication.displayPrice}',
                                  style: const TextStyle(
                                    color: Color(0xFF047857),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quantity Selector & Total
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantité :',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              color: AppTheme.primaryNavy,
                              iconSize: 22,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              color: AppTheme.primaryNavy,
                              iconSize: 22,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total estimé', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            Text(
                              totalAmount,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer Details Section Header
                  const Text(
                    'Vos Coordonnées de Livraison',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom et Prénom *',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.accentBlue),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD0DFE8)),
                      ),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Veuillez saisir votre nom complet' : null,
                  ),
                  const SizedBox(height: 12),

                  // Phone / WhatsApp Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Numéro de Téléphone / WhatsApp *',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.accentBlue),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD0DFE8)),
                      ),
                      hintText: '+243 ... / 081...',
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Veuillez saisir un numéro de téléphone valide' : null,
                  ),
                  const SizedBox(height: 12),

                  // Email Field (Optional)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Adresse Email (optionnel)',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.accentBlue),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD0DFE8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Delivery Address Field
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Ville, Commune et Adresse de livraison *',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.accentBlue),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD0DFE8)),
                      ),
                      hintText: 'Ex: Kinshasa, Gombe, Av. De la Paix...',
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Veuillez renseigner votre adresse de livraison' : null,
                  ),
                  const SizedBox(height: 12),

                  // Notes / Instructions Field
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notes ou précisions particulières (optionnel)',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Icon(Icons.note_alt_outlined, color: AppTheme.accentBlue),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD0DFE8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Method Section Header
                  const Text(
                    'Mode de Paiement Souhaité',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // Payment Method Options
                  _buildPaymentRadioTile(
                    value: 'mobile_money',
                    title: '📱 Mobile Money (Kinshasa & International)',
                    subtitle: 'Airtel Money, M-Pesa, Orange Money, Wave / Moov',
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentRadioTile(
                    value: 'cash_delivery',
                    title: '🚚 Paiement Cash à la Livraison',
                    subtitle: 'Payez en espèces directement lors de la réception de votre colis',
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentRadioTile(
                    value: 'card',
                    title: '💳 Carte Bancaire (Visa / Mastercard)',
                    subtitle: 'Paiement électronique sécurisé par carte',
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentRadioTile(
                    value: 'bank_transfer',
                    title: '🏦 Virement Bancaire',
                    subtitle: 'Coordonnées bancaires fournies après validation',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Footer Actions & Total Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total de votre commande', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  Text(
                    totalAmount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitOrder,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text(
                  'Valider la Commande',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRadioTile({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : AppTheme.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.accentBlue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.primaryNavy : AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(OrderItem order) {
    return Column(
      children: [
        // Success Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF047857),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 42),
              ),
              const SizedBox(height: 12),
              const Text(
                'Commande Enregistrée avec Succès ! 🎉',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Référence de commande : ${order.id}',
                style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        // Order Summary Details
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Récapitulatif de votre achat :',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Produit', order.productTitle),
                      const Divider(height: 16),
                      _buildSummaryRow('Département', order.department),
                      const Divider(height: 16),
                      _buildSummaryRow('Quantité', '${order.quantity} unité(s)'),
                      const Divider(height: 16),
                      _buildSummaryRow('Montant Total', order.totalAmount, isBold: true),
                      const Divider(height: 16),
                      _buildSummaryRow('Client', order.customerName),
                      const Divider(height: 16),
                      _buildSummaryRow('Téléphone', order.customerPhone),
                      const Divider(height: 16),
                      _buildSummaryRow('Livraison à', order.deliveryAddress),
                      const Divider(height: 16),
                      _buildSummaryRow('Mode de Paiement', _getPaymentMethodLabel(order.paymentMethod)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // WhatsApp Assistance Callout
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.support_agent_rounded, color: Color(0xFF2E7D32), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Un conseiller client GREAT MINDS GROUP a reçu votre commande et vous contactera rapidement pour organiser la livraison et le règlement.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fermer'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openWhatsAppConfirmation(order),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text(
                  'Finaliser & Suivre sur WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? const Color(0xFF047857) : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
