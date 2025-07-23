import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/email_card.dart';
import '../widgets/common_widgets.dart';
import '../providers/email_provider.dart';
import 'package:provider/provider.dart';

class EmailListScreen extends StatefulWidget {
  final String? emailAddress;

  const EmailListScreen({
    super.key,
    this.emailAddress,
  });

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.emailAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<EmailProvider>().fetchEmails(widget.emailAddress!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          widget.emailAddress ?? 'Emails',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              if (widget.emailAddress != null) {
                context.read<EmailProvider>().fetchEmails(widget.emailAddress!);
              }
            },
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.isLoading) {
            return const LoadingWidget(message: 'Loading emails...');
          }

          if (emailProvider.error != null) {
            return ErrorWidget(
              message: emailProvider.error!,
              onRetry: () {
                if (widget.emailAddress != null) {
                  emailProvider.fetchEmails(widget.emailAddress!);
                }
              },
            );
          }

          final emails = emailProvider.emails;

          if (emails.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Emails Yet',
              message: 'Your emails will appear here when they arrive.',
              icon: Icons.mail_outline,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (widget.emailAddress != null) {
                await emailProvider.fetchEmails(widget.emailAddress!);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: emails.length,
              itemBuilder: (context, index) {
                final email = emails[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EmailCard(
                    email: email,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/email-detail',
                        arguments: email,
                      );
                    },
                    onDelete: () {
                      emailProvider.deleteEmail(email.id);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}