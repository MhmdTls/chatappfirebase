import 'package:cloud_firestore/cloud_firestore.dart';

class Counter {
  final String currentUserID;

  Counter({required this.currentUserID});

  Stream<int> getUnreadMessagesCount(String receiverUserID) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('senderID', isEqualTo: receiverUserID)
        .where('receiverID', isEqualTo: currentUserID)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
