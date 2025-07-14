import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/diag_result.dart';
import '../models/pie_chart.dart';

class ResultScreen extends StatelessWidget {
  final DiagResult diagResult;

  const ResultScreen({super.key, required this.diagResult});

  @override
  Widget build(BuildContext context) {
    final confidences = diagResult.confidences;
    final (mainDiagType, mainConfidence) = confidences.first;

    final color = mainDiagType.color;
    final bgColor = color.withValues(alpha: 0.1);

    return Scaffold(
      appBar: AppBar(
        title: Text('分析结果'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt),
            tooltip: '保存报告',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('报告保存功能即将上线')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 结果摘要
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 1),
              ),
              child: Row(
                children: [
                  Icon(mainDiagType.icon, color: color, size: 48),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '诊断结果: ${mainDiagType.translate()}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '置信度: ${(mainConfidence * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          mainDiagType.desc,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 选择的ECG片段
            SizedBox(height: 16),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '经过处理的ECG片段',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '以下为经过处理的心电图片段',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 4 / 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: diagResult.processedImage!,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // 预测结果详情 - 更新为显示所有类别
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '预测结果详情',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // 显示所有类别的置信度
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '各类别置信度',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...diagResult.confidences.map((elem) {
                          final (diagType, confidence) = elem;
                          final classColor = diagType.color;
                          final chineseName = diagType.translate();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      diagType.icon,
                                      color: classColor,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '$chineseName (${diagType.name})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: classColor,
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      '${(confidence * 100).toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: confidence,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      classColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),

                    SizedBox(height: 16),

                    // 饼图显示所有类别
                    /**/
                    SizedBox(
                      height: 360,
                      child: CustomPaint(
                        painter: ConfidencePieChart(
                          confidences: {
                            for (var diagType in confidences)
                              diagType.$1.name: diagType.$2,
                          },
                          colors: {
                            for (var diagType in confidences)
                              diagType.$1.name: diagType.$1.color,
                          },
                          labels: {
                            for (var diagType in confidences)
                              diagType.$1.name: diagType.$1.translate(),
                          },
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Grad-CAM 热图
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grad-CAM热图分析',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '高亮区域显示了AI模型识别关键特征的区域',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: diagResult.heatmapImage,
                        /*
                        Image.memory(
                          // Must add some check
                          base64Decode(diagResult.heatmapBase64),
                          fit: BoxFit.contain,
                          height: 200,
                          width: double.infinity,
                        ),
                        */
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_buildGradientLegend()],
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        '较低关注度 ←→ 较高关注度',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // 说明信息
            Card(
              elevation: 2,
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '注意事项',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '此分析结果仅供参考，不能替代专业医生的诊断。如有疑问，请咨询专业医疗人员。',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientLegend() {
    return Container(
      width: 200,
      height: 20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade300,
            Colors.blue.shade600,
            Colors.yellow,
            Colors.orange,
            Colors.red,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
