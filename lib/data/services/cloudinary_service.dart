import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_failures.dart';

import 'cloudinary_service_stub.dart'
    if (dart.library.html) 'cloudinary_service_web.dart'
    if (dart.library.io) 'cloudinary_service_mobile.dart';

class CloudinaryUploadResult {
  final String publicId, secureUrl, format;
  final int width, height, bytes;
  const CloudinaryUploadResult({required this.publicId, required this.secureUrl, required this.width, required this.height, required this.format, required this.bytes});
  Map<String, dynamic> toMap() => {'publicId': publicId, 'secureUrl': secureUrl, 'width': width, 'height': height, 'format': format, 'bytes': bytes};
  factory CloudinaryUploadResult.fromMap(Map<String, dynamic> m) => CloudinaryUploadResult(publicId: m['publicId']??'', secureUrl: m['secureUrl']??'', width: m['width']??0, height: m['height']??0, format: m['format']??'', bytes: m['bytes']??0);
}

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();
  final String _cloudName = AppConstants.cloudinaryName;
  String thumbnailUrl(String id, {int w=400, int h=400}) => 'https://res.cloudinary.com/$_cloudName/image/upload/c_fill,w_$w,h_$h,q_auto,f_auto/$id';
  String fullUrl(String id) => 'https://res.cloudinary.com/$_cloudName/image/upload/q_auto,f_auto/$id';
  Future<Result<CloudinaryUploadResult>> uploadFromBytes(Uint8List bytes, String fileName, {String folder='campusfind/posts'}) =>
    uploadBytesToCloudinary(bytes, fileName, folder, AppConstants.cloudinaryName, AppConstants.cloudinaryPreset);
}