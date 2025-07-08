import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';

class SavedEmailsScreen extends StatelessWidget {
  const SavedEmailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Emails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<EmailProvider>().refreshDeviceEmails();
            },
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (emailProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emailProvider.error!,
                    style: TextStyle(color: Colors.red[300]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => emailProvider.refreshDeviceEmails(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final generatedEmails = emailProvider.generatedEmails;
          final currentEmail = emailProvider.currentEmail;
          final stats = emailProvider.getEmailStats();

          if (generatedEmails.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No generated emails yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Generate emails to see them here',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Stats Card
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Generated', stats['generated'].toString()),
                      _buildStatItem('Received', stats['received'].toString()),
                      _buildStatItem('Total', stats['total'].toString()),
                    ],
                  ),
                ),
              ),
              // Email List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: generatedEmails.length,
                  itemBuilder: (context, index) {
                    final emailData = generatedEmails[index];
                    final email = emailData['email'] as String;
                    final isCurrentEmail = email == emailProvider.currentEmail;
                    
                    return _SavedEmailTile(
                      email: email,
                      emailData: emailData,
                      isCurrentEmail: isCurrentEmail,
                      onTap: () {
                        emailProvider.switchToEmail(email);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to $email'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onDelete: () {
                        _showDeleteConfirmation(context, emailData['_id'], emailData, emailProvider);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Saved Emails',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate your first email to get started.\nAll generated emails will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to generate screen
                DefaultTabController.of(context)?.animateTo(1);
              },
              icon: const Icon(Icons.add),
              label: const Text('Generate Email'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, String emailId, Map<String, dynamic> emailData, EmailProvider emailProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this email?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                emailData['email'] as String,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                  emailProvider.deleteDeviceEmail(emailId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email deleted'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _SavedEmailTile extends StatelessWidget {
  final String email;
  final Map<String, dynamic> emailData;
  final bool isCurrentEmail;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedEmailTile({
    required this.email,
    required this.emailData,
    required this.isCurrentEmail,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(emailData['createdAt']);
    final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentEmail ? 4 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrentEmail
                ? Theme.of(context).colorScheme.secondary
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isCurrentEmail ? Icons.star : Icons.email,
            color: isCurrentEmail ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          email,
          style: TextStyle(
            fontWeight: isCurrentEmail ? FontWeight.w600 : FontWeight.normal,
            color: isCurrentEmail
                ? Theme.of(context).colorScheme.secondary
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentEmail ? 'Current Email' : _extractDomain(email),
              style: TextStyle(
                color: isCurrentEmail
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.grey[600],
                fontSize: 12,
                fontWeight: isCurrentEmail ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            Text(
              'Created: $formattedDate',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCurrentEmail)
              IconButton(
                icon: const Icon(Icons.star_border, size: 20),
                onPressed: onTap,
                tooltip: 'Set as current',
              ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: emailData['email'] as String));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Copy email',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete email',
            ),
          ],
        ),
        onTap: isCurrentEmail ? null : onTap,
      ),
    );
  }

  String _extractDomain(String email) {
    final parts = email.split('@');
    return parts.length > 1 ? '@${parts[1]}' : '';
  }
}