import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../data/services/cloudinary_service.dart';
import 'user_profile_screen.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class _Msg {
  final String id, senderId, text, createdAt;
  final String? imageUrl;
  final bool pending;
  _Msg({required this.id, required this.senderId, required this.text,
    required this.createdAt, this.imageUrl, this.pending = false});
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String chatId, otherUid, otherName, postTitle;
  final String? otherPhotoUrl;
  const ChatScreen({super.key, required this.chatId, required this.otherUid,
    required this.otherName, required this.postTitle, this.otherPhotoUrl});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _uid        = FirebaseAuth.instance.currentUser!.uid;
  final List<_Msg>  _msgs = [];

  StreamSubscription<QuerySnapshot>? _sub;
  bool _initialLoaded = false;
  bool _sendingPhoto  = false;

  // Pending image selected but not yet sent
  String? _pendingImagePath;
  Uint8List? _pendingImageBytes;

  @override
  void initState() {
    super.initState();
    _markRead();
    // Subscribe once — no StreamBuilder, so setState is always safe here
    _sub = FirebaseFirestore.instance
      .collection(FirestoreCollections.chats)
      .doc(widget.chatId)
      .collection(FirestoreCollections.messages)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen(_onSnapshot);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSnapshot(QuerySnapshot snap) {
    final incoming = snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return _Msg(
        id:        d.id,
        senderId:  data['senderId']  as String? ?? '',
        text:      data['text']      as String? ?? '',
        imageUrl:  data['imageUrl']  as String?,
        createdAt: data['createdAt'] as String? ?? '',
      );
    }).toList();

    // Remove pending items that now have a real Firestore entry
    // Match by senderId + createdAt (same second) since fake IDs differ
    final incomingKeys = incoming
      .map((m) => '${m.senderId}_${m.createdAt.substring(0, 19)}')
      .toSet();
    final stillPending = _msgs.where((m) =>
      m.pending &&
      !incomingKeys.contains('${m.senderId}_${m.createdAt.substring(0, 19)}')
    ).toList();

    setState(() {
      _msgs
        ..clear()
        ..addAll([...incoming, ...stillPending]);
      _initialLoaded = true;
    });
  }

  Future<void> _markRead() async {
    await FirebaseFirestore.instance
      .collection(FirestoreCollections.chats)
      .doc(widget.chatId)
      .update({'unread_$_uid': 0});
  }

  // ── Photo picker ─────────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
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

    final picked = await ImagePicker().pickImage(
      source: src, imageQuality: 60, maxWidth: 1080, maxHeight: 1080);
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();

    // Show preview — user can confirm or cancel
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.memory(bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Send'))),
            ])),
        ]),
      ));

    if (confirmed != true || !mounted) return;

    setState(() => _sendingPhoto = true);
    try {
      final url = await CloudinaryService.instance.uploadImageBytes(
        bytes, folder: 'campusfind/chats');
      await _sendMessage(text: '', imageUrl: url);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send photo.')));
    } finally {
      if (mounted) setState(() => _sendingPhoto = false);
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await _sendMessage(text: text);
  }

  Future<void> _sendMessage({required String text, String? imageUrl}) async {
    final now    = DateTime.now().toIso8601String();
    final fakeId = 'pending_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic insert
    setState(() => _msgs.insert(0, _Msg(
      id: fakeId, senderId: _uid, text: text,
      imageUrl: imageUrl, createdAt: now, pending: true)));
    _scrollToBottom();

    final db      = FirebaseFirestore.instance;
    final batch   = db.batch();
    final msgRef  = db.collection(FirestoreCollections.chats)
      .doc(widget.chatId).collection(FirestoreCollections.messages).doc();
    final chatRef = db.collection(FirestoreCollections.chats).doc(widget.chatId);

    batch.set(msgRef, {
      'senderId':  _uid,
      'text':      text,
      'imageUrl':  imageUrl,
      'createdAt': now,
      'read':      false,
    });
    batch.update(chatRef, {
      'lastMessage':               text.isNotEmpty ? text : '📷 Photo',
      'lastMessageAt':             now,
      'unread_${widget.otherUid}': FieldValue.increment(1),
    });

    await batch.commit();

    // Trigger actual phone push notification via free Vercel server
    try {
      final otherDoc = await db.collection(FirestoreCollections.users)
        .doc(widget.otherUid).get();
      final token = (otherDoc.data() as Map?)?['fcmToken'] as String?;
      if (token != null && token.isNotEmpty) {
        final meDoc = await db.collection(FirestoreCollections.users)
          .doc(_uid).get();
        final myName = (meDoc.data() as Map?)?['name'] as String? ?? 'New message';
        await http.post(
          Uri.parse('https://campusfind-notify-vercel.vercel.app/api/notify-message'),
          headers: {'Content-Type': 'application/json', 'x-secret': 'cfp_9k2mLx7Q'},
          body: jsonEncode({
            'token': token,
            'senderName': myName,
            'text': text,
            'chatId': widget.chatId,
          }),
        );
      }
    } catch (e) {
      debugPrint('notify-message push error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(0,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final initials = widget.otherName.isNotEmpty
      ? widget.otherName[0].toUpperCase() : 'U';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => UserProfileScreen(uid: widget.otherUid))),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(child: widget.otherPhotoUrl != null
                ? CachedNetworkImage(imageUrl: widget.otherPhotoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _AvatarWidget(initials))
                : _AvatarWidget(initials)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherName, style: AppTextStyles.titleMedium),
                Text('Re: ${widget.postTitle}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
        ),
      ),

      body: Column(children: [
        Expanded(
          child: !_initialLoaded
            ? const Center(child: CircularProgressIndicator())
            : _msgs.isEmpty
              ? Center(child: Text('Say hi! 👋',
                  style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) {
                    final m = _msgs[i];
                    return _Bubble(
                      text:     m.text,
                      imageUrl: m.imageUrl,
                      isMe:     m.senderId == _uid,
                      time:     DateTime.tryParse(m.createdAt),
                      pending:  m.pending,
                    );
                  }),
        ),

        // Input bar — padding bottom from MediaQuery.padding (safe area only, not keyboard)
        Container(
          color: AppColors.surface,
          padding: EdgeInsets.fromLTRB(
            8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
          child: Row(children: [
            IconButton(
              icon: _sendingPhoto
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.photo_outlined, color: AppColors.primary),
              onPressed: _sendingPhoto ? null : _pickPhoto),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendText,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20))),
          ]),
        ),
      ]),
    );
  }
}

// ── Bubble ────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final bool isMe, pending;
  final DateTime? time;
  const _Bubble({required this.text, required this.isMe,
    required this.pending, this.imageUrl, this.time});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.65;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: pending ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(16),
              topRight:    const Radius.circular(16),
              bottomLeft:  Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16)),
            boxShadow: AppShadows.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo
              if (imageUrl != null)
                GestureDetector(
                  onTap: () => _openFullscreen(context, imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(
                        text.isEmpty ? (isMe ? 16 : 4) : 0),
                      bottomRight: Radius.circular(
                        text.isEmpty ? (isMe ? 4 : 16) : 0)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: maxW,
                      // Portrait: ~56% wide = ~1:1.3 feel; landscape auto
                      fit: BoxFit.cover,
                      memCacheWidth: 480,
                      placeholder: (_, __) => Container(
                        width: maxW, height: 180,
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (_, __, ___) => Container(
                        width: maxW, height: 100,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),

              // Text
              if (text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: Text(text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isMe ? Colors.white : AppColors.textPrimary))),

              // Time + pending icon
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (time != null)
                    Text(AppDateUtils.timeAgo(time!),
                      style: AppTextStyles.caption.copyWith(
                        color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textSecondary,
                        fontSize: 10)),
                  if (isMe && pending) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.access_time_rounded,
                      size: 10, color: Colors.white.withOpacity(0.7)),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Photo')),
        body: Center(child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain))),
      )));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final String initial;
  const _AvatarWidget(this.initial);
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primaryLight,
    child: Center(child: Text(initial,
      style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary))));
}