import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'message.dart';

class ChatService with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final StreamController<double> _uploadProgressController = StreamController<double>();

  Stream<double> get uploadProgressStream => _uploadProgressController.stream;

  Future<void> sendMessage(String receiverId, String message, {Timestamp? scheduleTime}) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = scheduleTime ?? Timestamp.now();

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendImage(String receiverId) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final uploadTask = _uploadImageToFirebase(File(pickedFile.path));

      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
        _uploadProgressController.add(progress);
      });

      final imageUrl = await (await uploadTask).ref.getDownloadURL();
      if (imageUrl != null) {
        final String currentUserId = _firebaseAuth.currentUser!.uid;
        final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
        final Timestamp timestamp = Timestamp.now();

        Message newMessage = Message(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: receiverId,
          message: '', // Assuming the message is empty when sending an image
          imageUrl: imageUrl,
          timestamp: timestamp,
        );

        List<String> ids = [currentUserId, receiverId];
        ids.sort();
        String chatRoomId = ids.join("_");

        await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').add(newMessage.toMap());
      }
    }
  }

  Future<void> sendVideo(String receiverId) async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final uploadTask = _uploadVideoToFirebase(File(pickedFile.path));

      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
        _uploadProgressController.add(progress);
      });

      final videoUrl = await (await uploadTask).ref.getDownloadURL();
      if (videoUrl != null) {
        final String currentUserId = _firebaseAuth.currentUser!.uid;
        final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
        final Timestamp timestamp = Timestamp.now();

        Message newMessage = Message(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: receiverId,
          message: '', // Assuming the message is empty when sending a video
          videoUrl: videoUrl,
          timestamp: timestamp,
        );

        List<String> ids = [currentUserId, receiverId];
        ids.sort();
        String chatRoomId = ids.join("_");

        await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').add(newMessage.toMap());
      }
    }
  }

  UploadTask _uploadImageToFirebase(File file) {
    final ref = _firebaseStorage.ref().child('chat_images').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    return ref.putFile(file);
  }

  UploadTask _uploadVideoToFirebase(File file) {
    final ref = _firebaseStorage.ref().child('chat_videos').child('${DateTime.now().millisecondsSinceEpoch}.mp4');
    return ref.putFile(file);
  }

  Future<void> deleteMessage(String receiverId, String messageId) async {
    List<String> ids = [_firebaseAuth.currentUser!.uid, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').doc(messageId).delete();
  }

  // Add this function to your ChatService class
  Future<void> scheduleMessage(String receiverId, String message, DateTime scheduledTime) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.fromDate(scheduledTime);

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').add(newMessage.toMap());
  }





}
