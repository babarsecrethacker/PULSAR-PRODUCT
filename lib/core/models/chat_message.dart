import 'dart:convert';

enum MessageStatus {
  pending,    // Clock icon - sending
  sent,       // Single gray tick - sent to server
  delivered,  // Double gray tick - delivered to recipient
  read,       // Double blue tick - read by recipient
  failed,     // Exclamation mark - failed to send
}

class ChatMessage {
  final String id;
  final String from;
  final String to;
  final String message;
  final String? voiceBase64;
  final DateTime time;
  final MessageStatus status;

  /// The id the composer minted before the message was sent, echoed back
  /// by the server. Without it a locally "sending" bubble can never be
  /// matched to the stored copy, so its status would stay pending and
  /// the message would appear twice.
  final String? clientMessageId;

  ChatMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.message,
    required this.time,
    this.voiceBase64,
    this.status = MessageStatus.pending,
    this.clientMessageId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String statusStr = json["status"]?.toString() ?? "pending";
    MessageStatus status;
    switch (statusStr) {
      case "sent":
        status = MessageStatus.sent;
        break;
      case "delivered":
        status = MessageStatus.delivered;
        break;
      case "read":
        status = MessageStatus.read;
        break;
      case "failed":
        status = MessageStatus.failed;
        break;
      default:
        status = MessageStatus.pending;
    }

    return ChatMessage(
      id: json["id"]?.toString() ?? json["message_id"]?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case MessageStatus.pending:
        statusStr = "pending";
        break;
      case MessageStatus.sent:
        statusStr = "sent";
        break;
      case MessageStatus.delivered:
        statusStr = "delivered";
        break;
      case MessageStatus.read:
        statusStr = "read";
        break;
      case MessageStatus.failed:
        statusStr = "failed";
        break;
    }

    return {
      "type": "message",
      "id": id,
      "from": from,
      "to": to,
      "message": message,
      "audio": voiceBase64,
      "time": time.toIso8601String(),
      "status": statusStr,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? from,
    String? to,
    String? message,
    String? voiceBase64,
    DateTime? time,
    MessageStatus? status,
    String? clientMessageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      message: message ?? this.message,
      voiceBase64: voiceBase64 ?? this.voiceBase64,
      time: time ?? this.time,
      status: status ?? this.status,
      clientMessageId: clientMessageId ?? this.clientMessageId,
    );
  }

  String encode() {
    return jsonEncode(toJson());
  }

  @override
  String toString() {
    return "ChatMessage(id: $id, from: $from, to: $to, message: $message, status: $status)";
  }
}