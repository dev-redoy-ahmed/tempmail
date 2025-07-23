import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turbomail/screens/premium_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/email_provider.dart';
import '../utils/page_transitions.dart';
import '../services/ads_service.dart';
import 'inbox_screen.dart';
import 'premium_screen.dart';
import 'custom_drawer.dart';
import 'email_history_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _closeDrawer() {
    setState(() {
      _isDrawerOpen = false;
    });
  }

  void _generateEmail() async {
    // Show interstitial ad before generating email
    await AdsService().showInterstitialAd();
    
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    await emailProvider.generateRandomEmail();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New email generated successfully!'),
          backgroundColor: const Color(0xFF00D4AA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _deleteEmail() {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    if (emailProvider.currentEmail != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A2434),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Email', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to delete this email address?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                emailProvider.clearCurrentEmail();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Email deleted successfully!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  void _showQRCode() {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    if (emailProvider.currentEmail != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A2434),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('QR Code', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(
                  data: emailProvider.currentEmail!,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emailProvider.currentEmail!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF00D4AA))),
            ),
          ],
        ),
      );
    }
  }

  void _showHistoryList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1C2E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: EmailHistoryPage(scrollController: scrollController),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1C2E),
      body: Stack(
        children: [
          // Main content
          Scaffold(
            backgroundColor: const Color(0xFF0F1C2E),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A2434),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _toggleDrawer,
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.email,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'TurboMail',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  onPressed: () {
                    context.slideToPage(
                      const PremiumScreen(),
                      direction: SlideDirection.leftToRight,
                      duration: const Duration(milliseconds: 350),
                    );
                  },
                ),
              ],
            ),
            body: Consumer<EmailProvider>(
              builder: (context, emailProvider, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 0),
                            _buildEmailDisplay(emailProvider),
                            const SizedBox(height: 15),
                            _buildButtonRows(emailProvider),
                            const SizedBox(height: 20),
                            _buildAdBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Custom Drawer
          CustomDrawer(
            isOpen: _isDrawerOpen,
            onClose: _closeDrawer,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailDisplay(EmailProvider emailProvider) {
    return Container(
      margin: const EdgeInsets.only(left: 0,right: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        //color: const Color(0xFF0D1723),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Temporary Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (emailProvider.currentEmail != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Email content area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00D49B), // turquoise green
                  Color(0xFF02B58B), // deep teal
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: emailProvider.currentEmail != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Email Address:',
                        style: TextStyle(
                          color: Color(0xFF1A2434),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 📩 Email Text Container
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1C2E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                emailProvider.currentEmail!,
                                style: const TextStyle(
                                  color: Color(0xFF00D4AA),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 📋 Copy Button Container
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: emailProvider.currentEmail!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Email copied to clipboard!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF00D4AA),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D49B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF0F1C2E),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.copy,
                                color: Color(0xFF0F1C2E),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Inbox: ${emailProvider.emails.length} messages',
                        style: const TextStyle(
                          color: Color(0xFF1A2434),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                : const Column(
                    children: [
                      Icon(
                        Icons.mail_outline,
                        color: Colors.white38,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No Active Email',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Generate a new email to get started',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  Widget _buildButtonRows(EmailProvider emailProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            title: 'Generate Email',
            icon: Icons.add_circle_outline,
            onTap: _generateEmail,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            title: 'Delete Email',
            icon: Icons.delete_outline,
            onTap: emailProvider.currentEmail != null ? _deleteEmail : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            title: 'History List',
            icon: Icons.history,
            onTap: _showHistoryList,
          ),
        ),
      ],
    );
  }

  Widget _buildAdBox() {
    return FutureBuilder<BannerAd?>(
      future: AdsService().loadBannerAd(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final bannerAd = snapshot.data!;
          return Container(
            width: double.infinity,
            height: bannerAd.size.height.toDouble(),
            margin: const EdgeInsets.all(16),
            child: AdWidget(ad: bannerAd),
          );
        } else {
          // Fallback placeholder
          return Container(
            width: double.infinity,
            height: 120,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D4AA).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.ads_click,
                  color: Color(0xFF00D4AA),
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Advertisement Space',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your ads could be here',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled 
                ? const Color(0xFF00D4AA).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled ? const Color(0xFF00D4AA) : Colors.white38,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}