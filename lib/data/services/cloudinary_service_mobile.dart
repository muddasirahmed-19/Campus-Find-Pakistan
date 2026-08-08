import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/errors/app_failures.dart';
import 'cloudinary_service.dart';
Future<Result<CloudinaryUploadResult>> uploadBytesToCloudinary(Uint8List bytes, String fileName, String folder, String cloudName, String preset) async {
  try {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return Result.success(CloudinaryUploadResult(publicId: j['public_id'], secureUrl: j['secure_url'], width: j['width'], height: j['height'], format: j['format'], bytes: j['bytes']));
    }
    return Result.error(StorageFailure.uploadFailed());
  } catch (_) { return Result.error(StorageFailure.uploadFailed()); }
}