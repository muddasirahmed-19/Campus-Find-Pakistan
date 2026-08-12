import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/validators/app_validators.dart';
import '../../data/services/cloudinary_service.dart';

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
  University?   _university;
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

  Future<void> _pickImages() async {
    if (_images.length >= AppConstants.maxPostImages) {
      _showSnack('Maximum ${AppConstants.maxPostImages} images allowed');
      return;
    }
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 70);
      for (final f in files) {
        if (_images.length >= AppConstants.maxPostImages) break;
        final bytes = await f.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          _showSnack('One image was too large (max 5MB), skipped');
          continue;
        }
        setState(() => _images.add(bytes));
      }
    } catch (e) {
      _showSnack('Could not pick images. Try again.');
    }
  }

  Future<void> _submit() async {
    // Validate
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _errorMessage = 'Please select a category'); return;
    }
    if (_university == null) {
      setState(() => _errorMessage = 'Please select your university'); return;
    }
    if (_campusArea == null) {
      setState(() => _errorMessage = 'Please select a campus area'); return;
    }

    setState(() {
      _isSubmitting   = true;
      _errorMessage   = null;
      _uploadedCount  = 0;
      _statusMsg      = _images.isEmpty ? 'Saving post...' : 'Uploading images...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // ── Upload images to Cloudinary ─────────────────────────────────
      final imageUrls = <String>[];
      if (_images.isNotEmpty) {
        final urls = await CloudinaryService.instance.uploadMultiple(
          _images,
          folder: 'campusfind/posts',
          onProgress: (done, total) {
            if (mounted) setState(() {
              _uploadedCount = done;
              _statusMsg = 'Uploading image $done/$total...';
            });
          },
        );
        imageUrls.addAll(urls);

        if (imageUrls.isEmpty && _images.isNotEmpty) {
          // All uploads failed — warn but continue
          _showSnack('Images could not be uploaded. Post will be created without images.');
        } else if (imageUrls.length < _images.length) {
          _showSnack('${_images.length - imageUrls.length} image(s) failed to upload.');
        }
      }

      setState(() => _statusMsg = 'Saving post...');

      // ── Save post to Firestore ──────────────────────────────────────
      final now = DateTime.now();
      final docRef = await FirebaseFirestore.instance
        .collection(FirestoreCollections.posts)
        .add({
          'type':                _postType.name,
          'userId':              user.uid,
          'userName':            user.displayName ?? 'Anonymous',
          'universityShortName': _university!.shortName,
          'title':               _titleCtrl.text.trim(),
          'description':         _descCtrl.text.trim(),
          'categoryId':          _category!.id,
          'categoryName':        _category!.name,
          'categoryIcon':        _category!.icon,
          'imageUrls':           imageUrls,
          'campusArea':          _campusArea!,
          'dateLostFound':       _dateOccurred.toIso8601String(),
          'status':              'active',
          'rewardAmount':        _rewardCtrl.text.trim().isNotEmpty
                                   ? int.tryParse(_rewardCtrl.text.trim()) : null,
          'createdAt':           now.toIso8601String(),
          'expiresAt':           now.add(const Duration(days: 30)).toIso8601String(),
        })
        .timeout(const Duration(seconds: 15));

      debugPrint('Post created: ${docRef.id} | images: ${imageUrls.length}');

      if (!mounted) return;
      setState(() { _isSubmitting = false; _statusMsg = ''; });
      Navigator.pop(context);
      _showSnack(imageUrls.isNotEmpty
        ? 'Post created with ${imageUrls.length} image(s)!'
        : 'Post created successfully!');

    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false; _statusMsg = '';
        _errorMessage = 'Request timed out. Check your internet and try again.';
      });
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: [${e.code}] ${e.message}');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false; _statusMsg = '';
        _errorMessage = e.code == 'permission-denied'
          ? 'Permission denied. Make sure Firestore rules are published correctly.'
          : 'Firebase error [${e.code}]: ${e.message}';
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false; _statusMsg = '';
        _errorMessage = e.toString();
      });
    }
  }

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
                    _category = AppCategories.findById(v!);
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
                _lbl('University *'),
                DropdownButtonFormField<String>(
                  value: _university?.shortName, isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Select university',
                    prefixIcon: Icon(Icons.school_outlined)),
                  items: AppUniversities.all.map((u) => DropdownMenuItem(
                    value: u.shortName,
                    child: Text('${u.shortName} — ${u.city}',
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) {
                    final uni = AppUniversities.all
                      .firstWhere((u) => u.shortName == v);
                    setState(() { _university = uni; _campusArea = null; });
                  },
                  validator: (_) => _university == null ? 'Select university' : null),

                if (_university != null) ...[
                  const SizedBox(height: 14),
                  _lbl('Campus Area *'),
                  DropdownButtonFormField<String>(
                    value: _campusArea, isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select campus area',
                      prefixIcon: Icon(Icons.location_on_outlined)),
                    items: _university!.campusAreas.map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(a, style: AppTextStyles.bodyMedium))).toList(),
                    onChanged: (v) => setState(() => _campusArea = v),
                    validator: (_) =>
                      _campusArea == null ? 'Select campus area' : null),
                ],

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
                    // Add photo button
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
                    // Image previews
                    ..._images.asMap().entries.map((e) => Stack(children: [
                      Container(
                        width: 100, height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                          image: DecorationImage(
                            image: MemoryImage(e.value),
                            fit: BoxFit.cover))),
                      // Upload progress overlay
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
                                      strokeWidth: 2,
                                      color: Colors.white))))),
                      // Remove button (only when not submitting)
                      if (!_isSubmitting)
                        Positioned(top: 4, right: 12,
                          child: GestureDetector(
                            onTap: () =>
                              setState(() => _images.removeAt(e.key)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 14)))),
                    ])),
                  ]),
                ),

                // Upload progress bar
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

            // Error box
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

            // Submit button
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
      border: Border.all(color: AppColors.border, width: 0.8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.titleLarge),
      const SizedBox(height: 14),
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
          width: active ? 1.5 : 0.8)),
      child: Column(children: [
        Icon(icon, color: active ? color : AppColors.textSecondary, size: 28),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.labelMedium.copyWith(
          color: active ? color : AppColors.textSecondary,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400),
          textAlign: TextAlign.center),
      ]),
    ),
  );
}