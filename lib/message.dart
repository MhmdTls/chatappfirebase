import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final String? imageUrl; // Optional image URL
  final String? videoUrl; // Optional video URL
  final Timestamp timestamp;
  final bool isRead; // New field to track if the message is read

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    this.imageUrl, // Optional parameter for image URL
    this.videoUrl, // Optional parameter for video URL
    required this.timestamp,
    this.isRead = false, // Initialize isRead to false
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'imageUrl': imageUrl, // Include image URL in the map
      'videoUrl': videoUrl, // Include video URL in the map
      'timestamp': timestamp,
      'isRead': isRead, // Include isRead in the map
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      message: map['message'],
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      timestamp: map['timestamp'],
      isRead: map['isRead'],
    );
  }
}
