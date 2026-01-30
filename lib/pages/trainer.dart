import 'package:checout_trainer/helpers/darts_checkouts.dart';
import 'package:checout_trainer/repositories/custom_checkout_repository.dart';
import 'package:flutter/material.dart';
import 'package:linear_timer/linear_timer.dart';

void main() {
  runApp(const MaterialApp(home: TrainerPage()));
}

class TrainerPage extends StatefulWidget {
  const TrainerPage({Key? key}) : super(key: key);

  @override
  State<TrainerPage> createState() => _TrainerPageState();
}

class _TrainerPageState extends State<TrainerPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  final CustomCheckoutRepository _repository = CustomCheckoutRepository();

  final List<int> numbers = List.generate(20, (index) => index + 1);
  late LinearTimerController timerController = LinearTimerController(this);
  Duration timerDuration = const Duration(seconds: 30);

  int score = 0;
  List<String> solution = [];
  List<String> inputs = [];
  String modifier = "Single";

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timerController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCheckouts();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      timerController.start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in the background or user is leaving the app
      timerController.stop();
    } else if (state == AppLifecycleState.resumed) {
      // App is in the foreground again
      timerController.start();
    } else if (state == AppLifecycleState.inactive) {
      // App is in an inactive state (e.g., during a phone call)
      timerController.stop();
    } else if (state == AppLifecycleState.detached) {
      // App is detached (not common for typical apps)
      timerController.stop();
    }
  }

  Future<void> _loadCheckouts() async {
    await _repository.initCheckouts(); // Ensure checkouts are loaded
    generateRandomCheckout();
  }

  int _calculateInputSum() {
    return inputs.fold(0, (int sum, String item) {
      if (item == 'Bull') return sum + 50;
      if (item == '25') return sum + 25;
      final int value = int.parse(item.replaceAll(RegExp(r'[DT]'), ''));
      final int multiplier = item.startsWith('D') ? 2 : item.startsWith('T') ? 3 : 1;
      return sum + value * multiplier;
    });
  }

  bool _canFinishWithDouble(int remaining) {
    return remaining == 50 || (remaining >= 2 && remaining <= 40 && remaining.isEven);
  }

  void generateRandomCheckout() async {
    final randomCheckout = DartCheckouts.getRandomCheckout(_repository.checkouts);

    setState(() {
      score = randomCheckout.key;
      solution = randomCheckout.value;
      inputs.clear();
      modifier = _canFinishWithDouble(randomCheckout.key) ? 'Double' : 'Single';
    });
  }

  void addInput(String value) {
    if (inputs.length < solution.length) {
      setState(() {
        inputs.add(value);

        final remaining = score - _calculateInputSum();
        if (_canFinishWithDouble(remaining)) {
          modifier = 'Double';
        }
      });
    }
  }

  void undoInput() {
    if (inputs.isNotEmpty) {
      setState(() {
        inputs.removeLast();
      });
    }
  }

  void submit() {
    timerController.stop();
    bool arraysMatch(List<String> a, List<String> b) => a.join(', ') == b.join(', ');

    int calculateScore(List<String> items) {
      return items.fold(0, (int sum, String item) {
        if (item == 'Bull') return sum + 50;
        if (item == '25') return sum + 25;

        final int value = int.parse(item.replaceAll(RegExp(r'[DT]'), ''));
        final int multiplier = item.startsWith('D') ? 2 : item.startsWith('T') ? 3 : 1;
        return sum + value * multiplier;
      });
    }

    void showResultDialog(String title, Icon icon, Widget content, VoidCallback onNext) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              icon,
              const SizedBox(width: 8.0),
              Text(title),
            ],
          ),
          content: content,
          actions: [
            TextButton(
              onPressed: onNext,
              child: const Text("Next"),
            ),
          ],
        ),
      );
    }

    if (arraysMatch(inputs, solution)) {
      showResultDialog(
        "Correct!",
        const Icon(Icons.check, color: Colors.green),
        const Text("You matched the checkout!"),
        () {
          modifier = 'Single';
          Navigator.of(context).pop();
          generateRandomCheckout();
          timerController.reset();
          timerController.start();
        },
      );
      return;
    }

    final int total = calculateScore(inputs);
    final int solutionTotal = calculateScore(solution);

    if (total == solutionTotal) {
      showResultDialog(
        "Correct!",
        const Icon(Icons.check, color: Colors.green),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("You matched the checkout!"),
            const SizedBox(height: 8.0),
            const Text("Recommended sequence:"),
            Text(
              solution.join(' | '),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        () {
          modifier = 'Single';
          Navigator.of(context).pop();
          generateRandomCheckout();
          timerController.reset();
          timerController.start();
        },
      );
      return;
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.close, color: Colors.red),
            const SizedBox(width: 8.0),
            const Text("Incorrect!"),
          ],
        ),
        content: const Text("You did not match the checkout."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              timerController.start();
            },
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/dartbord.jpg'), // Path to your image
            fit: BoxFit.cover, // Makes the image cover the entire background
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LinearTimer(
                  duration: timerDuration,
                  controller: timerController,
                  forward: false,
                  minHeight: 16.0,
                  onTimerEnd: () {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.red),
                            const SizedBox(width: 8.0),
                            const Text("Time's Up!"),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("You ran out of time!"),
                            const SizedBox(height: 8.0),
                            const Text("The correct sequence was:"),
                            Text(
                              solution.join(' | '),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              generateRandomCheckout();
                              timerController.reset();
                              timerController.start();
                            },
                            child: const Text("Continue"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Top: Score Display
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Padding around text
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface, // Secondary color
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                          ),
                          child: Text(
                            "Checkout: $score",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Padding around text
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface, // Secondary color
                              borderRadius: BorderRadius.circular(12), // Rounded corners
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back, color: colorScheme.primary),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Middle: User Inputs
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 0.0,
                    children: inputs
                        .map((input) => Chip(
                              label: Text(input, style: TextStyle(color: colorScheme.primary)),
                            ))
                        .toList(),
                  ),
                ),
              ),
              // Bottom: Custom Keyboard
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Modifier Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['Single', 'Double', 'Treble'].map((mod) {
                          final remaining = score - _calculateInputSum();
                          final bool isDisabled = (mod != 'Double' && _canFinishWithDouble(remaining));
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: modifier == mod && !isDisabled ? Colors.green : null,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              foregroundColor: isDisabled ? Colors.grey : modifier == mod ? Colors.white : null,
                            ),
                            onPressed: isDisabled
                                ? null
                                : () {
                                    setState(() {
                                      modifier = mod;
                                    });
                                  },
                            child: Text(mod),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8.0),
                      // Number Buttons in Grid
                      GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: numbers.length,
                        itemBuilder: (context, index) {
                          final number = numbers[index];
                          final int value = modifier == 'Single'
                              ? number
                              : modifier == 'Double'
                                  ? number * 2
                                  : number * 3;
                          final String multiplierText =
                              modifier == 'Single' ? '' : '($value)';
        
                          final bool isDisabled = inputs.length == solution.length;
        
                          return ElevatedButton(
                            onPressed: isDisabled
                                ? null
                                : () {
                                    final prefix = modifier == 'Single'
                                        ? ''
                                        : modifier == 'Double'
                                            ? 'D'
                                            : 'T';
                                    addInput('$prefix$number');
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$number',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (multiplierText.isNotEmpty)
                                  Text(
                                    multiplierText,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8.0),
                      // Bull, Outer, Undo Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: inputs.length < solution.length ? () => addInput("Bull") : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Bull (50)"),
                          ),
                          ElevatedButton(
                            onPressed: !_canFinishWithDouble(score - _calculateInputSum()) && inputs.length < solution.length
                                ? () => addInput("25")
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Outer (25)"),
                          ),
                          ElevatedButton.icon(
                            onPressed: undoInput,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            icon: const Icon(Icons.undo),
                            label: const Text("Undo"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      // Submit Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: const Text(
                              "Submit",
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
