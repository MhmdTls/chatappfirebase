const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();

    // Get the receiver's FCM token
    const userRef = admin.firestore().collection('users').doc(message.receiverId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.log('No such user!');
      return null;
    }

    const fcmToken = userDoc.data().fcmToken;

    if (fcmToken) {
      // Send notification via Glitch endpoint
      try {
        const response = await axios.post('https://your-glitch-app.glitch.me/send_notification', {
          user_id: message.receiverId,
          message: message.message,
        });
        console.log('Notification sent successfully:', response.data);
      } catch (error) {
        console.error('Error sending notification:', error);
      }
    } else {
      console.log('No FCM token for user:', message.receiverId);
    }

    return null;
  });
