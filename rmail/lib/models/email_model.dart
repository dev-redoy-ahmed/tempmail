class EmailModel {
  final String id;
  final String from;
  final dynamic to; // Can be String or List<String>
  final String subject;
  final String body;
  final String date;

  EmailModel({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.date,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) {
    return EmailModel(
      id: json['_id'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      subject: json['subject'] ?? '(no subject)',
      body: json['body'] ?? '',
      date: json['date'] ?? '',
    );
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