import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLost = post.type == PostType.lost;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: AppShadows.card,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          if (post.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusMd)),
              child: CachedNetworkImage(
                imageUrl: post.imageUrls.first,
                height: AppDimens.postImageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: AppDimens.postImageHeight,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator())),
                errorWidget: (_, __, ___) => _Placeholder(post.categoryIcon),
              ))
          else
            _Placeholder(post.categoryIcon),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Badges row
              Row(children: [
                _Badge(
                  label: isLost ? 'LOST' : 'FOUND',
                  bg: isLost ? AppColors.lostLight : AppColors.foundLight,
                  fg: isLost ? AppColors.lostColor : AppColors.foundColor),
                const SizedBox(width: 8),
                Text(post.categoryName,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                Text(AppDateUtils.timeAgo(post.createdAt),
                  style: AppTextStyles.caption),
              ]),
              const SizedBox(height: 8),

              // Title
              Text(post.title, style: AppTextStyles.titleLarge,
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),

              // Description
              Text(post.description, style: AppTextStyles.bodySmall,
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),

              // Footer
              Row(children: [
                _Badge(
                  label: post.universityShortName,
                  bg: AppColors.primaryLight, fg: AppColors.primary),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textHint),
                const SizedBox(width: 2),
                Expanded(child: Text(post.campusArea,
                  style: AppTextStyles.caption,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (post.rewardAmount != null && post.rewardAmount! > 0)
                  _Badge(
                    label: 'PKR ${post.rewardAmount}',
                    bg: AppColors.secondaryLight, fg: AppColors.secondary),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
    child: Text(label, style: AppTextStyles.caption
      .copyWith(color: fg, fontWeight: FontWeight.w600)),
  );
}

class _Placeholder extends StatelessWidget {
  final String icon;
  const _Placeholder(this.icon);
  @override
  Widget build(BuildContext context) => Container(
    height: 140, width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusMd))),
    child: Center(child: Text(icon, style: const TextStyle(fontSize: 48))),
  );
}