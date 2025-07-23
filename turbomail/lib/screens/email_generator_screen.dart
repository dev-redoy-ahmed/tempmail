import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../providers/email_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/common_widgets.dart';
import 'package:provider/provider.dart';

class EmailGeneratorScreen extends StatefulWidget {
  const EmailGeneratorScreen({super.key});

  @override
  State<EmailGeneratorScreen> createState() => _EmailGeneratorScreenState();
}

class _EmailGeneratorScreenState extends State<EmailGeneratorScreen> {
  String? generatedEmail;
  bool isGenerating = false;
  List<Domain> availableDomains = [];

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  Future<void> _loadDomains() async {
    // Load available domains from API
    // For now, using default domains
    setState(() {
      availableDomains = [
        Domain(
          id: '1',
          name: 'tempmail.com',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        Domain(
          id: '2',
          name: 'quickmail.org',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        Domain(
          id: '3',
          name: 'fastmail.net',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];
    });
  }

  Future<void> _generateEmail() async {
    setState(() {
      isGenerating = true;
    });

    try {
      final emailProvider = context.read<EmailProvider>();
      final email = await emailProvider.generateEmail();
      
      setState(() {
        generatedEmail = email;
        isGenerating = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard() {
    if (generatedEmail != null) {
      Clipboard.setData(ClipboardData(text: generatedEmail!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email copied to clipboard!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'Generate Email',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Generate Temporary Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a temporary email address instantly',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Generated Email Display
            if (generatedEmail != null) ...[
              Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.blue.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.email,
                        color: Colors.blue,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your Temporary Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        generatedEmail!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/email-list',
                                arguments: generatedEmail,
                              );
                            },
                            icon: const Icon(Icons.inbox),
                            label: const Text('View Inbox'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Generate Button
            ElevatedButton(
              onPressed: isGenerating ? null : _generateEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Generating...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    )
                  : const Text(
                      'Generate New Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 30),

            // Available Domains
            const Text(
              'Available Domains',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: availableDomains.length,
                itemBuilder: (context, index) {
                  final domain = availableDomains[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.domain,
                        color: domain.isActive ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        domain.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        domain.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: domain.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      trailing: Icon(
                        domain.isActive ? Icons.check_circle : Icons.cancel,
                        color: domain.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Premium Features
            Consumer<PremiumProvider>(
              builder: (context, premiumProvider, child) {
                if (!premiumProvider.isPremium) {
                  return Card(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.withOpacity(0.1),
                            Colors.amber.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Get custom domains, longer email retention, and more!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/premium');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Upgrade Now'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}