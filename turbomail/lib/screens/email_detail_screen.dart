import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/email_model.dart';

class EmailDetailScreen extends StatefulWidget {
  final EmailModel email;

  const EmailDetailScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  bool _showHtmlContent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1C2E),
      body: Column(
        children: [
          _buildCustomAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmailHeader(),
                  const SizedBox(height: 20),
                  _buildContentToggle(),
                  const SizedBox(height: 16),
                  _buildEmailContent(),
                  if (widget.email.attachments.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildAttachmentsSection(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2434),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Email Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _shareEmail,
            icon: const Icon(
              Icons.share,
              color: Color(0xFF00D4AA),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Row(
            children: [
              const Icon(
                Icons.subject,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.email.subject.isNotEmpty ? widget.email.subject : 'No Subject',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // From
          _buildHeaderRow(
            icon: Icons.person,
            label: 'From',
            value: widget.email.from,
          ),
          
          const SizedBox(height: 12),
          
          // To
          _buildHeaderRow(
            icon: Icons.email,
            label: 'To',
            value: widget.email.to,
          ),
          
          const SizedBox(height: 12),
          
          // Date
          _buildHeaderRow(
            icon: Icons.access_time,
            label: 'Date',
            value: '${widget.email.formattedDate} • ${widget.email.timeAgo}',
          ),
          
          if (widget.email.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildHeaderRow(
              icon: Icons.attach_file,
              label: 'Attachments',
              value: '${widget.email.attachments.length} file${widget.email.attachments.length > 1 ? 's' : ''}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF00D4AA),
          size: 16,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentToggle() {
    if (widget.email.html.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showHtmlContent = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showHtmlContent 
                      ? const Color(0xFF00D4AA) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Text',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_showHtmlContent ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showHtmlContent = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showHtmlContent 
                      ? const Color(0xFF00D4AA) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rich Text',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _showHtmlContent ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _showHtmlContent ? Icons.code : Icons.text_fields,
                color: const Color(0xFF00D4AA),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _showHtmlContent ? 'Rich Content' : 'Message Content',
                style: const TextStyle(
                  color: Color(0xFF00D4AA),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _copyContent,
                icon: const Icon(
                  Icons.copy,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_showHtmlContent && widget.email.html.isNotEmpty)
            _buildHtmlContent()
          else
            _buildTextContent(),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    final content = widget.email.text.isNotEmpty 
        ? widget.email.text 
        : 'No message content';
        
    return SelectableText(
      content,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildHtmlContent() {
    return Html(
      data: widget.email.html,
      style: {
        "body": Style(
          color: Colors.white,
          fontSize: FontSize(14),
          lineHeight: const LineHeight(1.5),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "p": Style(
          color: Colors.white,
          margin: Margins.only(bottom: 8),
        ),
        "a": Style(
          color: const Color(0xFF00D4AA),
          textDecoration: TextDecoration.underline,
        ),
        "h1, h2, h3, h4, h5, h6": Style(
          color: const Color(0xFF00D4AA),
          fontWeight: FontWeight.bold,
        ),
        "strong, b": Style(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        "em, i": Style(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
        ),
        "ul, ol": Style(
          color: Colors.white,
          margin: Margins.only(left: 16, bottom: 8),
        ),
        "li": Style(
          color: Colors.white,
          margin: Margins.only(bottom: 4),
        ),
        "blockquote": Style(
          color: Colors.white70,
          backgroundColor: const Color(0xFF0F1C2E),
          padding: HtmlPaddings.all(12),
          margin: Margins.symmetric(vertical: 8),
          border: const Border(
            left: BorderSide(
              color: Color(0xFF00D4AA),
              width: 3,
            ),
          ),
        ),
        "code": Style(
          color: const Color(0xFF00D4AA),
          backgroundColor: const Color(0xFF0F1C2E),
          padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
          fontFamily: 'monospace',
        ),
        "pre": Style(
          color: Colors.white,
          backgroundColor: const Color(0xFF0F1C2E),
          padding: HtmlPaddings.all(12),
          margin: Margins.symmetric(vertical: 8),
          fontFamily: 'monospace',
        ),
      },
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.attach_file,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Attachments (${widget.email.attachments.length})',
                style: const TextStyle(
                  color: Color(0xFF00D4AA),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...widget.email.attachments.map((attachment) => 
            _buildAttachmentItem(attachment)
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(EmailAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(attachment.contentType),
              color: const Color(0xFF00D4AA),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.filename,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatFileSize(attachment.size)} • ${attachment.contentType}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _downloadAttachment(attachment),
            icon: const Icon(
              Icons.download,
              color: Color(0xFF00D4AA),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String contentType) {
    if (contentType.startsWith('image/')) {
      return Icons.image;
    } else if (contentType.startsWith('video/')) {
      return Icons.video_file;
    } else if (contentType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (contentType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (contentType.contains('word') || contentType.contains('document')) {
      return Icons.description;
    } else if (contentType.contains('excel') || contentType.contains('spreadsheet')) {
      return Icons.table_chart;
    } else if (contentType.contains('powerpoint') || contentType.contains('presentation')) {
      return Icons.slideshow;
    } else if (contentType.contains('zip') || contentType.contains('archive')) {
      return Icons.archive;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  void _copyContent() {
    final content = _showHtmlContent && widget.email.html.isNotEmpty
        ? widget.email.html
        : widget.email.text;
        
    Clipboard.setData(ClipboardData(text: content));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Content copied to clipboard'),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _shareEmail() {
    final content = '''
Subject: ${widget.email.subject.isNotEmpty ? widget.email.subject : 'No Subject'}
From: ${widget.email.from}
To: ${widget.email.to}
Date: ${widget.email.date}

${widget.email.text}
''';

    Clipboard.setData(ClipboardData(text: content));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email content copied to clipboard'),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _downloadAttachment(EmailAttachment attachment) {
    // TODO: Implement attachment download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download ${attachment.filename}'),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}