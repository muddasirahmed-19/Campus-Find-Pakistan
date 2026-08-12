import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/post_model.dart';
import '../home/widgets/post_card.dart';
import 'post_detail_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});
  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Posts'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Lost'), Tab(text: 'Found')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MyFeed(uid: uid, type: PostType.lost),
          _MyFeed(uid: uid, type: PostType.found),
        ],
      ),
    );
  }
}

class _MyFeed extends StatelessWidget {
  final String uid;
  final PostType type;
  const _MyFeed({required this.uid, required this.type});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
      .collection(FirestoreCollections.posts)
      .where('userId', isEqualTo: uid)
      .where('type', isEqualTo: type.name);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error loading posts',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)));
        }

        final posts = (snap.data?.docs ?? []).map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return PostModel.fromMap(data);
        }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.post_add_outlined,
                    color: AppColors.primary, size: 40)),
                const SizedBox(height: 20),
                Text(
                  type == PostType.lost
                    ? 'No lost item posts yet'
                    : 'No found item posts yet',
                  style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Items you post will appear here.',
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: posts.length,
          itemBuilder: (_, i) => _MyPostCard(
            post: posts[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: posts[i]))),
            onDelete: () => _confirmDelete(context, posts[i].id),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String postId) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Post'),
      content: const Text('Are you sure you want to delete this post? '
        'This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            Navigator.pop(ctx);
            await FirebaseFirestore.instance
              .collection(FirestoreCollections.posts)
              .doc(postId)
              .delete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post deleted.')));
            }
          },
          child: const Text('Delete')),
      ],
    ));
  }
}

// ── My Post Card with delete option ──────────────────────────────────────
class _MyPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _MyPostCard({required this.post, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PostCard(post: post, onTap: onTap),
      // Status + delete overlay
      Positioned(
        top: 8, right: 8,
        child: Row(children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: post.status == PostStatus.active
                ? AppColors.secondary
                : AppColors.textHint,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
            child: Text(post.status.label,
              style: AppTextStyles.caption
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
              child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 16)),
          ),
        ]),
      ),
    ]);
  }
}