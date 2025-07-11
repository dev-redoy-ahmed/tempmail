import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/email_provider.dart';
import '../models/email_model.dart';
import 'email_detail_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Inbox'),
            const SizedBox(width: 8),
            Consumer<EmailProvider>(
              builder: (context, emailProvider, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: emailProvider.isSocketConnected ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          Consumer<EmailProvider>(
            builder: (context, emailProvider, child) {
              return IconButton(
                icon: emailProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: null, // Refresh removed - emails are real-time via socket
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final emailProvider = Provider.of<EmailProvider>(context, listen: false);
              if (value == 'delete_all') {
                emailProvider.clearEmails();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.currentEmail == null) {
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
                    'No email selected',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Generate or select an email to view inbox',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          if (emailProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${emailProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      emailProvider.clearError();
                      // Note: Refresh removed - emails are real-time via socket
                    },
                    child: const Text('Clear Error'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Current email display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Email:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            emailProvider.currentEmail!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            // Copy to clipboard functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Emails list
              Expanded(
                child: emailProvider.emails.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mail_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No emails yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Emails will appear here when received',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {}, // Refresh removed - emails are real-time via socket
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: emailProvider.emails.length,
                          itemBuilder: (context, index) {
                            final email = emailProvider.emails[index];
                            return _EmailTile(
                              email: email,
                              index: index,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmailDetailScreen(
                                      email: email,
                                      index: index,
                                    ),
                                  ),
                                );
                              },
                              onDelete: () {
                                _showDeleteDialog(context, emailProvider, index);
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, EmailProvider emailProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Emails'),
        content: const Text('Are you sure you want to delete all emails? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              emailProvider.clearEmails();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, EmailProvider emailProvider, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Email'),
        content: const Text('Are you sure you want to delete this email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              emailProvider.removeEmail(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmailTile extends StatelessWidget {
  final EmailModel email;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EmailTile({
    required this.email,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            email.from.isNotEmpty ? email.from[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          email.subject,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'From: ${email.from}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              email.body.isNotEmpty ? email.body : '(no content)',
              style: const TextStyle(
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (email.raw != null && email.raw!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.code,
                          size: 12,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'RAW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  dateFormat.format(email.parsedDate),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}