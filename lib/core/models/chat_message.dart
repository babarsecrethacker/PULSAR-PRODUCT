import 'dart:convert';

class ChatMessage {
  final String from;
  final String to;
  final String message;
  final String? voiceBase64;
  final DateTime time;

  ChatMessage({
  required this.from,
  required this.to,
  required this.message,
  required this.time,
  this.voiceBase64,
});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      from: json["from"] ?? "",
      to: json["to"] ?? "",
      message: json["message"] ?? "",
      voiceBase64: json["audio"],
      time: DateTime.tryParse(
            json["time"] ??
                json["timestamp"] ??
                DateTime.now().toIso8601String(),
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "type": "message",
      "from": from,
      "to": to,
      "message": message,
      "audio": voiceBase64,
      "time": time.toIso8601String(),
    };
  }

  String encode() {
    return jsonEncode(toJson());
  }

  @override
  String toString() {
    return "ChatMessage(from: $from, to: $to, message: $message)";
  }
}