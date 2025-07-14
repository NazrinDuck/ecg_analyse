import 'package:ecg_analyse/models/convert_result.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ConvertScreen extends StatelessWidget {
  final ConvertResult convertResult;
  final String textFileName;

  const ConvertScreen({
    super.key,
    required this.convertResult,
    required this.textFileName,
  });

  Future<void> _saveImage(context) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: "请输入图片名称：",
      fileName: 'output.png',
      type: FileType.image,
      bytes: convertResult.convertImageBytes,
    );

    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('成功保存图片至$result')));
    }

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('心电图转换'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt),
            tooltip: '保存图片',
            onPressed: () => {_saveImage(context)},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '心电图',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '以下为文件$textFileName转换成的心电图，标度非规范，仅供参考',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    Card(child: convertResult.convertImage),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.image),
              label: Text('分析该图像'),
              onPressed: () => {Navigator.pop(context, true)},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
