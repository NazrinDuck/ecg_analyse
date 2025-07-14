import 'dart:convert';
import 'dart:io';

// import 'package:flutter/foundation.dart';
import 'package:ecg_analyse/models/convert_result.dart';
import 'package:flutter/services.dart';
//import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/diag_result.dart';

class ApiService {
  // 修改为固定的299x299尺寸
  static const int fixedWidth = 299;
  static const int fixedHeight = 299;

  Future<DiagResult> predictEcg(
    Uint8List imageBytes, {
    required Map cropParams,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.predictEndpoint}');

    try {
      // 获取图像尺寸用于验证
      /*
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = await decodeImageFromList(imageBytes);
      final imageWidth = decodedImage.width;
      final imageHeight = decodedImage.height;
      */

      // 直接使用框选传入的参数，但确保宽高为299x299
      final adjustedCropParams = {
        "left": cropParams["left"] ?? 0,
        "top": cropParams["top"] ?? 0,
        "width": fixedWidth,
        "height": fixedHeight,
      };

      print('原始裁剪参数: $cropParams');
      print('调整后的裁剪参数: $adjustedCropParams');

      // 创建multipart请求
      var request = http.MultipartRequest('POST', uri);

      // 添加文件
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          filename: "a.png",
          imageBytes,
          contentType: MediaType('image', 'png'),
        ),
        /*
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'png'),
        ),
        */
      );

      // 添加裁剪参数 - 使用调整后的参数
      request.fields['crop_params'] = jsonEncode(adjustedCropParams);
      print(request.files.first.field);
      print(request.files.first.length);

      // 更新处理参数 - 完全跳过处理流程
      final processParams = {
        "threshold": -1, // 设置为-1，表示不应用二值化
        "blur_radius": 0, // 设置为0，表示不应用模糊
      };

      // 设置尺寸参数，确保保持299x299
      final resizeParams = {
        "target_width": 299,
        "target_height": 299,
        "fill_color": 255,
      };

      request.fields['process_params'] = jsonEncode(processParams);
      request.fields['resize_params'] = jsonEncode(resizeParams);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return DiagResult.fromJson(json.decode(response.body));
      } else {
        throw Exception('预测失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  Future<ConvertResult> convertImage(File textFile) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.convertEndpoint}');
    try {
      var request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath('file', textFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return ConvertResult.fromJson(json.decode(response.body));
      } else {
        throw Exception('预测失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }
}
