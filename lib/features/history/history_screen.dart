import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_record.dart';
import '../paywall/paywall_provider.dart';

/// Provider for purchase history.
final purchaseHistoryProvider = FutureProvider<List<PurchaseRecord>>((ref) {
  final manager = ref.watch(subscriptionManagerProvider);
  return manager.getPurchaseHistory();
});

/// Screen displaying the user's complete payment history
/// with transaction details and status.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(purchaseHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History'), elevation: 0),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading history: $err')),
        data: (history) => history.isEmpty
            ? _buildEmptyState()
            : _buildHistoryList(context, history),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<PurchaseRecord> history) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Group by month
    final grouped = <String, List<PurchaseRecord>>{};
    for (final record in history) {
      final key = DateFormat('MMMM yyyy').format(record.purchaseDate);
      grouped.putIfAbsent(key, () => []).add(record);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, sectionIndex) {
        final month = grouped.keys.elementAt(sectionIndex);
        final records = grouped[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ...records.map(
              (record) =>
                  _buildRecordCard(context, record, dateFormat, timeFormat),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    PurchaseRecord record,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showDetailSheet(context, record, dateFormat),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getStatusColor(record.status).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSourceIcon(record.source),
                      color: _getStatusColor(record.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.sourceLabel} - '
                          '${dateFormat.format(record.purchaseDate)} at '
                          '${timeFormat.format(record.purchaseDate)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${record.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(record.status).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record.statusLabel,
                          style: TextStyle(
                            color: _getStatusColor(record.status),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSourceIcon(PurchaseSource source) {
    switch (source) {
      case PurchaseSource.appleIap:
        return Icons.apple;
      case PurchaseSource.googlePlay:
        return Icons.shop;
      case PurchaseSource.stripe:
        return Icons.credit_card;
      case PurchaseSource.applePay:
        return Icons.apple;
      case PurchaseSource.googlePay:
        return Icons.g_mobiledata;
    }
  }

  Color _getStatusColor(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.completed:
        return Colors.green;
      case PurchaseStatus.pending:
        return Colors.orange;
      case PurchaseStatus.failed:
        return Colors.red;
      case PurchaseStatus.refunded:
        return Colors.blue;
      case PurchaseStatus.cancelled:
        return Colors.grey;
    }
  }

  void _showDetailSheet(
    BuildContext context,
    PurchaseRecord record,
    DateFormat dateFormat,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Transaction Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _detailRow('Product', record.productName),
            _detailRow(
              'Amount',
              '\$${record.amount.toStringAsFixed(2)} ${record.currency}',
            ),
            _detailRow('Payment', record.sourceLabel),
            _detailRow('Status', record.statusLabel),
            _detailRow('Date', dateFormat.format(record.purchaseDate)),
            if (record.expiryDate != null)
              _detailRow('Expires', dateFormat.format(record.expiryDate!)),
            if (record.transactionId != null)
              _detailRow('Transaction ID', record.transactionId!),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
