import 'package:flutter/foundation.dart';
import '../../core/errors/app_failures.dart';
import 'cloudinary_service.dart';
Future<Result<CloudinaryUploadResult>> uploadBytesToCloudinary(Uint8List bytes, String fileName, String folder, String cloudName, String preset) async =>
  const Result.error(StorageFailure('Upload not supported on this platform'));