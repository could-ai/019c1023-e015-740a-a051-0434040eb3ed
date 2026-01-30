import 'package:flutter/material.dart';

class BlockShape {
  final List<List<int>> matrix; // 1 for occupied, 0 for empty
  final Color color;
  final int id; // Unique ID to identify specific instances

  const BlockShape({
    required this.matrix,
    required this.color,
    required this.id,
  });

  int get width => matrix[0].length;
  int get height => matrix.length;
}

class ShapeDefinitions {
  static const List<List<List<int>>> _patterns = [
    // 1x1
    [[1]],
    // 2x1
    [[1, 1]],
    [[1], [1]],
    // 3x1
    [[1, 1, 1]],
    [[1], [1], [1]],
    // 4x1
    [[1, 1, 1, 1]],
    [[1], [1], [1], [1]],
    // 2x2
    [[1, 1], [1, 1]],
    // L shapes (2x2 bounding box for small L)
    [[1, 0], [1, 1]],
    [[0, 1], [1, 1]],
    [[1, 1], [1, 0]],
    [[1, 1], [0, 1]],
    // 3x3 L shapes
    [[1, 0, 0], [1, 0, 0], [1, 1, 1]],
    [[0, 0, 1], [0, 0, 1], [1, 1, 1]],
    [[1, 1, 1], [1, 0, 0], [1, 0, 0]],
    [[1, 1, 1], [0, 0, 1], [0, 0, 1]],
    // T shapes
    [[1, 1, 1], [0, 1, 0]],
    [[0, 1, 0], [1, 1, 1]],
    [[1, 0], [1, 1], [1, 0]],
    [[0, 1], [1, 1], [0, 1]],
  ];

  static const List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  static BlockShape getRandomShape(int id) {
    final pattern = _patterns[DateTime.now().microsecondsSinceEpoch % _patterns.length];
    final color = _colors[DateTime.now().microsecondsSinceEpoch % _colors.length];
    return BlockShape(matrix: pattern, color: color, id: id);
  }
}
