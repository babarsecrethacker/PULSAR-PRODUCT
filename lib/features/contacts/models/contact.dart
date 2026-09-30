class Contact {
  final String id;
  final String name;
  final String lastMessage;
  final String lastSeen;
  final bool online;
  final bool typing;
  final int unread;
  final String? firebaseUid;

  const Contact({
    required this.id,
    required this.name,
    this.lastMessage = "",
    this.lastSeen = "",
    this.online = false,
    this.typing = false,
    this.unread = 0,
    this.firebaseUid,
  });

  factory Contact.fromLanUser(String username) {
    return Contact(
      id: username,
      name: username,
      lastMessage: "",
      lastSeen: "Online",
      online: true,
      typing: false,
      unread: 0,
    );
  }

  Contact copyWith({
    String? id,
    String? name,
    String? lastMessage,
    String? lastSeen,
    bool? online,
    bool? typing,
    int? unread,
    String? firebaseUid,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSeen: lastSeen ?? this.lastSeen,
      online: online ?? this.online,
      typing: typing ?? this.typing,
      unread: unread ?? this.unread,
      firebaseUid: firebaseUid ?? this.firebaseUid,
    );
  }
}