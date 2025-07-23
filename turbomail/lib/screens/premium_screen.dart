import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/premium_provider.dart';
import '../services/in_app_purchase_service.dart';
import '../utils/page_transitions.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? selectedPlan;

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A2434),
          appBar: AppBar(
            title: Row(
              children: [
                const Text(
                  'Premium',
                  style: TextStyle(color: Colors.white),
                ),
                if (premiumProvider.isPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: const Color(0xFF1A2434),
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              if (premiumProvider.isPremium)
                IconButton(
                  onPressed: () => _showRestoreDialog(context, premiumProvider),
                  icon: const Icon(Icons.restore, color: Color(0xFF00D4AA)),
                ),
            ],
          ),
          body: premiumProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00D4AA),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium Header
                      _buildPremiumHeader(premiumProvider),
                      const SizedBox(height: 32),

                      // Premium Features
                      _buildFeaturesSection(),
                      const SizedBox(height: 32),

                      // Pricing Plans
                      _buildPricingSection(premiumProvider),
                      const SizedBox(height: 32),

                      // Action Buttons
                      _buildActionButtons(context, premiumProvider),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPremiumHeader(PremiumProvider premiumProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: premiumProvider.isPremium 
              ? [const Color(0xFF00D4AA), const Color(0xFF1DB584)]
              : [const Color(0xFF00D4AA), const Color(0xFF1DB584)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              premiumProvider.isPremium ? Icons.verified : Icons.star,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            premiumProvider.isPremium ? 'Premium Active' : 'TurboMail Premium',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            premiumProvider.isPremium 
                ? 'You are enjoying all premium features'
                : 'Unlock advanced features and enhanced experience',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          if (premiumProvider.isPremium && premiumProvider.activePlan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Current Plan: ${premiumProvider.getPlanDisplayName(premiumProvider.activePlan)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Premium Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.email_outlined,
          title: 'Unlimited Emails',
          description: 'Create unlimited temporary email addresses',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.schedule,
          title: 'Extended Duration',
          description: 'Keep emails active for up to 30 days',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.security,
          title: 'Enhanced Security',
          description: 'Advanced encryption and privacy protection',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.support_agent,
          title: 'Priority Support',
          description: '24/7 premium customer support',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.block,
          title: 'Ad-Free Experience',
          description: 'Enjoy TurboMail without any advertisements',
        ),
      ],
    );
  }

  Widget _buildPricingSection(PremiumProvider premiumProvider) {
    if (premiumProvider.isPremium) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2434),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00D4AA),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'re all set!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enjoy all premium features',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          productId: InAppPurchaseService.monthlyProductId,
          title: 'Monthly',
          price: premiumProvider.getPlanPrice(InAppPurchaseService.monthlyProductId),
          period: '/month',
          features: [
            'All Premium Features',
            'Cancel Anytime',
            'Instant Activation',
          ],
          premiumProvider: premiumProvider,
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          productId: InAppPurchaseService.threeMonthProductId,
          title: '3 Months',
          price: premiumProvider.getPlanPrice(InAppPurchaseService.threeMonthProductId),
          period: '/3 months',
          features: [
            'All Premium Features',
            'Save 10%',
            'Better Value',
          ],
          premiumProvider: premiumProvider,
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          productId: InAppPurchaseService.sixMonthProductId,
          title: '6 Months',
          price: premiumProvider.getPlanPrice(InAppPurchaseService.sixMonthProductId),
          period: '/6 months',
          features: [
            'All Premium Features',
            'Save 20%',
            'Great Value',
          ],
          premiumProvider: premiumProvider,
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          productId: InAppPurchaseService.yearlyProductId,
          title: 'Yearly',
          price: premiumProvider.getPlanPrice(InAppPurchaseService.yearlyProductId),
          period: '/year',
          features: [
            'All Premium Features',
            'Save 33%',
            'Best Value',
          ],
          isPopular: true,
          premiumProvider: premiumProvider,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PremiumProvider premiumProvider) {
    if (premiumProvider.isPremium) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => premiumProvider.restorePurchases(),
              icon: const Icon(Icons.restore),
              label: const Text(
                'Restore Purchases',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (selectedPlan != null) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: premiumProvider.purchaseService.purchasePending
                  ? null
                  : () => _purchaseSelectedPlan(premiumProvider),
              icon: premiumProvider.purchaseService.purchasePending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upgrade),
              label: Text(
                premiumProvider.purchaseService.purchasePending
                    ? 'Processing...'
                    : 'Subscribe Now',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => premiumProvider.restorePurchases(),
            icon: const Icon(Icons.restore, size: 20),
            label: const Text(
              'Restore Purchases',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00D4AA),
              side: const BorderSide(color: Color(0xFF00D4AA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00D4AA),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String productId,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required PremiumProvider premiumProvider,
    bool isPopular = false,
  }) {
    final isSelected = selectedPlan == productId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = productId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2434),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF00D4AA)
                : isPopular 
                    ? const Color(0xFF00D4AA) 
                    : const Color(0xFF00D4AA).withOpacity(0.3),
            width: isSelected ? 2 : (isPopular ? 2 : 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00D4AA),
                    size: 24,
                  ),
              ],
            ),
            if (isPopular) const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price.isNotEmpty ? price : 'Loading...',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00D4AA),
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF00D4AA),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _purchaseSelectedPlan(PremiumProvider premiumProvider) async {
    if (selectedPlan == null) return;
    
    try {
      await premiumProvider.purchasePlan(selectedPlan!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestoreDialog(BuildContext context, PremiumProvider premiumProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2434),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Restore Purchases',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will restore any previous purchases you made. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              premiumProvider.restorePurchases();
            },
            child: const Text(
              'Restore',
              style: TextStyle(color: Color(0xFF00D4AA)),
            ),
          ),
        ],
      ),
    );
  }
}