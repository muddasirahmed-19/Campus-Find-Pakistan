import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/post_model.dart';
import '../auth/email_signup_screen.dart';
import '../posts/create_post_screen.dart';
import '../posts/post_detail_screen.dart';
import '../posts/my_posts_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chats_list_screen.dart';
import 'widgets/post_card.dart';
import 'widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl  = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String  _searchQuery    = '';
  String? _filterCategory = null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleDrawer(String route) {
    _scaffoldKey.currentState?.closeDrawer();
    switch (route) {
      case 'create_post':
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()));
        break;
      case 'my_posts':
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MyPostsScreen()));
        break;
      case 'chats':
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ChatsListScreen()));
        break;
      case 'profile':
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      case 'logout':
        _confirmLogout();
        break;
    }
  }

  void _confirmLogout() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            Navigator.pop(ctx);
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const EmailSignupScreen()),
              (_) => false);
          },
          child: const Text('Sign Out')),
      ],
    ));
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.55, maxChildSize: 0.85,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('Filter by Category', style: AppTextStyles.headlineSmall),
              const Spacer(),
              if (_filterCategory != null)
                TextButton(
                  onPressed: () {
                    setState(() => _filterCategory = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Clear')),
            ])),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              controller: ctrl,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 1.1,
                crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: AppCategories.all.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) return _CatTile(
                  icon: '🔍', label: 'All',
                  active: _filterCategory == null,
                  onTap: () {
                    setState(() => _filterCategory = null);
                    Navigator.pop(context);
                  });
                final cat = AppCategories.all[i - 1];
                return _CatTile(
                  icon: cat.icon, label: cat.name,
                  active: _filterCategory == cat.id,
                  onTap: () {
                    setState(() => _filterCategory = cat.id);
                    Navigator.pop(context);
                  });
              },
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Category label for app bar button
    final catLabel = _filterCategory != null
      ? AppCategories.findById(_filterCategory!)?.name ?? 'Category'
      : 'Category';
    final catActive = _filterCategory != null;

    return StreamBuilder<DocumentSnapshot>(
      stream: uid == null ? null : FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final uniRaw = data['university'] as String?;
        final university = (uniRaw != null && uniRaw.isNotEmpty) ? uniRaw : null;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: AppDrawer(onNavigate: _handleDrawer),

          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer()),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CampusFind PK'),
                if (university != null)
                  Text(university,
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ]),
            actions: [
              // Category filter button
              GestureDetector(
                onTap: _showCategoryPicker,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catActive ? AppColors.primaryLight : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    border: Border.all(
                      color: catActive
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.category_outlined,
                      size: 14,
                      color: catActive ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(catLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: catActive ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: catActive ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              ),
              // Notifications
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')))),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Lost Items'),
                Tab(text: 'Found Items'),
              ],
            ),
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Post Item')),

          body: snap.connectionState == ConnectionState.waiting
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                _SearchBar(
                  controller: _searchCtrl,
                  onSearch: (q) => setState(() => _searchQuery = q)),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _Feed(
                        type: PostType.lost,
                        search: _searchQuery,
                        university: university,
                        category: _filterCategory),
                      _Feed(
                        type: PostType.found,
                        search: _searchQuery,
                        university: university,
                        category: _filterCategory),
                    ],
                  ),
                ),
              ]),
        );
      },
    );
  }
}

// ── Search Bar (no university filter) ─────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  const _SearchBar({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: TextFormField(
      controller: controller,
      onChanged: onSearch,
      decoration: InputDecoration(
        hintText: 'Search lost or found items...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () { controller.clear(); onSearch(''); })
          : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        filled: true, fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    ),
  );
}

class _CatTile extends StatelessWidget {
  final String icon, label;
  final bool active;
  final VoidCallback onTap;
  const _CatTile({required this.icon, required this.label,
    required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: active ? AppColors.primary : AppColors.border)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(
          color: active ? AppColors.primary : AppColors.textPrimary,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400),
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ── Post Feed ─────────────────────────────────────────────────────────────────
class _Feed extends StatelessWidget {
  final PostType type;
  final String search;
  final String? university, category;
  const _Feed({required this.type, required this.search,
    required this.university, required this.category});

  @override
  Widget build(BuildContext context) {
    Query q = FirebaseFirestore.instance
      .collection(FirestoreCollections.posts)
      .where('type', isEqualTo: type.name);

    // Auto-filter by user's university
    if (university != null) {
      q = q.where('universityShortName', isEqualTo: university);
    }
    if (category != null) {
      q = q.where('categoryId', isEqualTo: category);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _Empty(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: 'Pull down to refresh.');
        }

        var posts = (snap.data?.docs ?? []).map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return PostModel.fromMap(data);
        }).toList();

        // Client-side: active only + newest first
        posts = posts
          .where((p) => p.status == PostStatus.active)
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Search filter
        if (search.isNotEmpty) {
          final q2 = search.toLowerCase();
          posts = posts.where((p) =>
            p.title.toLowerCase().contains(q2) ||
            p.description.toLowerCase().contains(q2) ||
            p.campusArea.toLowerCase().contains(q2) ||
            p.categoryName.toLowerCase().contains(q2)).toList();
        }

        if (posts.isEmpty) {
          return _Empty(
            icon: type == PostType.lost
              ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            title: search.isNotEmpty || category != null
              ? 'No results found'
              : type == PostType.lost
                ? 'No lost items yet'
                : 'No found items yet',
            subtitle: search.isNotEmpty
              ? 'Try different keywords or clear category filter'
              : 'Be the first to post!');
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCard(
              post: posts[i],
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: posts[i])))),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _Empty({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 72, color: AppColors.border),
        const SizedBox(height: 20),
        Text(title, style: AppTextStyles.headlineSmall
          .copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      ]),
    ),
  );
}