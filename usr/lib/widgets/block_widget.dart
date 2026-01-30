import 'package:flutter/material.dart';
import '../logic/shapes.dart';

class BlockWidget extends StatelessWidget {
  final BlockShape shape;
  final double cellSize;
  final bool isGhost;

  const BlockWidget({
    super.key,
    required this.shape,
    this.cellSize = 20.0,
    this.isGhost = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: shape.width * cellSize,
      height: shape.height * cellSize,
      child: Column(
        children: List.generate(shape.height, (r) {
          return Row(
            children: List.generate(shape.width, (c) {
              final isOccupied = shape.matrix[r][c] == 1;
              return Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isOccupied 
                      ? (isGhost ? shape.color.withOpacity(0.5) : shape.color) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
