import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/errors/app_failures.dart';
import 'cloudinary_service.dart';

Future<Result<CloudinaryUploadResult>> uploadBytesToCloudinary(
  Uint8List bytes, String fileName, String folder,
  String cloudName, String preset,
) async {
  try {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Result.success(CloudinaryUploadResult(
        publicId: json['public_id'] as String,
        secureUrl: json['secure_url'] as String,
        width: json['width'] as int,
        height: json['height'] as int,
        format: json['format'] as String,
        bytes: json['bytes'] as int,
      ));
    }
    return Result.error(StorageFailure.uploadFailed());
  } catch (_) {
    return Result.error(StorageFailure.uploadFailed());
  }
}