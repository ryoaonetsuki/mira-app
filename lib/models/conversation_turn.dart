/// A single turn in the live conversation transcript.
class ConversationTurn {
  final String id;
  final bool isUser;
  String text;
  bool isInterim;
  final DateTime timestamp;

  ConversationTurn({
    required this.id,
    required this.isUser,
    required this.text,
    this.isInterim = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  ConversationTurn copyWith({
    String? text,
    bool? isInterim,
  }) {
    return ConversationTurn(
      id: id,
      isUser: isUser,
      text: text ?? this.text,
      isInterim: isInterim ?? this.isInterim,
      timestamp: timestamp,
    );
  }
}
