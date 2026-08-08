// ─────────────────────────────────────────────
//  APP VALIDATORS
//  All validation logic in one place
// ─────────────────────────────────────────────
import '../constants/app_constants.dart';

class AppValidators {
  AppValidators._();

  // ── Full Name ────────────────────────────────
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must not exceed 50 characters';
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s\u0600-\u06FF]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  // ── Pakistani Phone Number ───────────────────
  // Accepts: 03XXXXXXXXX | +923XXXXXXXXX | 00923XXXXXXXXX
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.trim().replaceAll(' ', '').replaceAll('-', '');
    final phoneRegex = RegExp(r'^(\+92|0092|0)?3[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid Pakistani number (03XXXXXXXXX)';
    }
    return null;
  }

  // ── Normalize Phone to +92 format ────────────
  static String normalizePhone(String value) {
    var cleaned = value.trim().replaceAll(' ', '').replaceAll('-', '');
    if (cleaned.startsWith('0092')) {
      return '+92${cleaned.substring(4)}';
    } else if (cleaned.startsWith('92') && !cleaned.startsWith('+')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      return '+92${cleaned.substring(1)}';
    }
    return cleaned;
  }

  // ── University Email ─────────────────────────
  static String? universityEmail(String? value, String? expectedDomain) {
    if (value == null || value.trim().isEmpty) {
      return 'University email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    if (expectedDomain != null && expectedDomain.isNotEmpty) {
      if (!value.trim().toLowerCase().endsWith('@$expectedDomain') &&
          !value.trim().toLowerCase().endsWith('.$expectedDomain')) {
        return 'Email must be from @$expectedDomain';
      }
    }
    return null;
  }

  // ── Password ─────────────────────────────────
  // 8+ chars, 1 uppercase, 1 number, 1 special char
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must include at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must include at least one number';
    }
    if (!RegExp(r'[!@#\$&*~%^()_+=\-]').hasMatch(value)) {
      return 'Must include at least one special character (!@#\$&*)';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ── OTP ──────────────────────────────────────
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.trim().length != AppConstants.otpLength) {
      return 'Enter the ${AppConstants.otpLength}-digit code';
    }
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'OTP must contain digits only';
    }
    return null;
  }

  // ── Post Title ───────────────────────────────
  static String? postTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 5) {
      return 'Title must be at least 5 characters';
    }
    if (value.trim().length > 100) {
      return 'Title must not exceed 100 characters';
    }
    return null;
  }

  // ── Post Description ─────────────────────────
  static String? postDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 20) {
      return 'Description must be at least 20 characters';
    }
    if (value.trim().length > 1000) {
      return 'Description must not exceed 1000 characters';
    }
    return null;
  }

  // ── Post Date ────────────────────────────────
  static String? postDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    final now = DateTime.now();
    if (value.isAfter(now)) {
      return 'Date cannot be in the future';
    }
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    if (value.isBefore(sixtyDaysAgo)) {
      return 'Date cannot be more than 60 days ago';
    }
    return null;
  }

  // ── Reward Amount ─────────────────────────────
  static String? rewardAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final amount = int.tryParse(value.trim());
    if (amount == null) {
      return 'Enter a valid amount in PKR';
    }
    if (amount < AppConstants.minRewardPKR) {
      return 'Minimum reward is PKR ${AppConstants.minRewardPKR}';
    }
    if (amount > AppConstants.maxRewardPKR) {
      return 'Maximum reward is PKR ${AppConstants.maxRewardPKR}';
    }
    return null;
  }

  // ── Verification Question ─────────────────────
  static String? verificationQuestion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Verification question is required for found items';
    }
    if (value.trim().length < 10) {
      return 'Question must be at least 10 characters';
    }
    if (value.trim().length > 200) {
      return 'Question must not exceed 200 characters';
    }
    return null;
  }

  // ── Verification Answer ───────────────────────
  static String? verificationAnswer(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Answer is required';
    }
    if (value.trim().length < 2) {
      return 'Answer is too short';
    }
    if (value.trim().length > 100) {
      return 'Answer must not exceed 100 characters';
    }
    return null;
  }

  // ── Location Description ──────────────────────
  static String? locationDescription(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    if (value.trim().length > 200) {
      return 'Location note must not exceed 200 characters';
    }
    return null;
  }

  // ── Chat Message ──────────────────────────────
  static String? chatMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (value.trim().length > 2000) {
      return 'Message too long (max 2000 characters)';
    }
    return null;
  }

  // ── Report Reason ─────────────────────────────
  static String? reportReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a reason';
    }
    if (value.trim().length < 10) {
      return 'Reason must be at least 10 characters';
    }
    if (value.trim().length > 500) {
      return 'Reason must not exceed 500 characters';
    }
    return null;
  }

  // ── Generic Required ──────────────────────────
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

// ─────────────────────────────────────────────
//  PASSWORD STRENGTH HELPER
// ─────────────────────────────────────────────
enum PasswordStrength { weak, medium, strong }

class PasswordStrengthChecker {
  static PasswordStrength check(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~%^()_+=\-]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  static String get label {
    return '';
  }

  static String labelFor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:   return 'Weak';
      case PasswordStrength.medium: return 'Medium';
      case PasswordStrength.strong: return 'Strong';
    }
  }
}
