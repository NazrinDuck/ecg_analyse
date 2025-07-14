import 'dart:math' show cos, sin;

import 'package:flutter/material.dart';

class ConfidencePieChart extends CustomPainter {
  final Map<String, double> confidences;
  final Map<String, Color> colors;
  final Map<String, String> labels;

  ConfidencePieChart({
    required this.confidences,
    required this.colors,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 8; // 调整为更小的饼图

    // 确保置信度总和为1
    double total = confidences.values.fold(0, (sum, value) => sum + value);
    Map<String, double> normalizedConfidences = {};

    if (total > 0) {
      confidences.forEach((key, value) {
        normalizedConfidences[key] = value / total;
      });
    } else {
      confidences.forEach((key, value) {
        normalizedConfidences[key] = 1.0 / confidences.length;
      });
    }

    // 绘制饼图
    double startAngle = -1.5708; // 从上方开始 (-90度)

    normalizedConfidences.forEach((className, confidence) {
      if (confidence > 0) {
        final sweepAngle = confidence * 6.2832; // 2π
        final paint =
            Paint()
              ..color = colors[className] ?? Colors.grey
              ..style = PaintingStyle.fill;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          true,
          paint,
        );

        // 绘制标签线和文本
        final midAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 1.3;
        final labelPosition = Offset(
          center.dx + labelRadius * cos(midAngle),
          center.dy + labelRadius * sin(midAngle),
        );

        // 绘制线条
        final linePaint =
            Paint()
              ..color = colors[className] ?? Colors.grey
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke;

        final innerPoint = Offset(
          center.dx + radius * 0.8 * cos(midAngle),
          center.dy + radius * 0.8 * sin(midAngle),
        );

        final outerPoint = Offset(
          center.dx + radius * 1.1 * cos(midAngle),
          center.dy + radius * 1.1 * sin(midAngle),
        );

        canvas.drawLine(innerPoint, outerPoint, linePaint);

        // 绘制标签文本
        final labelText =
            '${labels[className] ?? className}: ${(confidence * 100).toStringAsFixed(1)}%';
        final textStyle = TextStyle(
          color: colors[className] ?? Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: labelText, style: textStyle);

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        double textX = labelPosition.dx;
        double textY = labelPosition.dy - textPainter.height / 2;

        // 调整标签位置，避免超出边界
        if (textX < 0) textX = 0;
        if (textX + textPainter.width > size.width) {
          textX = size.width - textPainter.width;
        }
        if (textY < 0) textY = 0;
        if (textY + textPainter.height > size.height) {
          textY = size.height - textPainter.height;
        }

        textPainter.paint(canvas, Offset(textX, textY));

        startAngle += sweepAngle;
      }
    });

    // 绘制中心圆
    final centerPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);

    // 绘制中心文本 - 显示最高置信度的类别
    final highestConfidenceClass =
        normalizedConfidences.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

    final highestConfidence =
        normalizedConfidences[highestConfidenceClass] ?? 0;
    final centerLabel =
        '${labels[highestConfidenceClass] ?? highestConfidenceClass}\n${(highestConfidence * 100).toStringAsFixed(1)}%';

    final centerTextStyle = TextStyle(
      color: colors[highestConfidenceClass] ?? Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    final centerTextSpan = TextSpan(text: centerLabel, style: centerTextStyle);

    final centerTextPainter = TextPainter(
      text: centerTextSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    centerTextPainter.layout();

    final centerTextOffset = Offset(
      center.dx - centerTextPainter.width / 2,
      center.dy - centerTextPainter.height / 2,
    );

    centerTextPainter.paint(canvas, centerTextOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
