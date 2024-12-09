import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFFDFDEC), // Beige/blanc cassé
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<int> grid = List.filled(16, 0);
  Set<int> combinedIndices = {};
  int moves = 0;
  int score = 0;
  int bestScore = 0;
  int goal = 2048;
  bool randomizeGrid = false; // Nouvelle option pour activer/désactiver la grille aléatoire.
  final List<int> goals = [256, 512, 1024, 2048];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      grid = List.filled(16, 0);
      if (randomizeGrid) {
        _fillRandomGrid();
      } else {
        _addRandomTile();
        _addRandomTile();
      }
      moves = 0;
      score = 0;
      combinedIndices.clear();
    });
  }

  void _fillRandomGrid() {
    final random = Random();
    int maxValue = goal ~/ 2; // Limiter les valeurs à la moitié de l'objectif.

    for (int i = 0; i < grid.length; i++) {
      if (random.nextBool()) {
        grid[i] = _randomPowerOfTwo(maxValue);
      } else {
        grid[i] = 0;
      }
    }
  }

  int _randomPowerOfTwo(int max) {
    // Générer une puissance de 2 aléatoire inférieure ou égale à `max`.
    List<int> powers = [];
    int value = 2;
    while (value <= max) {
      powers.add(value);
      value *= 2;
    }
    return powers.isNotEmpty ? powers[Random().nextInt(powers.length)] : 2;
  }

  void _addRandomTile() {
    final emptyIndices = <int>[];
    for (int i = 0; i < grid.length; i++) {
      if (grid[i] == 0) emptyIndices.add(i);
    }
    if (emptyIndices.isNotEmpty) {
      final randomIndex = emptyIndices[Random().nextInt(emptyIndices.length)];
      grid[randomIndex] = Random().nextBool() ? 2 : 4;
    }
  }

  void _move(String direction) {
    setState(() {
      List<int> newGrid = List.filled(16, 0);
      int moveScore = 0;
      combinedIndices.clear();

      for (int i = 0; i < 4; i++) {
        List<int> line;
        if (direction == 'up' || direction == 'down') {
          line = [
            grid[i],
            grid[i + 4],
            grid[i + 8],
            grid[i + 12],
          ];
        } else {
          line = grid.sublist(i * 4, (i + 1) * 4);
        }

        if (direction == 'down' || direction == 'right') {
          line = line.reversed.toList();
        }

        List<int> mergedLine = _mergeLine(line, i, direction);
        moveScore += _calculateScore(line, mergedLine);

        if (direction == 'down' || direction == 'right') {
          mergedLine = mergedLine.reversed.toList();
        }

        for (int j = 0; j < 4; j++) {
          if (direction == 'up' || direction == 'down') {
            newGrid[i + j * 4] = mergedLine[j];
          } else {
            newGrid[i * 4 + j] = mergedLine[j];
          }
        }
      }

      if (grid != newGrid) {
        grid = newGrid;
        moves++;
        score += moveScore;
        _addRandomTile();
        _checkWinCondition();
        _checkGameOver();
      }
    });
  }

  int _calculateScore(List<int> oldLine, List<int> newLine) {
    int score = 0;
    for (int i = 0; i < 4; i++) {
      if (newLine[i] > oldLine[i]) {
        score += newLine[i];
      }
    }
    return score;
  }

  void _checkWinCondition() {
    if (grid.contains(goal)) {
      bestScore = max(bestScore, score);
      _showWinDialog();
    }
  }

  void _checkGameOver() {
    if (!_canMove()) {
      bestScore = max(bestScore, score);
      _showGameOverDialog();
    }
  }

  bool _canMove() {
    for (int i = 0; i < 16; i++) {
      if (grid[i] == 0) return true;

      if (i % 4 != 3 && grid[i] == grid[i + 1]) return true; // Check right
      if (i < 12 && grid[i] == grid[i + 4]) return true;     // Check down
    }
    return false;
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bravo !"),
        content: Text("Vous avez atteint $goal !"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text("Nouvelle partie"),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: Text("Aucun mouvement possible.\nMeilleur score : $bestScore"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text("Nouvelle partie"),
          ),
        ],
      ),
    );
  }

  List<int> _mergeLine(List<int> line, int lineIndex, String direction) {
    List<int> merged = line.where((tile) => tile != 0).toList();

    for (int i = 0; i < merged.length - 1; i++) {
      if (merged[i] == merged[i + 1]) {
        merged[i] *= 2;
        merged[i + 1] = 0;

        int globalIndex = 0;
        if (direction == 'up' || direction == 'down') {
          globalIndex = lineIndex + i * 4;
        } else {
          globalIndex = lineIndex * 4 + i;
        }
        combinedIndices.add(globalIndex);
      }
    }

    merged = merged.where((tile) => tile != 0).toList();
    while (merged.length < 4) {
      merged.add(0);
    }

    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coups: $moves', style: const TextStyle(fontSize: 20)),
                Text('Score: $score', style: const TextStyle(fontSize: 20)),
                DropdownButton<int>(
                  value: goal,
                  items: goals
                      .map(
                        (g) => DropdownMenuItem(
                      value: g,
                      child: Text('$g'),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      goal = value!;
                      _startNewGame();
                    });
                  },
                ),
              ],
            ),
          ),
          CheckboxListTile(
            title: const Text('Grille aléatoire'),
            value: randomizeGrid,
            onChanged: (bool? value) {
              setState(() {
                randomizeGrid = value!;
                _startNewGame();
              });
            },
          ),
          Expanded(
            child: GameGrid(
              grid: grid,
              combinedIndices: combinedIndices,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewGame,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class GameGrid extends StatelessWidget {
  final List<int> grid;
  final Set<int> combinedIndices;

  const GameGrid({
    Key? key,
    required this.grid,
    required this.combinedIndices,
  }) : super(key: key);

  Color _getTileColor(int value) {
    if (value == 0) return Colors.grey[300]!;
    final Map<int, Color> colorMap = {
      2: Colors.lightBlue[100]!,
      4: Colors.lightBlue[200]!,
      8: Colors.lightBlue[300]!,
      16: Colors.lightBlue[400]!,
      32: Colors.lightBlue[500]!,
      64: Colors.lightBlue[600]!,
      128: Colors.blue[700]!,
      256: Colors.blue[800]!,
      512: Colors.blue[900]!,
      1024: Colors.indigo[700]!,
      2048: Colors.indigo[900]!,
    };
    return colorMap[value] ?? Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return combinedIndices.contains(index)
                    ? ScaleTransition(scale: animation, child: child)
                    : child;
              },
              child: Container(
                key: ValueKey(grid[index]),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _getTileColor(grid[index]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  grid[index] == 0 ? '' : '${grid[index]}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
