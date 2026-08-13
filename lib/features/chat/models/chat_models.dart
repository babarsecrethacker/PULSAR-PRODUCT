class ChatModel {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;

  ChatModel({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.online,
  });
}