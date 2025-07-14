import 'package:flutter/services.dart';
import 'dart:convert';

import './diag_type.dart';
import 'package:flutter/material.dart';

class DiagResult {
  final Image? heatmapImage; // 热图的base64编码
  final Image? processedImage; // 预处理后的图像
  List<(DiagType, double)> confidences = [];

  DiagResult({
    required this.heatmapImage,
    this.processedImage,
    List<(DiagType, double)>? allConfidences,
  }) {
    // 如果没有提供所有置信度，默认没有
    confidences = allConfidences ?? [];
  }

  factory DiagResult.fromJson(Map<String, dynamic> json) {
    Uint8List processedBytes = Base64Decoder().convert(
      json['processed_b64image'] as String,
    );

    Uint8List heatmapBytes = Base64Decoder().convert(
      json['heatmap_b64image'] as String,
    );

    // 解析主要的预测结果
    final Image processedImage = Image.memory(
      processedBytes,
      fit: BoxFit.fitWidth,
    );

    final Image heatmapImage = Image.memory(
      heatmapBytes,
      fit: BoxFit.fitWidth,
      height: 200,
      width: double.infinity,
    );

    final diagResult = DiagResult(
      heatmapImage: heatmapImage,
      processedImage: processedImage,
    );

    // 如果API返回了所有类别的置信度，解析它们
    if (json.containsKey('confidences')) {
      Map<String, dynamic> confidences = json['confidences'];
      confidences.forEach((key, value) {
        diagResult.confidences += [
          (
            DiagType.fromString(key),
            value is double ? value : value.toDouble(),
          ),
        ];
      });
    } else {
      throw Exception("错误：未受到confidences，请联系工作人员");
    }

    diagResult.confidences.sort((a, b) => b.$2.compareTo(a.$2));

    return diagResult;
  }
}
