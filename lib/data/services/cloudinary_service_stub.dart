import 'package:flutter/foundation.dart';
import '../../core/errors/app_failures.dart';
import 'cloudinary_service.dart';
Future<Result<CloudinaryUploadResult>> uploadBytesToCloudinary(Uint8List bytes, String fileName, String folder, String cloudName, String preset) async =>
  Result.error(const StorageFailure('Upload not supported on this platform'));