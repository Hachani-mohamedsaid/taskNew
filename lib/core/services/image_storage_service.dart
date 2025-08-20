import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker_web/image_picker_web.dart';

class ImageStorageService {
  static const String _imgbbApiKey = '05b2177b559da91f49c845e58ba5d7e9';
  static const String _imgbbUploadUrl = 'https://api.imgbb.com/1/upload';
  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB

  Future<Uint8List> _convertImageToBytes(XFile file) async {
    try {
      if (kIsWeb) {
        // Solution optimale pour le web
        final mediaInfo = await ImagePickerWeb.getImageInfo;
        if (mediaInfo?.data != null) return mediaInfo!.data!;
        
        // Fallback pour les URLs blob
        if (file.path.startsWith('blob:')) {
          final response = await http.get(Uri.parse(file.path));
          if (response.statusCode == 200) return response.bodyBytes;
        }
      }
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Image conversion failed: ${e.toString()}');
    }
  }

  Future<String?> uploadImage(XFile imageFile, {required String userId}) async {
    try {
      final bytes = await _convertImageToBytes(imageFile);
      
      if (bytes.length > _maxFileSize) {
        throw Exception('Image size exceeds 5MB limit');
      }

      final request = http.MultipartRequest('POST', Uri.parse(_imgbbUploadUrl))
        ..fields['key'] = _imgbbApiKey
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'user_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (jsonData['success'] == true) {
        return jsonData['data']['display_url'] ?? jsonData['data']['url'];
      } else {
        throw Exception(jsonData['error']['message'] ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('Image upload error: ${e.toString()}');
      rethrow;
    }
  }

  static bool isImageUrlValid(String? url) {
    return url != null && 
           url.isNotEmpty && 
           (url.startsWith('http://') || url.startsWith('https://'));
  }
}