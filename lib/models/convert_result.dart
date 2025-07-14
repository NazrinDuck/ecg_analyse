import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:flutter/material.dart';

class ConvertResult {
  final Image convertImage; // 预处理后的图像
  final Uint8List convertImageBytes;

  ConvertResult({required this.convertImage, required this.convertImageBytes});

  factory ConvertResult.fromJson(Map<String, dynamic> json) {
    Uint8List bytes = Base64Decoder().convert(
      json['convert_b64image'] as String,
    );
    // 解析主要的预测结果
    final Image convertImage = Image.memory(bytes, fit: BoxFit.contain);

    final convertResult = ConvertResult(
      convertImage: convertImage,
      convertImageBytes: bytes,
    );

    return convertResult;
  }
}
