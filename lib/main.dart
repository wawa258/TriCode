import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SnakeGame(),
    ),
  );
}

enum Direction { up, down, left, right }

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int cols = 20;
  static const int rows = 20;
  static const Duration tick = Duration(milliseconds: 150);

  final Random _random = Random();
  final FocusNode _focusNode = FocusNode();

  List<Point<int>> snake = [];
  Point<int> food = const Point(5, 5);
  Direction direction = Direction.right;
  Timer? _timer;

  int score = 0;
  bool started = false;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------- Game logic ----------
  void _resetGame() {
    snake = [const Point(10, 10), const Point(9, 10), const Point(8, 10)];
    direction = Direction.right;
    score = 0;
    gameOver = false;
    _placeFood();
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _resetGame();
      started = true;
    });
    _timer = Timer.periodic(tick, (_) => _move());
  }

  void _placeFood() {
    Point<int> p;
    do {
      p = Point(_random.nextInt(cols), _random.nextInt(rows));
    } while (snake.contains(p));
    food = p;
  }

  void _move() {
    final head = snake.first;
    Point<int> newHead;

    switch (direction) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    final hitWall = newHead.x < 0 ||
        newHead.x >= cols ||
        newHead.y < 0 ||
        newHead.y >= rows;
    final ateFood = newHead == food;

    // The tail moves away, so it is safe to step on it when not eating.
    final bodyToCheck =
        ateFood ? snake : snake.sublist(0, snake.length - 1);
    final hitSelf = bodyToCheck.contains(newHead);

    if (hitWall || hitSelf) {
      _timer?.cancel();
      setState(() {
        gameOver = true;
      });
      return;
    }

    setState(() {
      snake.insert(0, newHead);
      if (ateFood) {
        score += 10;
        _placeFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void _changeDirection(Direction newDir) {
    if (!started || gameOver) return;

    // Do not allow turning back on itself.
    final opposite = (direction == Direction.up && newDir == Direction.down) ||
        (direction == Direction.down && newDir == Direction.up) ||
        (direction == Direction.left && newDir == Direction.right) ||
        (direction == Direction.right && newDir == Direction.left);

    if (!opposite) {
      direction = newDir;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _changeDirection(Direction.up);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      _changeDirection(Direction.down);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      _changeDirection(Direction.left);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _changeDirection(Direction.right);
    } else if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter) {
      if (!started || gameOver) _startGame();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _onSwipe(DragUpdateDetails d) {
    if (d.delta.dx.abs() > d.delta.dy.abs()) {
      _changeDirection(d.delta.dx > 0 ? Direction.right : Direction.left);
    } else {
      _changeDirection(d.delta.dy > 0 ? Direction.down : Direction.up);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SNAKE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: $score',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Board
                    AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onPanUpdate: _onSwipe,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: BoardPainter(
                                snake: snake,
                                food: food,
                                cols: cols,
                                rows: rows,
                              ),
                            ),
                            if (!started || gameOver)
                              Container(
                                color: Colors.black54,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      gameOver ? 'GAME OVER' : 'READY?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (gameOver)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'Final score: $score',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Controls (ExcludeFocus keeps the keyboard working
                    // after you click a button)
                    ExcludeFocus(
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: (!started || gameOver) ? _startGame : null,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(gameOver ? 'Play Again' : 'Start'),
                          ),
                          const SizedBox(height: 12),
                          _arrowButton(Icons.keyboard_arrow_up, Direction.up),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _arrowButton(
                                  Icons.keyboard_arrow_left, Direction.left),
                              const SizedBox(width: 48),
                              _arrowButton(
                                  Icons.keyboard_arrow_right, Direction.right),
                            ],
                          ),
                          _arrowButton(
                              Icons.keyboard_arrow_down, Direction.down),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Arrow keys / WASD, swipe, or tap the arrows.\nSpace or Enter to start.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _arrowButton(IconData icon, Direction dir) {
    return IconButton(
      onPressed: () => _changeDirection(dir),
      icon: Icon(icon, size: 36),
      color: Colors.white,
      style: IconButton.styleFrom(backgroundColor: Colors.white12),
    );
  }
}

// Draws the board, snake and food.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.snake,
    required this.food,
    required this.cols,
    required this.rows,
  });

  final List<Point<int>> snake;
  final Point<int> food;
  final int cols;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF162447),
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(
          Offset(i * cellW, 0), Offset(i * cellW, size.height), gridPaint);
    }
    for (int j = 0; j <= rows; j++) {
      canvas.drawLine(
          Offset(0, j * cellH), Offset(size.width, j * cellH), gridPaint);
    }

    // Food
    canvas.drawCircle(
      Offset((food.x + 0.5) * cellW, (food.y + 0.5) * cellH),
      cellW * 0.38,
      Paint()..color = Colors.redAccent,
    );

    // Snake
    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x * cellW + 1, p.y * cellH + 1, cellW - 2, cellH - 2),
        Radius.circular(cellW * 0.25),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = i == 0 ? Colors.limeAccent : Colors.greenAccent.shade700,
      );
    }

    // Border
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}