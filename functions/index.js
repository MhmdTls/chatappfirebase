const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    const receiverUserID = messageData.receiverUserID;

    // Fetch the receiver's FCM token from Firestore
    const userDoc = await admin.firestore().collection('users').doc(receiverUserID).get();
    const fcmToken = userDoc.data().fcmToken;

    const payload = {
      notification: {
        title: 'New Message',
        body: messageData.message || 'You have received a new message.',
        sound: 'default',
      },
    };

    if (fcmToken) {
      await admin.messaging().sendToDevice(fcmToken, payload);
    }
  });
