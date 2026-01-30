import 'package:flutter/material.dart';
import 'shapes.dart';

class GameLogic extends ChangeNotifier {
  static const int gridSize = 8;
  
  // The grid stores Colors? (null means empty)
  List<List<Color?>> grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
  
  // Available shapes in the dock
  List<BlockShape?> availableShapes = [null, null, null];
  
  int score = 0;
  bool isGameOver = false;
  int currentCombo = 0;

  GameLogic() {
    _refillShapes();
  }

  void restart() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    score = 0;
    isGameOver = false;
    currentCombo = 0;
    availableShapes = [null, null, null];
    _refillShapes();
    notifyListeners();
  }

  void _refillShapes() {
    // Only refill if all shapes are used
    if (availableShapes.every((s) => s == null)) {
      for (int i = 0; i < 3; i++) {
        availableShapes[i] = ShapeDefinitions.getRandomShape(DateTime.now().microsecondsSinceEpoch + i);
      }
      _checkGameOver();
      notifyListeners();
    }
  }

  bool canPlaceShape(BlockShape shape, int row, int col) {
    // Check bounds and overlap
    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (shape.matrix[r][c] == 1) {
          int gridRow = row + r;
          int gridCol = col + c;

          if (gridRow < 0 || gridRow >= gridSize || gridCol < 0 || gridCol >= gridSize) {
            return false;
          }

          if (grid[gridRow][gridCol] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void placeShape(BlockShape shape, int row, int col, int shapeIndex) {
    if (!canPlaceShape(shape, row, col)) return;

    // Place the shape
    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (shape.matrix[r][c] == 1) {
          grid[row + r][col + c] = shape.color;
        }
      }
    }

    // Remove from available shapes
    availableShapes[shapeIndex] = null;

    // Add placement score (number of blocks placed)
    int blocksCount = 0;
    for(var row in shape.matrix) {
      for(var cell in row) {
        if(cell == 1) blocksCount++;
      }
    }
    score += blocksCount;

    // Check for lines to clear
    _checkLines();

    // Refill if needed
    if (availableShapes.every((s) => s == null)) {
      _refillShapes();
    } else {
      // Check game over after placement (if we didn't just refill)
      _checkGameOver();
    }
    
    notifyListeners();
  }

  void _checkLines() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];

    // Check rows
    for (int r = 0; r < gridSize; r++) {
      if (grid[r].every((c) => c != null)) {
        rowsToClear.add(r);
      }
    }

    // Check cols
    for (int c = 0; c < gridSize; c++) {
      bool full = true;
      for (int r = 0; r < gridSize; r++) {
        if (grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) {
        colsToClear.add(c);
      }
    }

    if (rowsToClear.isEmpty && colsToClear.isEmpty) {
      currentCombo = 0;
      return;
    }

    currentCombo++;
    
    // Calculate score
    int linesCleared = rowsToClear.length + colsToClear.length;
    // Base score for lines + combo bonus
    score += (linesCleared * 10) * currentCombo;

    // Clear the lines
    // We need to clear them simultaneously, so we don't mess up the grid while checking
    // Actually, we can just set them to null. A cell might be cleared by both row and col.
    
    for (int r in rowsToClear) {
      for (int c = 0; c < gridSize; c++) {
        grid[r][c] = null;
      }
    }
    
    for (int c in colsToClear) {
      for (int r = 0; r < gridSize; r++) {
        grid[r][c] = null;
      }
    }
  }

  void _checkGameOver() {
    // If no available shape can fit anywhere on the grid, it's game over.
    // We only check available shapes.
    
    bool canMove = false;
    
    for (var shape in availableShapes) {
      if (shape == null) continue;
      
      // Try to find ANY valid position for this shape
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          if (canPlaceShape(shape, r, c)) {
            canMove = true;
            break;
          }
        }
        if (canMove) break;
      }
      if (canMove) break;
    }
    
    // If we have shapes but none can move, game over
    // Note: If availableShapes is empty, we would have refilled. 
    // If after refill we still can't move (unlikely with empty board, but possible with full board), then game over.
    // Actually, refill happens immediately when empty. So we always have shapes if game is running.
    
    // Edge case: if we just refilled, we check.
    
    if (!canMove && availableShapes.any((s) => s != null)) {
      isGameOver = true;
    }
  }
}
