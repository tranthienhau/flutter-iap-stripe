import 'package:flutter/material.dart';

import 'features/history/history_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/subscription/subscription_screen.dart';

/// Root application widget with bottom navigation
/// providing access to all major screens.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter IAP + Stripe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C63FF),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[50],
          foregroundColor: Colors.black87,
          centerTitle: true,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

/// Home shell with bottom navigation bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _screens = const [
    _HomeContent(),
    PaywallScreen(),
    SubscriptionScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_membership_outlined),
            selectedIcon: Icon(Icons.card_membership),
            label: 'Subscription',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

/// Home content screen showcasing the demo features.
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter IAP + Stripe'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeroCard(context),
          const SizedBox(height: 24),
          const Text(
            'Payment Integrations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            icon: Icons.apple,
            title: 'Apple IAP Subscriptions',
            description:
                'StoreKit 2 integration via in_app_purchase plugin. '
                'Supports monthly and yearly auto-renewable subscriptions.',
            color: Colors.black87,
          ),
          _buildFeatureCard(
            context,
            icon: Icons.shop,
            title: 'Google Play Billing',
            description:
                'Google Play Billing Library v6 support. '
                'Handles purchases, acknowledgment, and subscription state.',
            color: Colors.green,
          ),
          _buildFeatureCard(
            context,
            icon: Icons.payment,
            title: 'Apple Pay / Google Pay',
            description:
                'Native wallet payments via the pay plugin. '
                'One-tap checkout for frictionless user experience.',
            color: Colors.blue,
          ),
          _buildFeatureCard(
            context,
            icon: Icons.credit_card,
            title: 'Stripe Integration',
            description:
                'PaymentSheet and custom card entry. '
                'Server-side PaymentIntent creation, SCA-ready.',
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(height: 24),
          const Text(
            'Key Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFeatureChip('Receipt Validation'),
          _buildFeatureChip('Purchase Restoration'),
          _buildFeatureChip('Subscription Management'),
          _buildFeatureChip('Payment History'),
          _buildFeatureChip('Riverpod State Management'),
          _buildFeatureChip('Multi-Platform Support'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.payments, size: 40, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Payment Integration POC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Demonstrates production-ready patterns for in-app purchases, '
            'native wallets, and Stripe payment processing in Flutter.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBadge('Flutter'),
              const SizedBox(width: 8),
              _buildBadge('Riverpod'),
              const SizedBox(width: 8),
              _buildBadge('Stripe'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
