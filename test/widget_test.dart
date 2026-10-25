import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Flutter UI (hearts, dialogue, puzzle). This is where build() belongs.
// ---------------------------------------------------------------------------
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Create the game ONCE so it is not recreated on every rebuild.
  final CodeNectGame game = CodeNectGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: game),

          // Hearts
          Positioned(
            top: 20,
            left: 20,
            child: ValueListenableBuilder<int>(
              valueListenable: game.hearts,
              builder: (context, hearts, _) {
                return Text(
                  '❤️' * hearts,
                  style: const TextStyle(fontSize: 28),
                );
              },
            ),
          ),

          // NPC dialogue
          ValueListenableBuilder<bool>(
            valueListenable: game.dialogueOpen,
            builder: (context, open, _) {
              if (!open) return const SizedBox.shrink();
              return Center(
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'NPC',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'The gate is broken!\nCan you fix the code?',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: game.startPuzzle,
                        child: const Text('Start Puzzle'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Coding puzzle
          ValueListenableBuilder<bool>(
            valueListenable: game.puzzleOpen,
            builder: (context, open, _) {
              if (!open) return const SizedBox.shrink();
              return Center(
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Fix the Code',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text('Arrange the code to create a loop:'),
                      const SizedBox(height: 15),
                      const Text(
                        'for (int i = 0; i < 5; i++)',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: game.solvePuzzle,
                        child: const Text('Submit Correct Answer'),
                      ),
                      TextButton(
                        onPressed: game.wrongAnswer,
                        child: const Text('Submit Wrong Answer'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game logic (Flame). No build() here.
// ---------------------------------------------------------------------------
class CodeNectGame extends FlameGame with HasKeyboardHandlerComponents {
  late Player player;
  late Npc npc;
  late Gate gate;

  // ValueNotifiers let the Flutter UI update when these values change.
  final ValueNotifier<int> hearts = ValueNotifier<int>(3);
  final ValueNotifier<bool> dialogueOpen = ValueNotifier<bool>(false);
  final ValueNotifier<bool> puzzleOpen = ValueNotifier<bool>(false);

  @override
  Future<void> onLoad() async {
    // Background
    add(
      RectangleComponent(
        position: Vector2.zero(),
        size: size,
        paint: Paint()..color = const Color(0xFF7BC96F),
      ),
    );

    player = Player(position: Vector2(350, 250));
    add(player);

    npc = Npc(position: Vector2(550, 250));
    add(npc);

    gate = Gate(position: Vector2(700, 250));
    add(gate);
  }

  void interact() {
    if (player.position.distanceTo(npc.position) < 100 &&
        !dialogueOpen.value &&
        !puzzleOpen.value) {
      dialogueOpen.value = true;
    }
  }

  void startPuzzle() {
    dialogueOpen.value = false;
    puzzleOpen.value = true;
  }

  void solvePuzzle() {
    puzzleOpen.value = false;
    gate.open = true;
  }

  void wrongAnswer() {
    if (hearts.value > 0) {
      hearts.value--;
    }

    if (hearts.value == 0) {
      hearts.value = 3;
    }
  }
}

class Player extends RectangleComponent
    with KeyboardHandler, HasGameReference<CodeNectGame> {
  Player({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(40),
          paint: Paint()..color = Colors.blue,
        );

  final double speed = 200;
  final Vector2 direction = Vector2.zero();

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    direction.setZero();

    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x += 1;
    }

    // Press E once to talk to the NPC.
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      game.interact();
    }

    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Do not move while a dialogue or puzzle is open.
    if (game.dialogueOpen.value || game.puzzleOpen.value) return;

    if (!direction.isZero()) {
      position += direction.normalized() * speed * dt;
    }
  }
}

class Npc extends CircleComponent {
  Npc({required Vector2 position})
      : super(
          position: position,
          radius: 25,
          paint: Paint()..color = Colors.orange,
        );
}

class Gate extends RectangleComponent {
  Gate({required Vector2 position})
      : super(
          position: position,
          size: Vector2(40, 100),
          paint: Paint()..color = Colors.red,
        );

  bool open = false;

  @override
  void update(double dt) {
    super.update(dt);

    if (open) {
      paint.color = Colors.green;
    }
  }
}