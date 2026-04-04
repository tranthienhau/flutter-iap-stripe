import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/subscription_plan.dart';
import '../paywall/paywall_screen.dart';
import 'subscription_provider.dart';

/// Screen showing the user's current subscription status
/// with options to upgrade, downgrade, or cancel.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionProvider);

    ref.listen<SubscriptionState>(subscriptionProvider, (prev, next) {
      if (next.message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message!)));
        ref.read(subscriptionProvider.notifier).clearMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Subscription'), elevation: 0),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(subscriptionProvider.notifier).loadSubscription(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStatusCard(context, state),
                  const SizedBox(height: 20),
                  if (state.activeSubscription != null) ...[
                    _buildDetailsCard(context, state),
                    const SizedBox(height: 20),
                    _buildActionsCard(context, ref, state),
                  ],
                  if (state.activeTier == SubscriptionTier.free) ...[
                    _buildUpgradePrompt(context),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionState state) {
    final isPremium = state.activeTier != SubscriptionTier.free;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFF6C63FF), const Color(0xFF3F3D9E)]
              : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? const Color(0xFF6C63FF) : Colors.grey)
                .withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPremium ? Icons.workspace_premium : Icons.person_outline,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? 'Premium Active' : 'Free Plan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPremium
                ? '${state.activeTier.name[0].toUpperCase()}${state.activeTier.name.substring(1)} subscription'
                : 'Upgrade to unlock all features',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, SubscriptionState state) {
    final sub = state.activeSubscription!;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _detailRow('Plan', sub.productName),
          _detailRow('Amount', '\$${sub.amount.toStringAsFixed(2)}'),
          _detailRow('Payment', sub.sourceLabel),
          _detailRow('Started', dateFormat.format(sub.purchaseDate)),
          if (sub.expiryDate != null)
            _detailRow('Renews', dateFormat.format(sub.expiryDate!)),
          _detailRow('Status', sub.statusLabel),
          if (sub.transactionId != null)
            _detailRow(
              'Transaction',
              sub.transactionId!.length > 20
                  ? '${sub.transactionId!.substring(0, 20)}...'
                  : sub.transactionId!,
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (state.activeTier == SubscriptionTier.monthly)
            _actionTile(
              icon: Icons.upgrade,
              title: 'Upgrade to Yearly',
              subtitle: 'Save 33% with annual billing',
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            ),
          _actionTile(
            icon: Icons.cancel_outlined,
            title: 'Cancel Subscription',
            subtitle: 'Switch back to the free plan',
            isDestructive: true,
            onTap: () => _showCancelDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : Colors.blue),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(51)),
      ),
      child: Column(
        children: [
          const Icon(Icons.rocket_launch, size: 40, color: Color(0xFF6C63FF)),
          const SizedBox(height: 12),
          const Text(
            'Unlock Premium Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Get unlimited access, no ads, offline downloads, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'You will lose access to premium features at the end of your '
          'current billing period. You can re-subscribe at any time.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(subscriptionProvider.notifier).cancelSubscription();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
