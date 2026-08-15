const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

// New post -> notify everyone subscribed to that university's topic
exports.onBroadcastCreate = onDocumentCreated("broadcasts/{id}", async (event) => {
  const d = event.data.data();
  const topic = `uni_${d.universityShortName.replace(/[^a-zA-Z0-9]/g, "_")}`;
  await admin.messaging().send({
    topic,
    notification: {title: d.title, body: d.body},
    data: {postId: d.postId, type: "new_post"},
    android: {notification: {channelId: "high_importance_channel"}},
  });
});

// New chat message -> notify the OTHER participant (not the sender) by token
exports.onMessageCreate = onDocumentCreated(
  "chats/{chatId}/messages/{msgId}",
  async (event) => {
    const m = event.data.data();
    const chatId = event.params.chatId;

    const chatSnap = await admin.firestore().collection("chats").doc(chatId).get();
    const participants = chatSnap.data()?.participants || [];
    const recipientUid = participants.find((uid) => uid !== m.senderId);
    if (!recipientUid) return;

    const recipientDoc = await admin.firestore().collection("users").doc(recipientUid).get();
    const token = recipientDoc.data()?.fcmToken;
    if (!token) return;

    const senderDoc = await admin.firestore().collection("users").doc(m.senderId).get();
    const senderName = senderDoc.data()?.name || "New message";

    await admin.messaging().send({
      token,
      notification: {
        title: senderName,
        body: m.text && m.text.length > 0 ? m.text : "📷 Photo",
      },
      data: {chatId, type: "new_message"},
      android: {notification: {channelId: "high_importance_channel"}},
    });
  }
);