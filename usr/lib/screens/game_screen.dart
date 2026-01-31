import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_logic.dart';
import '../logic/shapes.dart';
import '../widgets/block_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GlobalKey _gridKey = GlobalKey();
  // We need to know the cell size to calculate drop position
  double _cellSize = 0;
  // Ghost piece state
  BlockShape? _draggedShape;
  int _ghostRow = -1;
  int _ghostCol = -1;

  @override
  Widget build(BuildContext context) {
    final gameLogic = context.watch<GameLogic>();
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Block Blast Clone', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GameLogic>().restart();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score Board
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  const Text('SCORE', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  Text('${gameLogic.score}', 
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),

            // Game Grid
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate cell size to fit 8x8 grid in available space, with a cap for responsiveness
                      double availableSize = (constraints.maxWidth < constraints.maxHeight 
                          ? constraints.maxWidth 
                          : constraints.maxHeight) - 32;
                      _cellSize = availableSize / GameLogic.gridSize;
                      // Cap cell size to prevent excessive enlargement on large screens (e.g., web)
                      _cellSize = _cellSize.clamp(20.0, 60.0);

                      return Stack(
                        children: [
                          // The Grid Container
                          Container(
                            key: _gridKey,
                            width: _cellSize * GameLogic.gridSize,
                            height: _cellSize * GameLogic.gridSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B2B40),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: GameLogic.gridSize * GameLogic.gridSize,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: GameLogic.gridSize,
                              ),
                              itemBuilder: (context, index) {
                                int r = index ~/ GameLogic.gridSize;
                                int c = index % GameLogic.gridSize;
                                Color? cellColor = gameLogic.grid[r][c];
                                
                                // Check if this cell is part of the ghost
                                bool isGhostCell = false;
                                if (_draggedShape != null && _ghostRow != -1 && _ghostCol != -1) {
                                  int localR = r - _ghostRow;
                                  int localC = c - _ghostCol;
                                  if (localR >= 0 && localR < _draggedShape!.height &&
                                      localC >= 0 && localC < _draggedShape!.width) {
                                    if (_draggedShape!.matrix[localR][localC] == 1) {
                                      isGhostCell = true;
                                    }
                                  }
                                }

                                return Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isGhostCell 
                                        ? _draggedShape!.color.withOpacity(0.5) 
                                        : (cellColor ?? const Color(0xFF363650)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Game Over Overlay
                          if (gameLogic.isGameOver)
                            Container(
                              width: _cellSize * GameLogic.gridSize,
                              height: _cellSize * GameLogic.gridSize,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'GAME OVER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<GameLogic>().restart();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      ),
                                      child: const Text('Try Again', style: TextStyle(fontSize: 18, color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Dock (Available Shapes) - Dynamic height based on screen size
            Container(
              height: isPortrait ? screenSize.height * 0.18 : screenSize.height * 0.12, // Responsive height
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 180), // Safety bounds
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final shape = gameLogic.availableShapes[index];
                  if (shape == null) return const SizedBox(width: 80); // Placeholder

                  return Draggable<BlockShape>(
                    data: shape,
                    feedback: Transform.scale(
                      scale: 1.2,
                      child: BlockWidget(shape: shape, cellSize: _cellSize),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: BlockWidget(shape: shape, cellSize: _cellSize * 0.6), // Smaller in dock
                    ),
                    onDragStarted: () {
                      setState(() {
                        _draggedShape = shape;
                      });
                    },
                    onDragUpdate: (details) {
                      _updateGhostPosition(details.globalPosition, shape);
                    },
                    onDraggableCanceled: (_, __) {
                      setState(() {
                        _draggedShape = null;
                        _ghostRow = -1;
                        _ghostCol = -1;
                      });
                    },
                    onDragEnd: (details) {
                      _handleDrop(details.offset, shape, index);
                      setState(() {
                        _draggedShape = null;
                        _ghostRow = -1;
                        _ghostCol = -1;
                      });
                    },
                    child: BlockWidget(shape: shape, cellSize: _cellSize * 0.6), // Smaller in dock
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateGhostPosition(Offset globalPosition, BlockShape shape) {
    if (_gridKey.currentContext == null) return;

    final RenderBox renderBox = _gridKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    
    // We want the finger to be roughly in the center of the shape being dragged, 
    // but Draggable feedback usually aligns top-left with cursor unless offset.
    // Let's assume the user is dragging by the center of the shape.
    // Adjust logic: The drop target is where the top-left of the shape lands.
    // To make it intuitive, we should offset by half the shape size.
    
    // Actually, standard Draggable behavior: the feedback widget follows the finger.
    // If we want the finger to be "holding" the block, we need to map the finger position to grid cells.
    // Let's assume the finger is at the center of the block.
    
    double shapePixelWidth = shape.width * _cellSize;
    double shapePixelHeight = shape.height * _cellSize;
    
    // Offset to top-left of the shape
    double topLeftX = localPosition.dx - (shapePixelWidth / 2); // Center drag assumption
    double topLeftY = localPosition.dy - (shapePixelHeight / 2) - 50; // -50 because feedback is usually shifted up by finger
    
    // However, Draggable feedback position is tricky. 
    // Let's rely on the fact that we want to snap to the nearest cell.
    
    int col = (topLeftX / _cellSize).round();
    int row = (topLeftY / _cellSize).round();

    // Validate if this position is valid for placement
    final gameLogic = context.read<GameLogic>();
    if (gameLogic.canPlaceShape(shape, row, col)) {
      if (_ghostRow != row || _ghostCol != col) {
        setState(() {
          _ghostRow = row;
          _ghostCol = col;
        });
      }
    } else {
      if (_ghostRow != -1 || _ghostCol != -1) {
        setState(() {
          _ghostRow = -1;
          _ghostCol = -1;
        });
      }
    }
  }

  void _handleDrop(Offset dropOffset, BlockShape shape, int index) {
    // We use the last valid ghost position if available, or calculate again
    // But onDragEnd gives us the global position where the drag ended.
    // It's safer to use the state from _updateGhostPosition if it was valid.
    
    if (_ghostRow != -1 && _ghostCol != -1) {
      context.read<GameLogic>().placeShape(shape, _ghostRow, _ghostCol, index);
    }
  }
}
