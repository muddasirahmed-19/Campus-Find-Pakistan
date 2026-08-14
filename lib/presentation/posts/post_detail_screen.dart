import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/post_model.dart';
import '../../data/services/notification_service.dart';
import '../chat/chat_screen.dart';

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

          // ── App Bar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            title: Text(post.title,
              style: AppTextStyles.titleLarge,
              overflow: TextOverflow.ellipsis),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Image Gallery ─────────────────────────────────
                if (post.imageUrls.isNotEmpty)
                  _ImageGallery(imageUrls: post.imageUrls)
                else
                  _NoImagePlaceholder(
                    icon: post.categoryIcon,
                    color: isLost ? AppColors.lostLight : AppColors.foundLight),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                    // ── Type + Status row ─────────────────────────
                    Row(children: [
                      _Tag(
                        label: isLost ? 'LOST' : 'FOUND',
                        bg: isLost ? AppColors.lostLight : AppColors.foundLight,
                        fg: isLost ? AppColors.lostColor : AppColors.foundColor),
                      const SizedBox(width: 8),
                      _StatusTag(status: post.status),
                      const Spacer(),
                      Text(AppDateUtils.timeAgo(post.createdAt),
                        style: AppTextStyles.caption),
                    ]),

                    const SizedBox(height: 16),

                    // ── Title ─────────────────────────────────────
                    Text(post.title, style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 8),

                    // ── Posted by ─────────────────────────────────
                    Row(children: [
                      const Icon(Icons.person_outline_rounded,
                        size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Posted by ${post.userName}',
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      _Tag(
                        label: post.universityShortName,
                        bg: AppColors.primaryLight,
                        fg: AppColors.primary),
                    ]),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── Description ───────────────────────────────
                    Text('Description', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    Text(post.description,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),

                    const SizedBox(height: 20),

                    // ── Details Card ──────────────────────────────
                    _DetailsCard(post: post, isLost: isLost),

                    const SizedBox(height: 28),

                    // ── Action Buttons ────────────────────────────
                    if (!isOwner && post.status == PostStatus.active)
                      ElevatedButton.icon(
                        onPressed: () => _showContactDialog(context),
                        icon: Icon(isLost
                          ? Icons.volunteer_activism_outlined
                          : Icons.back_hand_outlined),
                        label: Text(isLost
                          ? 'I Found This!'
                          : 'This is Mine!'),
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

                    const SizedBox(height: 40),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(post.type == PostType.found
        ? 'Claim This Item' : 'I Found This!'),
      content: Text(post.type == PostType.found
        ? 'Contact the finder to claim this item.'
        : 'Contact the owner to help return this item.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await _openOrCreateChat(context);
          },
          child: const Text('Contact')),
      ],
    ));
  }

  Future<void> _openOrCreateChat(BuildContext context) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final db    = FirebaseFirestore.instance;

    // Reuse existing chat for this post between these two users
    final existing = await db
      .collection(FirestoreCollections.chats)
      .where('postId',       isEqualTo: post.id)
      .where('participants', arrayContains: myUid)
      .limit(1)
      .get();

    String chatId;
    if (existing.docs.isNotEmpty) {
      chatId = existing.docs.first.id;
    } else {
      final ref = await db.collection(FirestoreCollections.chats).add({
        'postId':                 post.id,
        'postTitle':              post.title,
        'participants':           [myUid, post.userId],
        'lastMessage':            '',
        'lastMessageAt':          DateTime.now().toIso8601String(),
        'createdAt':              DateTime.now().toIso8601String(),
        'unread_$myUid':          0,
        'unread_${post.userId}':  0,
      });
      chatId = ref.id;
    }

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        chatId:    chatId,
        otherUid:  post.userId,
        otherName: post.userName,
        postTitle: post.title,
      )));
  }

  void _markResolved(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Mark as Resolved'),
      content: const Text(
        'Has this item been found/returned? '
        'This will remove it from the active feed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await FirebaseFirestore.instance
              .collection(FirestoreCollections.posts)
              .doc(post.id)
              .update({'status': 'resolved'});
            // Write a resolved broadcast so others can see it
            await NotificationService.broadcastNewPost(
              postId:              '${post.id}_resolved',
              universityShortName: post.universityShortName,
              title: '✅ Resolved: ${post.title}',
              body:  'This item has been found/returned.',
            );
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
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel')),
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

// ── Image Gallery with swipe + dots ──────────────────────────────────────────
class _ImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  const _ImageGallery({required this.imageUrls});
  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _current = 0;
  final _ctrl  = PageController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Swipeable image pages
      SizedBox(
        height: 280,
        child: PageView.builder(
          controller: _ctrl,
          itemCount: widget.imageUrls.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _openFullscreen(context, i),
            child: CachedNetworkImage(
              imageUrl: widget.imageUrls[i],
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.surfaceVariant,
                child: const Center(child: CircularProgressIndicator())),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image_outlined,
                  size: 48, color: AppColors.textHint)),
            ),
          ),
        ),
      ),

      // Dots indicator (only if multiple images)
      if (widget.imageUrls.length > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.imageUrls.length, (i) =>
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _current == i ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(4)),
            )),
        ),
        const SizedBox(height: 4),
        Text('${_current + 1} / ${widget.imageUrls.length}',
          style: AppTextStyles.caption),
      ],
    ]);
  }

  void _openFullscreen(BuildContext context, int initialIndex) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _FullscreenGallery(
        imageUrls: widget.imageUrls,
        initialIndex: initialIndex)));
  }
}

// ── Fullscreen Gallery ────────────────────────────────────────────────────────
class _FullscreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _FullscreenGallery(
    {required this.imageUrls, required this.initialIndex});
  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl    = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrls[i],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                size: 64, color: Colors.white38),
            ),
          ),
        ),
      ),
    );
  }
}

// ── No Image Placeholder ─────────────────────────────────────────────────────
class _NoImagePlaceholder extends StatelessWidget {
  final String icon;
  final Color color;
  const _NoImagePlaceholder({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    height: 160, width: double.infinity,
    color: color,
    child: Center(child: Text(icon,
      style: const TextStyle(fontSize: 72))));
}

// ── Details Card ─────────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final PostModel post;
  final bool isLost;
  const _DetailsCard({required this.post, required this.isLost});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.8)),
      child: Column(children: [
        _DetailRow(
          icon: Icons.category_outlined,
          label: 'Category',
          value: '${post.categoryIcon}  ${post.categoryName}'),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _DetailRow(
          icon: Icons.location_on_outlined,
          label: 'Campus Area',
          value: post.campusArea),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _DetailRow(
          icon: Icons.school_outlined,
          label: 'University',
          value: post.universityShortName),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: isLost ? 'Date Lost' : 'Date Found',
          value: AppDateUtils.formatDate(post.dateLostFound)),
        if (post.rewardAmount != null && post.rewardAmount! > 0) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          _DetailRow(
            icon: Icons.attach_money_rounded,
            label: 'Reward',
            value: StringUtils.formatCurrency(post.rewardAmount!)),
        ],
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 12),
      // Label takes fixed width for alignment
      SizedBox(
        width: 110,
        child: Text(label,
          style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.textSecondary))),
      const SizedBox(width: 8),
      // Value takes remaining space, wraps if needed
      Expanded(child: Text(value,
        style: AppTextStyles.titleMedium,
        textAlign: TextAlign.right)),
    ]),
  );
}

// ── Tag widgets ───────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Tag({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
    child: Text(label, style: AppTextStyles.caption
      .copyWith(color: fg, fontWeight: FontWeight.w600)));
}

// Green when active, gray when resolved/expired
class _StatusTag extends StatelessWidget {
  final PostStatus status;
  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    switch (status) {
      case PostStatus.active:
        bg = AppColors.secondaryLight;
        fg = AppColors.secondary;
        break;
      case PostStatus.resolved:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        break;
      case PostStatus.claimPending:
      case PostStatus.claimApproved:
      case PostStatus.handoffPending:
        bg = AppColors.accent.withOpacity(0.15);
        fg = AppColors.accent;
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
      child: Text(status.label,
        style: AppTextStyles.caption
          .copyWith(color: fg, fontWeight: FontWeight.w600)));
  }
}