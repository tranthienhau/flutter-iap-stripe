/// The source of a purchase transaction.
enum PurchaseSource { appleIap, googlePlay, stripe, applePay, googlePay }

/// Status of a purchase.
enum PurchaseStatus { pending, completed, failed, refunded, cancelled }

/// Model representing a single purchase transaction record.
class PurchaseRecord {
  final String id;
  final String productId;
  final String productName;
  final double amount;
  final String currency;
  final PurchaseSource source;
  final PurchaseStatus status;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final String? transactionId;
  final String? receiptData;

  const PurchaseRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.amount,
    this.currency = 'USD',
    required this.source,
    required this.status,
    required this.purchaseDate,
    this.expiryDate,
    this.transactionId,
    this.receiptData,
  });

  bool get isActive {
    if (status != PurchaseStatus.completed) return false;
    if (expiryDate == null) return true;
    return expiryDate!.isAfter(DateTime.now());
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  String get sourceLabel {
    switch (source) {
      case PurchaseSource.appleIap:
        return 'Apple IAP';
      case PurchaseSource.googlePlay:
        return 'Google Play';
      case PurchaseSource.stripe:
        return 'Stripe';
      case PurchaseSource.applePay:
        return 'Apple Pay';
      case PurchaseSource.googlePay:
        return 'Google Pay';
    }
  }

  String get statusLabel {
    switch (status) {
      case PurchaseStatus.pending:
        return 'Pending';
      case PurchaseStatus.completed:
        return 'Completed';
      case PurchaseStatus.failed:
        return 'Failed';
      case PurchaseStatus.refunded:
        return 'Refunded';
      case PurchaseStatus.cancelled:
        return 'Cancelled';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'amount': amount,
      'currency': currency,
      'source': source.name,
      'status': status.name,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'transactionId': transactionId,
    };
  }

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      source: PurchaseSource.values.byName(json['source'] as String),
      status: PurchaseStatus.values.byName(json['status'] as String),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      transactionId: json['transactionId'] as String?,
    );
  }
}
