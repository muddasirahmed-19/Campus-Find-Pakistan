import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class SecurityUtils {
  SecurityUtils._();
  static String hashAnswer(String answer) {
    final bytes = utf8.encode(answer.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }
  static bool verifyAnswer(String raw, String hash) => hashAnswer(raw) == hash;
  static String generateHandoffCode() =>
    (Random.secure().nextInt(900000) + 100000).toString();
}

// Renamed to AppDateUtils to avoid conflict with Flutter's built-in DateUtils
class AppDateUtils {
  AppDateUtils._();
  static final _date     = DateFormat('dd MMM yyyy');
  static final _time     = DateFormat('hh:mm a');
  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatDate(DateTime dt)     => _date.format(dt);
  static String formatTime(DateTime dt)     => _time.format(dt);
  static String formatDateTime(DateTime dt) => _dateTime.format(dt);
  static String timeAgo(DateTime dt)        => timeago.format(dt);
  static bool   isExpired(DateTime exp)     => DateTime.now().isAfter(exp);

  static String remainingTime(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0)  return '${diff.inDays}d remaining';
    if (diff.inHours > 0) return '${diff.inHours}h remaining';
    return '${diff.inMinutes}m remaining';
  }
}

class StringUtils {
  StringUtils._();
  static String truncate(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max)}...';

  static String capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1).toLowerCase();

  static String formatCurrency(int amount) {
    final f = NumberFormat('#,##0', 'en_PK');
    return 'PKR ${f.format(amount)}';
  }
}

class ImageUtils {
  ImageUtils._();
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static bool isSizeValid(int bytes) => bytes <= maxFileSizeBytes;
}