import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/post_model.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isLost  = post.type == PostType.lost;
    final isOwner = FirebaseAuth.instance.currentUser?.uid == post.userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Image header
          SliverAppBar(
            expandedHeight: post.imageUrls.isNotEmpty ? 280 : 120,
            pinned: true,
            backgroundColor: isLost ? AppColors.lostColor : AppColors.foundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: post.imageUrls.isNotEmpty
                ? PageView.builder(
                    itemCount: post.imageUrls.length,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: post.imageUrls[i], fit: BoxFit.cover))
                : Container(
                    color: isLost ? AppColors.lostLight : AppColors.foundLight,
                    child: Center(child: Text(post.categoryIcon,
                      style: const TextStyle(fontSize: 80)))),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Type + time row
                Row(children: [
                  _Tag(
                    label: isLost ? 'LOST' : 'FOUND',
                    bg: isLost ? AppColors.lostLight : AppColors.foundLight,
                    fg: isLost ? AppColors.lostColor : AppColors.foundColor),
                  const SizedBox(width: 8),
                  _Tag(label: post.status.label,
                    bg: AppColors.surfaceVariant, fg: AppColors.textSecondary),
                  const Spacer(),
                  Text(AppDateUtils.timeAgo(post.createdAt),
                    style: AppTextStyles.caption),
                ]),

                const SizedBox(height: 16),
                Text(post.title, style: AppTextStyles.headlineLarge),
                const SizedBox(height: 8),

                // Posted by
                Row(children: [
                  const Icon(Icons.person_outline_rounded,
                    size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Posted by ${post.userName}',
                    style: AppTextStyles.bodySmall),
                  const SizedBox(width: 12),
                  _Tag(label: post.universityShortName,
                    bg: AppColors.primaryLight, fg: AppColors.primary),
                ]),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                Text('Description', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                Text(post.description,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
                const SizedBox(height: 20),

                // Details card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.border, width: 0.8)),
                  child: Column(children: [
                    _Row(Icons.category_outlined, 'Category',
                      '${post.categoryIcon}  ${post.categoryName}'),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _Row(Icons.location_on_outlined, 'Campus Area', post.campusArea),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _Row(Icons.school_outlined, 'University', post.universityShortName),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _Row(Icons.calendar_today_outlined,
                      isLost ? 'Date Lost' : 'Date Found',
                      AppDateUtils.formatDate(post.dateLostFound)),
                    if (post.rewardAmount != null && post.rewardAmount! > 0) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _Row(Icons.attach_money_rounded, 'Reward',
                        StringUtils.formatCurrency(post.rewardAmount!)),
                    ],
                  ]),
                ),

                const SizedBox(height: 32),

                // Action buttons
                if (!isOwner && post.status == PostStatus.active)
                  ElevatedButton.icon(
                    onPressed: () => _showContactDialog(context),
                    icon: Icon(isLost
                      ? Icons.volunteer_activism_outlined
                      : Icons.back_hand_outlined),
                    label: Text(isLost ? 'I Found This!' : 'This is Mine!'),
                  ),

                if (isOwner) ...[
                  OutlinedButton.icon(
                    onPressed: () => _markResolved(context),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Mark as Resolved'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error)),
                    onPressed: () => _deletePost(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Post'),
                  ),
                ],

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(post.type == PostType.found ? 'Claim This Item' : 'I Found This!'),
      content: Text(post.type == PostType.found
        ? 'Contact the finder to claim this item. They may ask you to describe it to verify ownership.'
        : 'Contact the owner to help return this item.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Full claim & chat system coming soon!')));
          },
          child: const Text('Contact')),
      ],
    ));
  }

  void _markResolved(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Mark as Resolved'),
      content: const Text('Has this item been found/returned? This will remove it from the active feed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await FirebaseFirestore.instance
              .collection(FirestoreCollections.posts)
              .doc(post.id)
              .update({'status': 'resolved'});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post marked as resolved!')));
              Navigator.pop(context);
            }
          },
          child: const Text('Mark Resolved')),
      ],
    ));
  }

  void _deletePost(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Post'),
      content: const Text('Are you sure? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            Navigator.pop(ctx);
            await FirebaseFirestore.instance
              .collection(FirestoreCollections.posts)
              .doc(post.id)
              .delete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post deleted.')));
              Navigator.pop(context);
            }
          },
          child: const Text('Delete')),
      ],
    ));
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Tag({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
    child: Text(label, style: AppTextStyles.caption
      .copyWith(color: fg, fontWeight: FontWeight.w600)),
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 12),
      Text(label, style: AppTextStyles.bodySmall),
      const Spacer(),
      Flexible(child: Text(value, style: AppTextStyles.titleMedium,
        textAlign: TextAlign.right)),
    ]),
  );
}