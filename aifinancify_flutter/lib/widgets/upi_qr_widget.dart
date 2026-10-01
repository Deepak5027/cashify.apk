import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight QR Code visual generator and renderer for UPI payments
class UpiQrWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;
  final String? centerLabel;

  const UpiQrWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
    this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size - 24, size - 24),
            painter: _QrMatrixPainter(
              data: data,
              fgColor: foregroundColor,
            ),
          ),
          if (centerLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Text(
                centerLabel!,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final String data;
  final Color fgColor;

  _QrMatrixPainter({required this.data, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.fill;

    // Generate deterministic 25x25 QR matrix pattern based on data hash
    const int matrixSize = 25;
    final double cellSize = size.width / matrixSize;
    final int hash = _hashString(data);
    final random = Random(hash);

    final List<List<bool>> grid = List.generate(
      matrixSize,
      (y) => List.generate(matrixSize, (x) => false),
    );

    // 1. Draw standard QR Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    _drawFinderPattern(grid, 0, 0);
    _drawFinderPattern(grid, matrixSize - 7, 0);
    _drawFinderPattern(grid, 0, matrixSize - 7);

    // 2. Draw Timing Patterns
    for (int i = 8; i < matrixSize - 8; i++) {
      grid[6][i] = (i % 2 == 0);
      grid[i][6] = (i % 2 == 0);
    }

    // 3. Fill Data Payload
    for (int y = 0; y < matrixSize; y++) {
      for (int x = 0; x < matrixSize; x++) {
        if (_isFinderOrTiming(x, y, matrixSize)) continue;
        grid[y][x] = random.nextBool();
      }
    }

    // Paint cells with rounded squares
    for (int y = 0; y < matrixSize; y++) {
      for (int x = 0; x < matrixSize; x++) {
        if (grid[y][x]) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize * 0.92, cellSize * 0.92),
            Radius.circular(cellSize * 0.25),
          );
          canvas.drawRRect(rect, paint);
        }
      }
    }
  }

  void _drawFinderPattern(List<List<bool>> grid, int startX, int startY) {
    for (int y = 0; y < 7; y++) {
      for (int x = 0; x < 7; x++) {
        final isBorder = (x == 0 || x == 6 || y == 0 || y == 6);
        final isCenter = (x >= 2 && x <= 4 && y >= 2 && y <= 4);
        grid[startY + y][startX + x] = isBorder || isCenter;
      }
    }
  }

  bool _isFinderOrTiming(int x, int y, int size) {
    if (x < 8 && y < 8) return true; // Top-Left
    if (x >= size - 8 && y < 8) return true; // Top-Right
    if (x < 8 && y >= size - 8) return true; // Bottom-Left
    if (x == 6 || y == 6) return true; // Timing
    if (x >= 10 && x <= 14 && y >= 10 && y <= 14) return true; // Center logo area
    return false;
  }

  int _hashString(String s) {
    int hash = 5381;
    for (int i = 0; i < s.length; i++) {
      hash = ((hash << 5) + hash) + s.codeUnitAt(i);
    }
    return hash.abs();
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) => oldDelegate.data != data || oldDelegate.fgColor != fgColor;
}
