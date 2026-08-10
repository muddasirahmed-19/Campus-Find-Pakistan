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

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _rewardCtrl   = TextEditingController();

  PostType      _postType    = PostType.lost;
  ItemCategory? _category;
  String?       _subcategory;
  University?   _university;
  String?       _campusArea;
  DateTime      _dateOccurred = DateTime.now();

  final List<Uint8List> _images = [];
  bool    _isSubmitting  = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _rewardCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= AppConstants.maxPostImages) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Maximum ${AppConstants.maxPostImages} images allowed')));
      return;
    }
    final files = await ImagePicker().pickMultiImage(imageQuality: 75);
    for (final f in files) {
      if (_images.length >= AppConstants.maxPostImages) break;
      setState(() {});
      final bytes = await f.readAsBytes();
      setState(() => _images.add(bytes));
    }
  }

  Future<void> _submit() async {
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
    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      final urls = <String>[];
      for (int i = 0; i < _images.length; i++) {
        final r = await CloudinaryService.instance.uploadFromBytes(
          _images[i], 'post_$i.jpg');
        if (r.isSuccess && r.data != null) urls.add(r.data!.secureUrl);
      }

      final user = FirebaseAuth.instance.currentUser;
      final now  = DateTime.now();

      await FirebaseFirestore.instance
        .collection(FirestoreCollections.posts)
        .add({
          'type': _postType.name,
          'userId': user?.uid ?? '',
          'userName': user?.displayName ?? user?.email ?? 'Anonymous',
          'universityShortName': _university!.shortName,
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'categoryId': _category!.id,
          'categoryName': _category!.name,
          'categoryIcon': _category!.icon,
          'imageUrls': urls,
          'campusArea': _campusArea,
          'dateLostFound': _dateOccurred.toIso8601String(),
          'status': 'active',
          'rewardAmount': _rewardCtrl.text.isNotEmpty
            ? int.tryParse(_rewardCtrl.text.trim()) : null,
          'createdAt': now.toIso8601String(),
          'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
        });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')));
    } catch (e) {
      setState(() { _isSubmitting = false; _errorMessage = 'Failed to create post. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Post'), backgroundColor: AppColors.surface),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Post type
            _Card('What are you posting?',
              Row(children: [
                Expanded(child: _TypeBtn(
                  label: 'I Lost Something', icon: Icons.search_rounded,
                  active: _postType == PostType.lost, color: AppColors.lostColor,
                  onTap: () => setState(() => _postType = PostType.lost))),
                const SizedBox(width: 12),
                Expanded(child: _TypeBtn(
                  label: 'I Found Something', icon: Icons.inventory_2_outlined,
                  active: _postType == PostType.found, color: AppColors.foundColor,
                  onTap: () => setState(() => _postType = PostType.found))),
              ]),
            ),
            const SizedBox(height: 16),

            // Item details
            _Card('Item Details',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _lbl('Title *'),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Black Samsung Galaxy S23',
                    prefixIcon: Icon(Icons.title_rounded)),
                  textCapitalization: TextCapitalization.sentences,
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
                  onChanged: (v) {
                    setState(() {
                      _category = AppCategories.findById(v!);
                      _subcategory = null;
                    });
                  },
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
                      value: s, child: Text(s, style: AppTextStyles.bodyMedium))).toList(),
                    onChanged: (v) => setState(() => _subcategory = v)),
                ],

                const SizedBox(height: 14),
                _lbl('Description *'),
                TextFormField(
                  controller: _descCtrl, maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the item — color, brand, size, unique marks...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true),
                  textCapitalization: TextCapitalization.sentences,
                  validator: AppValidators.postDescription),
              ]),
            ),
            const SizedBox(height: 16),

            // Location & date
            _Card('Where & When',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    final uni = AppUniversities.all.firstWhere((u) => u.shortName == v);
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
                      value: a, child: Text(a, style: AppTextStyles.bodyMedium))).toList(),
                    onChanged: (v) => setState(() => _campusArea = v),
                    validator: (_) => _campusArea == null ? 'Select campus area' : null),
                ],

                const SizedBox(height: 14),
                _lbl('Date ${_postType == PostType.lost ? "Lost" : "Found"} *'),
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _dateOccurred,
                      firstDate: DateTime.now().subtract(const Duration(days: 60)),
                      lastDate: DateTime.now());
                    if (p != null) setState(() => _dateOccurred = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              ]),
            ),
            const SizedBox(height: 16),

            // Photos
            _Card('Photos (optional)',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Add up to ${AppConstants.maxPostImages} photos',
                  style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    if (_images.length < AppConstants.maxPostImages)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100, height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            border: Border.all(color: AppColors.border)),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.primary, size: 28),
                              SizedBox(height: 4),
                              Text('Add Photo',
                                style: TextStyle(fontSize: 11, color: AppColors.primary)),
                            ]),
                        ),
                      ),
                    ..._images.asMap().entries.map((e) => Stack(children: [
                      Container(
                        width: 100, height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          image: DecorationImage(
                            image: MemoryImage(e.value), fit: BoxFit.cover))),
                      Positioned(top: 4, right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(e.key)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.error, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 14)))),
                    ])),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Reward (lost only)
            if (_postType == PostType.lost)
              _Card('Reward (optional)',
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Offer a reward to increase chances of finding your item.',
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

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.error.withOpacity(0.4))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                ])),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? 'Posting...' : 'Post Item')),

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

Widget _Card(String title, Widget child) => Container(
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