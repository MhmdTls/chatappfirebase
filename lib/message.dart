import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final String? imageUrl; // Optional image URL
  final String? videoUrl; // Optional video URL
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    this.imageUrl, // Optional parameter for image URL
    this.videoUrl, // Optional parameter for video URL
    required this.timestamp,
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
    };
  }
}
