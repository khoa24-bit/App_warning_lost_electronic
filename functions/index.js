/* eslint-disable no-console */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Theo dõi thay đổi trên nút thiết bị trong Realtime Database
exports.notifyDeviceOffline = functions.database
    .ref("/devices/{deviceId}/status")
    .onUpdate(async (change, context) => {
      const before = change.before.val();
      const after = change.after.val();

      // Chỉ gửi thông báo nếu trạng thái đổi từ online -> offline
      if (before === "online" && after === "offline") {
        const deviceId = context.params.deviceId;

        // Lấy owner từ nhánh cha
        const snapshot = await change.after.ref.parent.once("value");
        const deviceData = snapshot.val();
        const ownerId = deviceData.owner;

        // Lấy FCM token từ Firestore: /users/{uid}/fcmToken
        const userDoc = await admin
            .firestore()
            .collection("users")
            .doc(ownerId)
            .get();
        const userData = userDoc.data();

        if (!userData || !userData.fcmToken) {
          console.log("Không tìm thấy FCM token của người dùng.");
          return null;
        }

        const payload = {
          notification: {
            title: "Thiết bị ngoại tuyến",
            body: `Thiết bị "${deviceData.name || deviceId}" đã mất kết nối.`,
          },
          token: userData.fcmToken,
        };

        try {
          await admin.messaging().send(payload);
          console.log("Đã gửi thông báo đến:", userData.fcmToken);
        } catch (error) {
          console.error("Lỗi khi gửi thông báo:", error);
        }
      }

      return null;
    });
