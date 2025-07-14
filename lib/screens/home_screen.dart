import 'dart:io';

import 'package:ecg_analyse/screens/convert_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import './result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Uint8List? _selectedImageBytes;

  bool _isLoading = false;

  // 原始图像上选框的固定大小 - 与full_process.py中保持一致
  final double originalSelectionWidth = 1064;
  final double originalSelectionHeight = 245;

  // 选框在UI上的位置和大小
  double selectionLeft = 0;
  double selectionTop = 0;
  double selectionWidth = 0;
  double selectionHeight = 0;

  // 原始图像上选框的位置
  double originalSelectionLeft = 618;
  double originalSelectionTop = 1738;

  // 图像尺寸
  Size? _imageSize;

  // 图像尺寸在UI上的大小
  Size? _displaySize;

  // 图像缩放比例(原始尺寸/显示尺寸)
  double _scaleX = 1.0;
  double _scaleY = 1.0;

  // 图像控制器
  final TransformationController _transformController =
      TransformationController();

  // 开始拖拽位置
  Offset? _dragStartPosition;

  // 拖拽状态
  bool _isDragging = false;

  // 当前变换的缩放比例
  double _currentScale = 1.0;

  // 图像在容器中的偏移量
  double _scaleFactor = 1.0;

  // 图像容器Key
  final GlobalKey _imageKey = GlobalKey();

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImageBytes = File(result.files.single.path!).readAsBytesSync();
      });

      // 获取图像尺寸并调整选框位置
      await _getImageSize();
    }
  }

  Future<void> _pickText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.files.single.path != null) {
      await _convertImage(File(result.files.single.path!));
    }
  }

  Future<void> _convertImage(File textFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final convertResult = await _apiService.convertImage(textFile);

      if (mounted) {
        final bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ConvertScreen(
                  convertResult: convertResult,
                  textFileName: textFile.path,
                ),
          ),
        );

        if (result != null && result) {
          setState(() {
            _selectedImageBytes = convertResult.convertImageBytes;
          });

          final image = await decodeImageFromList(
            convertResult.convertImageBytes,
          );

          _imageSize = Size(image.width.toDouble(), image.height.toDouble());

          // Wait for layout to be fully complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryGetDisplaySize();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('转换失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 获取图像实际尺寸和计算缩放比例
  Future<void> _getImageSize() async {
    if (_selectedImageBytes == null) return;

    // Get original image dimensions
    final image = await decodeImageFromList(_selectedImageBytes!);
    _imageSize = Size(image.width.toDouble(), image.height.toDouble());

    // Wait for layout to be fully complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryGetDisplaySize();
    });
  }

  void _tryGetDisplaySize() {
    if (_imageKey.currentContext != null) {
      final RenderBox box =
          _imageKey.currentContext!.findRenderObject() as RenderBox;

      // Check if the box has non-zero size
      if (box.size.width > 0 && box.size.height > 0) {
        _displaySize = box.size;

        // Calculate scaling factors
        _calculateScalingFactors();

        // Set the selection box size and position
        _updateSelectionSizeAndPosition();

        // Notify UI to refresh
        if (mounted) setState(() {});
      } else {
        // If size is still zero, retry after a small delay
        Future.delayed(Duration(milliseconds: 50), _tryGetDisplaySize);
      }
    } else {
      // If context is not available, retry after a small delay
      Future.delayed(Duration(milliseconds: 50), _tryGetDisplaySize);
    }
  }

  void _calculateScalingFactors() {
    if (_imageSize == null ||
        _displaySize == null ||
        _displaySize!.width <= 0 ||
        _displaySize!.height <= 0 ||
        _imageSize!.width <= 0 ||
        _imageSize!.height <= 0) {
      return;
    }

    // 计算图像在UI上的显示尺寸
    double imageAspect = _imageSize!.width / _imageSize!.height;
    double containerAspect = _displaySize!.width / _displaySize!.height;

    double displayWidth, displayHeight;

    if (imageAspect > containerAspect) {
      // 图像比容器更宽
      displayWidth = _displaySize!.width;
      displayHeight = displayWidth / imageAspect;
    } else {
      // 图像比容器更高或相等
      displayHeight = _displaySize!.height;
      displayWidth = displayHeight * imageAspect;
    }

    // 计算缩放因子
    _scaleFactor = displayWidth / _imageSize!.width;

    // 计算从显示坐标到原始图像坐标的比例
    _scaleX = _imageSize!.width / displayWidth;
    _scaleY = _imageSize!.height / displayHeight;

    // 打印调试信息
    print('图像实际大小: ${_imageSize!.width}x${_imageSize!.height}');
    print('图像显示大小: ${displayWidth}x${displayHeight}');
    print('缩放因子: $_scaleFactor, 横向比例: $_scaleX, 纵向比例: $_scaleY');

    _updateSelectionSizeAndPosition();
  }

  void _updateSelectionSizeAndPosition() {
    if (_imageSize == null) return;

    final imageWidth = _imageSize!.width * _scaleFactor;
    final imageHeight = _imageSize!.height * _scaleFactor;

    selectionLeft = (originalSelectionLeft * _scaleFactor);
    selectionTop = (originalSelectionTop * _scaleFactor);
    selectionWidth = (originalSelectionWidth * _scaleFactor).clamp(
      0.0,
      imageWidth,
    );
    selectionHeight = (originalSelectionHeight * _scaleFactor).clamp(
      0.0,
      imageHeight,
    );

    double maxLeft = imageWidth - selectionWidth;
    double maxTop = imageHeight - selectionHeight;

    selectionLeft = selectionLeft.clamp(0.0, maxLeft);
    selectionTop = selectionTop.clamp(0.0, maxTop);
    print("Init Left Pos: $selectionLeft");
    print("Init Top Pos: $selectionTop");
  }

  // 处理拖拽开始
  void _onPanStart(DragStartDetails details) {
    if (_selectedImageBytes == null) return;

    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // 检查是否点击在选框内
    if (_isInsideSelection(localPosition)) {
      setState(() {
        _isDragging = true;
        _dragStartPosition = localPosition;
      });
    }
  }

  // 处理拖拽更新
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDragging && _dragStartPosition != null) {
      final RenderBox box =
          _imageKey.currentContext!.findRenderObject() as RenderBox;
      final localPosition = box.globalToLocal(details.globalPosition);

      final dx = localPosition.dx - _dragStartPosition!.dx;
      final dy = localPosition.dy - _dragStartPosition!.dy;

      setState(() {
        // 计算新位置
        double newLeft = selectionLeft + dx / _currentScale;
        double newTop = selectionTop + dy / _currentScale;

        // 确保选框不超出图像边界
        if (_imageSize != null) {
          double maxLeft = (_imageSize!.width / _scaleX) - selectionWidth;
          double maxTop = (_imageSize!.height / _scaleY) - selectionHeight;

          newLeft = newLeft.clamp(0, maxLeft);
          newTop = newTop.clamp(0, maxTop);
        }

        selectionLeft = newLeft;
        selectionTop = newTop;

        // 更新原始图像上的选框位置
        originalSelectionLeft = selectionLeft * _scaleX;
        originalSelectionTop = selectionTop * _scaleY;

        _dragStartPosition = localPosition;
      });
    }
  }

  // 处理拖拽结束
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (_selectedImageBytes == null) return;

    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    // 考虑当前的缩放和平移
    final Matrix4 transform = _transformController.value;
    //final double scale = transform.getMaxScaleOnAxis();

    // 将点击位置转换为图像坐标
    final double x = (localPosition.dx - transform.getTranslation().x);
    final double y = (localPosition.dy - transform.getTranslation().y);

    setState(() {
      // 计算选框的左上角坐标，使点击点成为选框的中心
      selectionLeft = x - selectionWidth / 2;
      selectionTop = y - selectionHeight / 2;

      // 确保选框不超出图像边界
      if (_imageSize != null) {
        double maxLeft = (_imageSize!.width / _scaleX) - selectionWidth;
        double maxTop = (_imageSize!.height / _scaleY) - selectionHeight;

        selectionLeft = selectionLeft.clamp(0.0, maxLeft);
        selectionTop = selectionTop.clamp(0.0, maxTop);
      }

      // 更新原始图像上的选框位置
      originalSelectionLeft = selectionLeft * _scaleX;
      originalSelectionTop = selectionTop * _scaleY;
    });
  }

  // 检查点击位置是否在选框内
  bool _isInsideSelection(Offset position) {
    // 考虑缩放和偏移
    final Matrix4 transform = _transformController.value;
    final double scale = transform.getMaxScaleOnAxis();

    // 获取变换后的选框位置
    final double left = selectionLeft * scale + transform.getTranslation().x;
    final double top = selectionTop * scale + transform.getTranslation().y;
    final double right = left + selectionWidth * scale;
    final double bottom = top + selectionHeight * scale;

    return position.dx >= left &&
        position.dx <= right &&
        position.dy >= top &&
        position.dy <= bottom;
  }

  // 处理缩放变化
  void _onTransformChanged() {
    setState(() {
      _currentScale = _transformController.value.getMaxScaleOnAxis();
    });
  }

  Future<void> _analyzeImage() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请先选择ECG图像')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 确保原始选框坐标是最新的，并考虑图像实际大小
      int left = originalSelectionLeft.round();
      int top = originalSelectionTop.round();
      int width = originalSelectionWidth.round();
      int height = originalSelectionHeight.round();

      // 确保裁剪参数不超出图像边界
      if (_imageSize != null) {
        left = left.clamp(0, _imageSize!.width.toInt() - 1);
        top = top.clamp(0, _imageSize!.height.toInt() - 1);
        width = width.clamp(1, _imageSize!.width.toInt() - left);
        height = height.clamp(1, _imageSize!.height.toInt() - top);
      }

      // 构建裁剪参数
      final cropParams = {
        "left": left,
        "top": top,
        "width": width,
        "height": height,
      };

      // 显示参数提示
      print('使用裁剪参数: $cropParams');

      final result = await _apiService.predictEcg(
        _selectedImageBytes!,
        cropParams: cropParams,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(diagResult: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('分析失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ECG房颤分析'), centerTitle: true),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child:
                    _selectedImageBytes != null
                        ? GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          onTapDown: _onTapDown, // 添加点击处理
                          child: ClipRect(
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  transformationController:
                                      _transformController,
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.memory(
                                    _selectedImageBytes!,
                                    key: _imageKey,
                                    fit: BoxFit.contain,
                                  ),
                                  //_selectedImage!,
                                ),
                                // 选择框
                                if (!_isLoading)
                                  Positioned(
                                    left:
                                        selectionLeft * _currentScale +
                                        _transformController.value
                                            .getTranslation()
                                            .x,
                                    top:
                                        selectionTop * _currentScale +
                                        _transformController.value
                                            .getTranslation()
                                            .y,
                                    child: Container(
                                      width: selectionWidth * _currentScale,
                                      height: selectionHeight * _currentScale,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('请选择ECG图像进行分析'),
                              ],
                            ),
                          ),
                        ),
              ),
            ),
            if (_selectedImageBytes != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '点击图像可移动选框，或拖动红色选框选择要分析的ECG片段',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              // 显示当前选择区域的坐标
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  children: [
                    Text(
                      '显示选区坐标: X=${selectionLeft.round()}, Y=${selectionTop.round()}, 宽=${selectionWidth.round()}, 高=${selectionHeight.round()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      '原始选区坐标: X=${originalSelectionLeft.round()}, Y=${originalSelectionTop.round()}, 宽=${originalSelectionWidth.round()}, 高=${originalSelectionHeight.round()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('选择图像'),
                  onPressed: _isLoading ? null : _pickImage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.analytics),
                  label: Text('分析'),
                  onPressed:
                      (_isLoading || _selectedImageBytes == null)
                          ? null
                          : _analyzeImage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.short_text_rounded),
                  label: Text('txt文件转心电图'),
                  onPressed: _pickText,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在分析中，请稍候...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
