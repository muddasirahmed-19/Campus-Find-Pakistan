import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.surface),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.chats)
          .where('participants', arrayContains: uid)
          .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                      size: 72, color: AppColors.border),
                    const SizedBox(height: 20),
                    Text('No conversations yet',
                      style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Start a chat by tapping Contact on a post.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final chats = docs.toList()
            ..sort((a, b) {
              final aT = (a.data() as Map)['lastMessageAt'] as String? ?? '';
              final bT = (b.data() as Map)['lastMessageAt'] as String? ?? '';
              return bT.compareTo(aT);
            });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final data  = chats[i].data() as Map<String, dynamic>;
              final chatId = chats[i].id;
              final participants = List<String>.from(data['participants'] ?? []);
              final otherUid = participants.firstWhere(
                (p) => p != uid, orElse: () => '');
              final lastMsg    = data['lastMessage']   as String? ?? '';
              final lastMsgAt  = data['lastMessageAt'] as String? ?? '';
              final postTitle  = data['postTitle']     as String? ?? 'Post';
              final unreadCount = (data['unread_$uid'] as int?) ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                  .collection(FirestoreCollections.users)
                  .doc(otherUid)
                  .get(),
                builder: (_, userSnap) {
                  final userData = userSnap.data?.data()
                    as Map<String, dynamic>? ?? {};
                  final otherName  = userData['name']     as String? ?? 'User';
                  final otherPhoto = userData['photoUrl'] as String?;

                  return _ChatTile(
                    chatId: chatId,
                    otherUid: otherUid,
                    otherName: otherName,
                    otherPhoto: otherPhoto,
                    lastMsg: lastMsg,
                    lastMsgAt: lastMsgAt,
                    postTitle: postTitle,
                    unreadCount: unreadCount,
                    currentUid: uid,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId, otherUid, otherName, lastMsg, lastMsgAt, postTitle, currentUid;
  final String? otherPhoto;
  final int unreadCount;

  const _ChatTile({
    required this.chatId, required this.otherUid, required this.otherName,
    required this.lastMsg, required this.lastMsgAt, required this.postTitle,
    required this.unreadCount, required this.currentUid, this.otherPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final initials = otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U';
    final timeStr  = lastMsgAt.isNotEmpty
      ? AppDateUtils.timeAgo(DateTime.tryParse(lastMsgAt) ?? DateTime.now())
      : '';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          otherUid: otherUid,
          otherName: otherName,
          otherPhotoUrl: otherPhoto,
          postTitle: postTitle,
        ))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border, width: 0.8)),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(child: otherPhoto != null
              ? CachedNetworkImage(imageUrl: otherPhoto!, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _InitialAvatar(initials))
              : _InitialAvatar(initials)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(otherName,
                  style: AppTextStyles.titleMedium,
                  overflow: TextOverflow.ellipsis)),
                Text(timeStr, style: AppTextStyles.caption),
              ]),
              const SizedBox(height: 2),
              Text('Re: $postTitle',
                style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary),
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(child: Text(lastMsg,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: unreadCount > 0
                      ? FontWeight.w600 : FontWeight.w400),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
                    child: Text('$unreadCount',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700))),
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  const _InitialAvatar(this.initial);
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primaryLight,
    child: Center(child: Text(initial,
      style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary))));
}