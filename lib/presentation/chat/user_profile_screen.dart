import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/post_model.dart';
import '../posts/post_detail_screen.dart';
import '../home/widgets/post_card.dart';

class UserProfileScreen extends StatelessWidget {
  final String uid;
  const UserProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMe  = uid == myUid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          final name       = data['name']       as String? ?? 'User';
          final university = data['university'] as String? ?? '';
          final photoUrl   = data['photoUrl']   as String?;
          final joinedAt   = data['createdAt']  as String?;
          final initials   = name.isNotEmpty ? name[0].toUpperCase() : 'U';

          return CustomScrollView(slivers: [
            // ── App Bar ────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              expandedHeight: 220,
              actions: [
                if (!isMe)
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, color: AppColors.error),
                    tooltip: 'Report User',
                    onPressed: () => _showReportDialog(context, myUid, name)),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      // Avatar
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 2)),
                        child: ClipOval(child: photoUrl != null
                          ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _InitialBg(initials))
                          : _InitialBg(initials)),
                      ),
                      const SizedBox(height: 12),
                      Text(name,
                        style: AppTextStyles.titleLarge
                          .copyWith(color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                      if (university.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull)),
                          child: Text(university,
                            style: AppTextStyles.caption
                              .copyWith(color: Colors.white))),
                      ],
                      if (joinedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Joined ${AppDateUtils.formatDate(DateTime.tryParse(joinedAt) ?? DateTime.now())}',
                          style: AppTextStyles.caption
                            .copyWith(color: Colors.white70)),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Their Posts ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Posts by $name',
                  style: AppTextStyles.headlineSmall))),

            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection(FirestoreCollections.posts)
                  .where('userId', isEqualTo: uid)
                  .where('status', isEqualTo: PostStatus.active.firestoreValue)
                  .snapshots(),
                builder: (ctx, pSnap) {
                  if (pSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()));
                  }
                  final posts = (pSnap.data?.docs ?? []).map((d) {
                    final m = d.data() as Map<String, dynamic>;
                    m['id'] = d.id;
                    return PostModel.fromMap(m);
                  }).toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(child: Text('No active posts yet',
                        style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary))));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    itemCount: posts.length,
                    itemBuilder: (_, i) => PostCard(
                      post: posts[i],
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: posts[i])))));
                },
              ),
            ),
          ]);
        },
      ),
    );
  }

  void _showReportDialog(
      BuildContext context, String reporterUid, String reportedName) {
    final reasons = [
      'Fake or misleading post',
      'Harassment or threatening messages',
      'Spam or scam attempt',
      'Inappropriate content',
      'Other',
    ];
    String? selected;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
          title: Text('Report $reportedName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why are you reporting this user?',
                style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                value: r,
                groupValue: selected,
                title: Text(r, style: AppTextStyles.bodyMedium),
                onChanged: (v) => setS(() => selected = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
              onPressed: selected == null ? null : () async {
                Navigator.pop(ctx);
                await _submitReport(reporterUid, selected!);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Report submitted. Thank you for keeping campus safe.')));
              },
              child: const Text('Submit Report')),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String reporterUid, String reason) async {
    await FirebaseFirestore.instance
      .collection(FirestoreCollections.reports)
      .add({
        'reportedUserId': uid,
        'reporterUserId': reporterUid,
        'reason':         reason,
        'type':           'user',
        'createdAt':      DateTime.now().toIso8601String(),
        'status':         'pending',
      });
  }
}

class _InitialBg extends StatelessWidget {
  final String initial;
  const _InitialBg(this.initial);
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withOpacity(0.2),
    child: Center(child: Text(initial,
      style: AppTextStyles.headlineMedium
        .copyWith(color: Colors.white, fontWeight: FontWeight.w700))));
}