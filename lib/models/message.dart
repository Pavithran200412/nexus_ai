enum Sender { user, ai, system }

class Message {
  final String id;
  final Sender sender;
  final String text;
  final DateTime timestamp;
  final String? imageData;
  final bool isThinking;
  final Attachment? attachment;

  Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.imageData,
    this.isThinking = false,
    this.attachment,
  });
}

class Attachment {
  final AttachmentType type;
  final String data;
  final String fileName;
  final String mimeType;

  Attachment({
    required this.type,
    required this.data,
    required this.fileName,
    required this.mimeType,
  });
}

enum AttachmentType { image, file }