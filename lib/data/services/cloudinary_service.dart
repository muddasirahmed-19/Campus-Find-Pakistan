import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  final String _cloudName = AppConstants.cloudinaryName;
  final String _preset    = AppConstants.cloudinaryPreset;

  String get _uploadUrl =>
    'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload single image bytes, returns secure URL or throws
  Future<String> uploadImageBytes(
    Uint8List bytes, {
    String fileName = 'image.jpg',
    String folder   = 'campusfind/posts',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _preset
      ..fields['folder']        = folder
      ..files.add(http.MultipartFile.fromBytes(
        'file', bytes, filename: fileName));

    final streamed  = await request.send()
      .timeout(const Duration(seconds: 30));
    final response  = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final url  = json['secure_url'] as String?;
      if (url == null) throw Exception('No URL in Cloudinary response');
      return url;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final msg  = body['error']?['message'] ?? 'Unknown error';
      throw Exception('Cloudinary [${response.statusCode}]: $msg');
    }
  }

  /// Upload multiple images, returns list of uploaded URLs
  Future<List<String>> uploadMultiple(
    List<Uint8List> images, {
    String folder = 'campusfind/posts',
    void Function(int done, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      try {
        final url = await uploadImageBytes(
          images[i],
          fileName: 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          folder: folder,
        );
        urls.add(url);
      } catch (e) {
        // Log but continue uploading remaining images
        debugPrintUploadError('Image ${i+1} failed: $e');
      }
      onProgress?.call(i + 1, images.length);
    }
    return urls;
  }

  /// Build optimized thumbnail URL
  String thumbnailUrl(String url, {int w = 400, int h = 400}) {
    // If it's already a Cloudinary URL, add transformations
    if (url.contains('cloudinary.com')) {
      return url.replaceFirst(
        '/upload/', '/upload/c_fill,w_$w,h_$h,q_auto,f_auto/');
    }
    return url;
  }
}

void debugPrintUploadError(String msg) {
  // ignore: avoid_print
  print('[Cloudinary] $msg');
}