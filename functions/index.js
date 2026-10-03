const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Triggers when a new document is created in the 'notifications' collection.
 * Delivers a real native Push Notification via APNs (iOS) and FCM (Android).
 */
exports.sendPushNotificationOnFirestoreCreate = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    region: "europe-west1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const data = snap.data();
    const userId = data.userId;
    const title = data.title || "CitySwim";
    const message = data.message || "";

    if (!userId) {
      console.log("No userId in notification document");
      return;
    }

    try {
      // 1. Fetch user document to find their FCM device token
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.log(`User ${userId} not found in Firestore`);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token registered for user ${userId}`);
        return;
      }

      // 2. Build cross-platform Push payload with full APNs priority
      const payload = {
        token: fcmToken,
        notification: {
          title: title,
          body: message,
        },
        data: {
          notificationId: String(event.params.notificationId || ""),
          type: String(data.type || "general"),
          actionType: String(data.actionType || ""),
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          payload: {
            aps: {
              alert: {
                title: title,
                body: message,
              },
              sound: "default",
              badge: 1,
              "content-available": 1,
            },
          },
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "high_importance_channel",
          },
        },
      };

      // 3. Send message through Firebase Cloud Messaging (APNs gateway)
      const response = await messaging.send(payload);
      console.log(`Push notification sent successfully to user ${userId}: ${response}`);
    } catch (error) {
      console.error(`Error sending push notification to user ${userId}:`, error);

      // If token is invalid or uninstalled, clean it up
      if (
        error.code === "messaging/registration-token-not-registered" ||
        error.code === "messaging/invalid-registration-token"
      ) {
        console.log(`Cleaning up invalid token for user ${userId}`);
        await db.collection("users").doc(userId).update({
          fcmToken: null,
          fcmTokenInvalidatedAt: new Date(),
        });
      }
    }
  }
);
