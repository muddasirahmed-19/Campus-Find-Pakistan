import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
//  SECURITY UTILS
// ─────────────────────────────────────────────
class SecurityUtils {
  SecurityUtils._();

  /// SHA-256 hash for verification answers (stored in Firestore)
  static String hashAnswer(String answer) {
    final normalized = answer.trim().toLowerCase();
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Compare raw answer to stored hash
  static bool verifyAnswer(String rawAnswer, String storedHash) {
    return hashAnswer(rawAnswer) == storedHash;
  }

  /// Generate 6-digit handoff OTP
  static String generateHandoffCode() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000; // 100000 – 999999
    return code.toString();
  }

  /// Generate UUID v4
  static String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()
        .replaceAllMapped(RegExp(r'(.{8})(.{4})(.{4})(.{4})(.{12})'),
          (m) => '${m[1]}-${m[2]}-${m[3]}-${m[4]}-${m[5]}');
  }
}

// ─────────────────────────────────────────────
//  DATE / TIME UTILS
// ─────────────────────────────────────────────
class DateUtils {
  DateUtils._();

  static final _dateFormat   = DateFormat('dd MMM yyyy');
  static final _timeFormat   = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _firestoreFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime dt) => _dateFormat.format(dt);
  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);
  static String formatForFirestore(DateTime dt) => _firestoreFormat.format(dt);

  static String timeAgo(DateTime dt) => timeago.format(dt);

  static bool isExpired(DateTime expiresAt) =>
      DateTime.now().isAfter(expiresAt);

  static DateTime postExpiryDate() =>
      DateTime.now().add(const Duration(days: 30));

  static DateTime handoffExpiryDate() =>
      DateTime.now().add(const Duration(hours: 48));

  static String remainingTime(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d remaining';
    if (diff.inHours > 0) return '${diff.inHours}h remaining';
    return '${diff.inMinutes}m remaining';
  }
}

// ─────────────────────────────────────────────
//  STRING UTILS
// ─────────────────────────────────────────────
class StringUtils {
  StringUtils._();

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String formatPhoneForDisplay(String phone) {
    // Normalize to +92XXXXXXXXXX then format as +92 3XX XXXXXXX
    final normalized = phone.startsWith('+92')
        ? phone
        : '+92${phone.replaceAll(RegExp(r'^(0092|0)'), '')}';
    if (normalized.length == 13) {
      return '${normalized.substring(0, 3)} ${normalized.substring(3, 6)} ${normalized.substring(6, 9)} ${normalized.substring(9)}';
    }
    return phone;
  }

  static String formatCurrency(int amount) {
    final formatter = NumberFormat('#,##0', 'en_PK');
    return 'PKR ${formatter.format(amount)}';
  }

  static bool isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }
}

// ─────────────────────────────────────────────
//  IMAGE UTILS
// ─────────────────────────────────────────────
class ImageUtils {
  ImageUtils._();

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  static bool isSizeValid(int sizeInBytes) =>
      sizeInBytes <= maxFileSizeBytes;

  static bool isExtensionValid(String path) {
    final ext = path.split('.').last.toLowerCase();
    return allowedExtensions.contains(ext);
  }

  /// Build Cloudinary thumbnail URL with transformations
  static String cloudinaryThumb(String publicId, {
    int width = 400, int height = 400, String crop = 'fill',
  }) {
    return 'https://res.cloudinary.com/YOUR_CLOUD/image/upload/'
        'c_$crop,w_$width,h_$height,q_auto,f_auto/$publicId';
  }
}
