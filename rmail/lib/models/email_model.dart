class EmailModel {
  final String id;
  final String from;
  final dynamic to; // Can be String or List<String>
  final String subject;
  final String body;
  final String date;
  final String? raw; // Raw email content
  final Map<String, dynamic>? headers; // Email headers

  EmailModel({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.date,
    this.raw,
    this.headers,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) {
    // If raw email data is present, parse it
    if (json['raw'] != null) {
      final parsed = _parseRawEmail(json['raw']);
      return EmailModel(
        id: json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        from: json['from'] ?? parsed['from'] ?? '',
        to: json['to'] ?? parsed['to'] ?? '',
        subject: parsed['subject'] ?? '(no subject)',
        body: parsed['body'] ?? '',
        date: json['date'] ?? DateTime.now().toIso8601String(),
        raw: json['raw'],
        headers: json['headers'] ?? parsed['headers'],
      );
    }
    
    // Fallback to regular JSON parsing
    return EmailModel(
      id: json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      subject: json['subject'] ?? '(no subject)',
      body: json['body'] ?? '',
      date: json['date'] ?? DateTime.now().toIso8601String(),
      raw: json['raw'],
      headers: json['headers'],
    );
  }

  // Parse raw email content
  static Map<String, dynamic> _parseRawEmail(String rawEmail) {
    final lines = rawEmail.split('\n');
    final headers = <String, String>{};
    String subject = '';
    String from = '';
    String to = '';
    String body = '';
    bool inHeaders = true;
    bool inBody = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (inHeaders) {
        if (line.trim().isEmpty) {
          inHeaders = false;
          inBody = true;
          continue;
        }
        
        if (line.startsWith('Subject: ')) {
          subject = line.substring(9).trim();
          headers['subject'] = subject;
        } else if (line.startsWith('From: ')) {
          from = line.substring(6).trim();
          headers['from'] = from;
        } else if (line.startsWith('To: ')) {
          to = line.substring(4).trim();
          headers['to'] = to;
        } else if (line.contains(': ')) {
          final colonIndex = line.indexOf(': ');
          final key = line.substring(0, colonIndex).toLowerCase();
          final value = line.substring(colonIndex + 2);
          headers[key] = value;
        }
      } else if (inBody) {
        body += line + '\n';
      }
    }
    
    return {
      'subject': subject,
      'from': from,
      'to': to,
      'body': body.trim(),
      'headers': headers,
    };
  }

  String get toAddress {
    if (to is List) {
      return (to as List).join(', ');
    }
    return to.toString();
  }

  DateTime get parsedDate {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }
}