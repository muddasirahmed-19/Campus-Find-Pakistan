import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/post_model.dart';
import '../posts/post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _lastSeen = '1970-01-01T00:00:00.000Z';

  @override
  void initState() {
    super.initState();
    _loadAndMarkSeen();
  }

  Future<void> _loadAndMarkSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final prev  = prefs.getString('lastSeenBroadcastsAt') ?? '1970-01-01T00:00:00.000Z';
    setState(() => _lastSeen = prev);
    await prefs.setString('lastSeenBroadcastsAt', DateTime.now().toIso8601String());
  }

  Future<void> _openPost(BuildContext context, String postId) async {
    final doc = await FirebaseFirestore.instance
      .collection(FirestoreCollections.posts).doc(postId).get();
    if (!doc.exists || !context.mounted) return;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    final post = PostModel.fromMap(data);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PostDetailScreen(post: post)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Notifications')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
          .collection(FirestoreCollections.users).doc(_uid).get(),
        builder: (ctx, userSnap) {
          final uni = (userSnap.data?.data() as Map?)?['university'] as String? ?? '';

          if (uni.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Set your university in Profile to see notifications.',
                textAlign: TextAlign.center)));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
              .collection('broadcasts')
              .where('universityShortName', isEqualTo: uni)
              .snapshots(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = [...(snap.data?.docs ?? [])]
                ..removeWhere((d) => (d.data() as Map)['posterUid'] == _uid)
                ..sort((a, b) {
                  final at = (a.data() as Map)['createdAt'] as String? ?? '';
                  final bt = (b.data() as Map)['createdAt'] as String? ?? '';
                  return bt.compareTo(at);
                });

              if (docs.isEmpty) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                      size: 72, color: AppColors.border),
                    const SizedBox(height: 16),
                    Text('No new posts yet',
                      style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.textSecondary)),
                  ]));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data      = docs[i].data() as Map<String, dynamic>;
                  final postId    = data['postId']    as String? ?? '';
                  final posterUid = data['posterUid'] as String? ?? '';
                  final title     = data['title']     as String? ?? '';
                  final body      = data['body']      as String? ?? '';
                  final createdAt = data['createdAt'] as String? ?? '';
                  final isNew     = createdAt.compareTo(_lastSeen) > 0;
                  final time      = DateTime.tryParse(createdAt);

                  return _BroadcastTile(
                    posterUid: posterUid,
                    title:     title,
                    body:      body,
                    time:      time,
                    isNew:     isNew,
                    onTap:     () => _openPost(context, postId),
                  );
                });
            });
        }),
    );
  }
}

// ── Tile with poster avatar fetched from Firestore ────────────────────────────
class _BroadcastTile extends StatelessWidget {
  final String posterUid, title, body;
  final DateTime? time;
  final bool isNew;
  final VoidCallback onTap;
  const _BroadcastTile({required this.posterUid, required this.title,
    required this.body, required this.onTap,
    this.time, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
        .collection(FirestoreCollections.users).doc(posterUid).get(),
      builder: (_, snap) {
        final userData = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name     = userData['name']     as String? ?? 'User';
        final photo    = userData['photoUrl'] as String?;
        final initial  = name.isNotEmpty ? name[0].toUpperCase() : 'U';

        return InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isNew ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                color: isNew
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.border,
                width: 0.8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Poster avatar
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(child: photo != null && photo.isNotEmpty
                  ? CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _InitialAvatar(initial))
                  : _InitialAvatar(initial)),
              ),
              const SizedBox(width: 12),

              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: isNew ? FontWeight.w700 : FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (isNew)
                      Container(width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 3),
                  Text('by $name · $body',
                    style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(AppDateUtils.timeAgo(time!),
                      style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint)),
                  ],
                ])),
            ]),
          ),
        );
      });
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  const _InitialAvatar(this.initial);
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primaryLight,
    child: Center(child: Text(initial,
      style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary))));
}