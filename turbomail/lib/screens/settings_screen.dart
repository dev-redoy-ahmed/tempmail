import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/email_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/stats_card.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool autoDeleteEnabled = false;
  int autoDeleteDays = 7;
  String selectedTheme = 'dark';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          Consumer<PremiumProvider>(
            builder: (context, premiumProvider, child) {
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        premiumProvider.isPremium ? Icons.star : Icons.person,
                        color: premiumProvider.isPremium ? Colors.amber : Colors.blue,
                      ),
                      title: Text(
                        premiumProvider.isPremium ? 'Premium Account' : 'Free Account',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        premiumProvider.isPremium 
                            ? 'Enjoy all premium features'
                            : 'Upgrade to unlock premium features',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: premiumProvider.isPremium
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                      onTap: () {
                        if (!premiumProvider.isPremium) {
                          Navigator.pushNamed(context, '/premium');
                        }
                      },
                    ),
                    if (!premiumProvider.isPremium)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/premium');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Upgrade to Premium'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Email Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'Get notified when new emails arrive',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Email Management Section
          _buildSectionHeader('Email Management'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Auto Delete Emails',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically delete emails after $autoDeleteDays days',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  value: autoDeleteEnabled,
                  onChanged: (value) {
                    setState(() {
                      autoDeleteEnabled = value;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                if (autoDeleteEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Text(
                          'Delete after: ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Expanded(
                          child: Slider(
                            value: autoDeleteDays.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: '$autoDeleteDays days',
                            onChanged: (value) {
                              setState(() {
                                autoDeleteDays = value.round();
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                        ),
                        Text(
                          '$autoDeleteDays days',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Clear All Emails',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'Delete all stored emails permanently',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    _showClearEmailsDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // App Settings Section
          _buildSectionHeader('App Settings'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette, color: Colors.purple),
                  title: const Text(
                    'Theme',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    selectedTheme == 'dark' ? 'Dark Theme' : 'Light Theme',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    _showThemeDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.green),
                  title: const Text(
                    'Language',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'English',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    // Language selection
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.blue),
                  title: const Text(
                    'App Version',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    '1.0.0',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.orange),
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    // Open privacy policy
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.teal),
                  title: const Text(
                    'Terms of Service',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    // Open terms of service
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.support, color: Colors.indigo),
                  title: const Text(
                    'Support',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    // Open support
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showClearEmailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Clear All Emails',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete all emails? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<EmailProvider>().clearAllEmails();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All emails cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Delete All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Select Theme',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text(
                  'Dark Theme',
                  style: TextStyle(color: Colors.white),
                ),
                value: 'dark',
                groupValue: selectedTheme,
                onChanged: (value) {
                  setState(() {
                    selectedTheme = value!;
                  });
                  Navigator.of(context).pop();
                },
                activeColor: Colors.blue,
              ),
              RadioListTile<String>(
                title: const Text(
                  'Light Theme',
                  style: TextStyle(color: Colors.white),
                ),
                value: 'light',
                groupValue: selectedTheme,
                onChanged: (value) {
                  setState(() {
                    selectedTheme = value!;
                  });
                  Navigator.of(context).pop();
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }
}