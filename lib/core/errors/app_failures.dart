// ─────────────────────────────────────────────
//  ERROR HANDLING
// ─────────────────────────────────────────────

// Base app failure
abstract class AppFailure {
  final String message;
  final String? code;
  const AppFailure(this.message, {this.code});

  @override
  String toString() => 'AppFailure($code): $message';
}

// Auth failures
class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.code});

  factory AuthFailure.invalidPhone() =>
      const AuthFailure('Invalid phone number. Use format: 03XXXXXXXXX',
          code: 'invalid-phone');

  factory AuthFailure.invalidOtp() =>
      const AuthFailure('Incorrect OTP. Please try again.', code: 'invalid-otp');

  factory AuthFailure.otpExpired() =>
      const AuthFailure('OTP has expired. Request a new one.', code: 'otp-expired');

  factory AuthFailure.tooManyRequests() =>
      const AuthFailure('Too many attempts. Please wait a moment.',
          code: 'too-many-requests');

  factory AuthFailure.userNotFound() =>
      const AuthFailure('No account found. Please sign up first.',
          code: 'user-not-found');

  factory AuthFailure.emailAlreadyExists() =>
      const AuthFailure('This email is already registered.',
          code: 'email-already-in-use');

  factory AuthFailure.wrongPassword() =>
      const AuthFailure('Incorrect password. Try again.', code: 'wrong-password');

  factory AuthFailure.networkError() =>
      const AuthFailure('No internet connection. Check your network.',
          code: 'network-error');

  factory AuthFailure.unknown(String message) =>
      AuthFailure('Something went wrong: $message', code: 'unknown');
}

// Firestore / Data failures
class DataFailure extends AppFailure {
  const DataFailure(super.message, {super.code});

  factory DataFailure.notFound(String item) =>
      DataFailure('$item not found.', code: 'not-found');

  factory DataFailure.permissionDenied() =>
      const DataFailure('You don\'t have permission to do this.',
          code: 'permission-denied');

  factory DataFailure.networkError() =>
      const DataFailure('No internet connection.', code: 'network-error');

  factory DataFailure.unknown(String message) =>
      DataFailure('Something went wrong: $message', code: 'unknown');
}

// Storage (Cloudinary) failures
class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.code});

  factory StorageFailure.uploadFailed() =>
      const StorageFailure('Image upload failed. Try again.', code: 'upload-failed');

  factory StorageFailure.fileTooLarge() =>
      const StorageFailure('Image is too large. Maximum size is 5MB.',
          code: 'file-too-large');

  factory StorageFailure.invalidFormat() =>
      const StorageFailure('Only JPG and PNG images are allowed.',
          code: 'invalid-format');
}

// Post failures
class PostFailure extends AppFailure {
  const PostFailure(super.message, {super.code});

  factory PostFailure.alreadyClaimed() =>
      const PostFailure('This item already has a pending claim.',
          code: 'already-claimed');

  factory PostFailure.ownPost() =>
      const PostFailure('You cannot claim your own post.', code: 'own-post');

  factory PostFailure.postExpired() =>
      const PostFailure('This post has expired.', code: 'post-expired');

  factory PostFailure.wrongAnswer() =>
      const PostFailure('Incorrect answer. Please try again.',
          code: 'wrong-answer');
}

// ─────────────────────────────────────────────
//  RESULT TYPE (success / failure)
// ─────────────────────────────────────────────
class Result<T> {
  final T? data;
  final AppFailure? failure;

  const Result.success(this.data) : failure = null;
  const Result.error(this.failure) : data = null;

  bool get isSuccess => failure == null;
  bool get isError   => failure != null;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) error,
  }) {
    if (isSuccess) return success(data as T);
    return error(failure!);
  }
}

// ─────────────────────────────────────────────
//  FIREBASE AUTH ERROR MAPPER
// ─────────────────────────────────────────────
class FirebaseErrorMapper {
  static AuthFailure fromCode(String code) {
    switch (code) {
      case 'invalid-phone-number':     return AuthFailure.invalidPhone();
      case 'invalid-verification-code': return AuthFailure.invalidOtp();
      case 'code-expired':             return AuthFailure.otpExpired();
      case 'too-many-requests':        return AuthFailure.tooManyRequests();
      case 'user-not-found':           return AuthFailure.userNotFound();
      case 'email-already-in-use':     return AuthFailure.emailAlreadyExists();
      case 'wrong-password':           return AuthFailure.wrongPassword();
      case 'network-request-failed':   return AuthFailure.networkError();
      default:                          return AuthFailure.unknown(code);
    }
  }
}
