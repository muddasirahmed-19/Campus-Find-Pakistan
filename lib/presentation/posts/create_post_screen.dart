import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/validators/app_validators.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/services/notification_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _rewardCtrl = TextEditingController();

  PostType      _postType     = PostType.lost;
  ItemCategory? _category;
  String?       _subcategory;
  String?       _campusArea;
  DateTime      _dateOccurred = DateTime.now();

  final List<Uint8List> _images = [];
  bool    _isSubmitting  = false;
  int     _uploadedCount = 0;
  String  _statusMsg     = '';
  String? _errorMessage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Pick images: camera or gallery ────────────────────────────────────────
  Future<void> _pickImages() async {
    if (_images.length >= AppConstants.maxPostImages) {
      _showSnack('Maximum ${AppConstants.maxPostImages} images allowed');
      return;
    }
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery)),
          const SizedBox(height: 8),
        ])));

    if (src == null) return;

    if (src == ImageSource.gallery) {
      final files = await ImagePicker().pickMultiImage(imageQuality: 70);
      for (final f in files) {
        if (_images.length >= AppConstants.maxPostImages) break;
        final bytes = await f.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          _showSnack('${f.name} is too large (max 5MB), skipped');
          continue;
        }
        setState(() => _images.add(bytes));
      }
    } else {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera, imageQuality: 70);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _showSnack('Image too large (max 5MB)');
        return;
      }
      setState(() => _images.add(bytes));
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _errorMessage = 'Please select a category'); return;
    }
    if (_campusArea == null) {
      setState(() => _errorMessage = 'Please select a campus area'); return;
    }

    setState(() {
      _isSubmitting  = true;
      _errorMessage  = null;
      _uploadedCount = 0;
      _statusMsg     = _images.isEmpty ? 'Saving post...' : 'Uploading images...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final userDoc  = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users).doc(user.uid).get();
      final userName = userDoc.data()?['name']      as String? ?? 'Anonymous';
      final uniShort = userDoc.data()?['university'] as String? ?? '';
      if (uniShort.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Please set your university in Profile first.';
        });
        return;
      }

      // Upload images
      final imageUrls = <String>[];
      for (var i = 0; i < _images.length; i++) {
        setState(() {
          _uploadedCount = i;
          _statusMsg = 'Uploading image ${i + 1} of ${_images.length}...';
        });
        final url = await CloudinaryService.instance.uploadImageBytes(
          _images[i], folder: 'campusfind/posts');
        imageUrls.add(url);
      }

      setState(() => _statusMsg = 'Saving post...');

      final docRef = await FirebaseFirestore.instance
        .collection(FirestoreCollections.posts).add({
          'userId':              user.uid,
          'userName':            userName,
          'universityShortName': uniShort,
          'type':                _postType.name,
          'title':               _titleCtrl.text.trim(),
          'description':         _descCtrl.text.trim(),
          'categoryId':          _category!.id,
          'categoryName':        _category!.name,
          'categoryIcon':        _category!.icon,
          'subcategoryName':     _subcategory,
          'imageUrls':           imageUrls,
          'campusArea':          _campusArea,
          'dateLostFound':       _dateOccurred.toIso8601String(),
          'rewardAmount':        _rewardCtrl.text.trim().isEmpty
            ? null : int.tryParse(_rewardCtrl.text.trim()),
          'status':              PostStatus.active.firestoreValue,
          'createdAt':           DateTime.now().toIso8601String(),
          'expiresAt':           DateTime.now()
            .add(const Duration(days: 30)).toIso8601String(),
        });

      await NotificationService.broadcastNewPost(
        postId:              docRef.id,
        universityShortName: uniShort,
        title: '${_postType == PostType.lost ? '🔍 Lost' : '📢 Found'}: ${_titleCtrl.text.trim()}',
        body:  '$uniShort • ${_campusArea ?? ''}',
      );

      if (!mounted) return;
      setState(() { _isSubmitting = false; _statusMsg = ''; });
      _showSnack('Post created successfully!');
      Navigator.pop(context);

    } catch (e) {
      if (mounted) setState(() {
        _isSubmitting = false;
        _statusMsg    = '';
        _errorMessage = e.toString();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: AppColors.surface),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // Post Type
            _SectionCard(title: 'What are you posting?',
              child: Row(children: [
                Expanded(child: _TypeBtn(
                  label: 'I Lost Something',
                  icon: Icons.search_rounded,
                  active: _postType == PostType.lost,
                  color: AppColors.lostColor,
                  onTap: () => setState(() => _postType = PostType.lost))),
                const SizedBox(width: 12),
                Expanded(child: _TypeBtn(
                  label: 'I Found Something',
                  icon: Icons.inventory_2_outlined,
                  active: _postType == PostType.found,
                  color: AppColors.foundColor,
                  onTap: () => setState(() => _postType = PostType.found))),
              ])),
            const SizedBox(height: 16),

            // Item Details
            _SectionCard(title: 'Item Details',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _lbl('Title *'),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Black Samsung Galaxy S23',
                    prefixIcon: Icon(Icons.title_rounded)),
                  validator: AppValidators.postTitle),
                const SizedBox(height: 14),

                _lbl('Category *'),
                DropdownButtonFormField<String>(
                  value: _category?.id, isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Select category',
                    prefixIcon: Icon(Icons.category_outlined)),
                  items: AppCategories.all.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.icon}  ${c.name}',
                      style: AppTextStyles.bodyMedium))).toList(),
                  onChanged: (v) => setState(() {
                    _category    = AppCategories.findById(v!);
                    _subcategory = null;
                  }),
                  validator: (_) => _category == null ? 'Select a category' : null),

                if (_category != null && _category!.subcategories.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _lbl('Subcategory (optional)'),
                  DropdownButtonFormField<String>(
                    value: _subcategory, isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select subcategory',
                      prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded)),
                    items: _category!.subcategories.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: AppTextStyles.bodyMedium))).toList(),
                    onChanged: (v) => setState(() => _subcategory = v)),
                ],

                const SizedBox(height: 14),
                _lbl('Description *'),
                TextFormField(
                  controller: _descCtrl, maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Describe — color, brand, size, unique marks...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true),
                  validator: AppValidators.postDescription),
              ])),
            const SizedBox(height: 16),

            // Where & When
            _SectionCard(title: 'Where & When',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _lbl('Campus Area *'),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                    .collection(FirestoreCollections.users)
                    .doc(FirebaseAuth.instance.currentUser?.uid).get(),
                  builder: (_, snap) {
                    final uniShortName = (snap.data?.data()
                      as Map?)?['university'] as String? ?? '';
                    final uni = AppUniversities.all.firstWhere(
                      (u) => u.shortName == uniShortName,
                      orElse: () => AppUniversities.all.first);
                    return DropdownButtonFormField<String>(
                      value: _campusArea, isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select campus area',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                      items: uni.campusAreas.map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a, style: AppTextStyles.bodyMedium))).toList(),
                      onChanged: (v) => setState(() => _campusArea = v),
                      validator: (_) =>
                        _campusArea == null ? 'Select campus area' : null);
                  }),

                const SizedBox(height: 14),
                _lbl('Date ${_postType == PostType.lost ? "Lost" : "Found"} *'),
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _dateOccurred,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 60)),
                      lastDate: DateTime.now());
                    if (p != null) setState(() => _dateOccurred = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: AppColors.border, width: 0.8)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        '${_dateOccurred.day}/${_dateOccurred.month}/${_dateOccurred.year}',
                        style: AppTextStyles.bodyMedium),
                    ]),
                  ),
                ),
              ])),
            const SizedBox(height: 16),

            // Photos
            _SectionCard(title: 'Photos (optional)',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(children: [
                  Text('Add up to ${AppConstants.maxPostImages} photos',
                    style: AppTextStyles.bodySmall),
                  const Spacer(),
                  Text('${_images.length}/${AppConstants.maxPostImages}',
                    style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary)),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(scrollDirection: Axis.horizontal,
                    children: [
                    if (_images.length < AppConstants.maxPostImages)
                      GestureDetector(
                        onTap: _isSubmitting ? null : _pickImages,
                        child: Container(
                          width: 100, height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.4))),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.primary, size: 28),
                              SizedBox(height: 4),
                              Text('Add Photo',
                                style: TextStyle(
                                  fontSize: 11, color: AppColors.primary)),
                            ]),
                        )),
                    ..._images.asMap().entries.map((e) => Stack(children: [
                      Container(
                        width: 100, height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          image: DecorationImage(
                            image: MemoryImage(e.value), fit: BoxFit.cover))),
                      if (_isSubmitting && _uploadedCount <= e.key)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius:
                                BorderRadius.circular(AppDimens.radiusMd)),
                            child: Center(
                              child: _uploadedCount > e.key
                                ? const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 28)
                                : const SizedBox(width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))))),
                      if (!_isSubmitting)
                        Positioned(top: 4, right: 12,
                          child: GestureDetector(
                            onTap: () =>
                              setState(() => _images.removeAt(e.key)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 14)))),
                    ])),
                  ]),
                ),
                if (_isSubmitting && _images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _images.isEmpty ? null
                      : _uploadedCount / _images.length,
                    borderRadius: BorderRadius.circular(2)),
                  const SizedBox(height: 4),
                  Text(_statusMsg, style: AppTextStyles.caption),
                ],
              ])),
            const SizedBox(height: 16),

            // Reward (lost only)
            if (_postType == PostType.lost)
              _SectionCard(title: 'Reward (optional)',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text('Offer a reward to increase chances of finding.',
                    style: AppTextStyles.bodySmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rewardCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '500',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      prefixText: 'PKR  '),
                    validator: AppValidators.rewardAmount),
                ])),

            const SizedBox(height: 16),

            // Error
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.4))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Icon(Icons.error_outline,
                    color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage!,
                    style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error))),
                ])),

            // Submit
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting
                ? (_statusMsg.isNotEmpty ? _statusMsg : 'Posting...')
                : 'Post Item')),

            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: AppTextStyles.labelLarge));
}

// ── Supporting widgets ────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      boxShadow: AppShadows.card),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.titleMedium),
      const SizedBox(height: 16),
      child,
    ]));
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.icon,
    required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.1) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: active ? color : AppColors.border,
          width: active ? 2 : 1)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? color : AppColors.textSecondary, size: 28),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.labelMedium.copyWith(
          color: active ? color : AppColors.textSecondary),
          textAlign: TextAlign.center),
      ])));
}