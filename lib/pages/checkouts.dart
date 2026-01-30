import 'package:flutter/material.dart';
import 'package:checout_trainer/helpers/darts_checkouts.dart';
import 'package:checout_trainer/repositories/custom_checkout_repository.dart';

class CheckoutsPage extends StatefulWidget {
  @override
  _CheckoutsPageState createState() => _CheckoutsPageState();
}

class _CheckoutsPageState extends State<CheckoutsPage> {
  final CustomCheckoutRepository _repository = CustomCheckoutRepository();
  final TextEditingController _searchController = TextEditingController();
  Map<int, List<String>> _filteredCheckouts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckouts();
  }

  // Load custom checkouts from repository asynchronously
  Future<void> _loadCheckouts() async {
    await _repository.initCheckouts(); // Ensure checkouts are loaded
    setState(() {
      _filteredCheckouts = {
        ...DartCheckouts.checkouts, // Default checkouts
        ..._repository.checkouts,   // Custom checkouts from the repository
      };
      _isLoading = false;
    });
  }

  void _filterCheckouts(String query) {
    final searchKey = int.tryParse(query);
    setState(() {
      if (searchKey != null) {
        _filteredCheckouts = {
          ...DartCheckouts.checkouts,
          ..._repository.checkouts,
        }..removeWhere((key, value) => !key.toString().startsWith(query));
      } else {
        _filteredCheckouts = {
          ...DartCheckouts.checkouts,
          ..._repository.checkouts,
        };
      }
    });
  }

  Future<void> _replaceCheckout(int score, List<String> newCheckout) async {
    if (!_isDefaultCheckout(score, newCheckout)) {
      await _repository.addCheckout(score, newCheckout);
      setState(() {
        _filteredCheckouts[score] = newCheckout;
      });
    } else {
      await _removeCustomCheckout(score);
    }
  }

  bool _isDefaultCheckout(int score, List<String> newCheckout) {
    return DartCheckouts.checkouts[score]?.join(', ') == newCheckout.join(', ');
  }

  Future<void> _removeCustomCheckout(int score) async {
    await _repository.removeCheckout(score);
    _filterCheckouts(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
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
              // Search Bar & Back Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface, // Secondary color
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by score',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        keyboardType: TextInputType.number, // Numeric keyboard only
                        onChanged: (query) => _filterCheckouts(query),
                      ),
                    ),
                  ],
                ),
              ),
              // Display a loading indicator while data is being fetched
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                // List of Checkouts
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredCheckouts.length,
                    itemBuilder: (context, index) {
                      final key = _filteredCheckouts.keys.elementAt(index);
                      final value = _filteredCheckouts[key];
                      final isCustom = _repository.checkouts.containsKey(key);
        
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$key', // Score on the left
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Checkout (throws) on the right
                              Expanded(
                                child: Text(
                                  value?.join(', ') ?? 'No custom checkout',
                                  style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          trailing: isCustom
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeCustomCheckout(key),
                                )
                              : null,
                          onTap: () async {
                            final newCheckout = await showDialog<List<String>>(
                              context: context,
                              builder: (context) => EditCheckoutDialog(
                                score: key,
                                currentCheckout: value ?? [],
                              ),
                            );
        
                            if (newCheckout != null) {
                              await _replaceCheckout(key, newCheckout);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditCheckoutDialog extends StatefulWidget {
  final int score;
  final List<String> currentCheckout;

  const EditCheckoutDialog({
    Key? key,
    required this.score,
    required this.currentCheckout,
  }) : super(key: key);

  @override
  _EditCheckoutDialogState createState() => _EditCheckoutDialogState();
}

class _EditCheckoutDialogState extends State<EditCheckoutDialog> {
  late List<String> _checkout;
  final _formKey = GlobalKey<FormState>();
  bool showSumNotCorrectError = false;

  @override
  void initState() {
    super.initState();
    _checkout = List.from(widget.currentCheckout);
  }

  bool _isValidInput(String input) {
    // Regex for valid scores with optional D or T prefix
    final scorePattern = RegExp(r'^[DT]?(1[0-9]|20|[1-9]|25|Bull)$');
    return scorePattern.hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Checkout for ${widget.score}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Use D or T prefix for double or triple.',
              style: TextStyle(color: Colors.grey),
            ),
            // Display each throw input
            for (int i = 0; i < _checkout.length; i++)
              TextFormField(
                initialValue: _checkout[i],
                decoration: InputDecoration(
                  labelText: 'Throw ${i + 1}',
                  errorText: _isValidInput(_checkout[i]) ? null : 'Invalid score',
                ),
                onChanged: (value) {
                  setState(() {
                    _checkout[i] = value;
                  });
                },
                validator: (value) {
                  // Validate on Save only, not on every change
                  if (value == null || value.isEmpty || !_isValidInput(value)) {
                    return 'Invalid score';
                  }
                  return null;
                },
              ),
              // if (_checkout.length < 3)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 8.0),
              //     child: ElevatedButton(
              //       onPressed: () {
              //         setState(() {
              //           _checkout.add('');
              //         });
              //       },
              //       child: Text('Add Throw'),
              //     ),
              //   ),
            // Display error message if total sum is incorrect
            if (showSumNotCorrectError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Total sum is not correct!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),  
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            showSumNotCorrectError = false;
            // Validate total sum
            if (_checkout.isNotEmpty) {
              final sum = _checkout.fold(0, (int sum, String item) {
                if (item == 'Bull') return sum + 50;
                if (item == '25') return sum + 25;

                final int value = int.parse(item.replaceAll(RegExp(r'[DT]'), ''));
                final int multiplier = item.startsWith('D') ? 2 : item.startsWith('T') ? 3 : 1;
                return sum + value * multiplier;
              });

              if (sum != widget.score) {
                setState(() {
                  showSumNotCorrectError = true;
                });
                return;
              }
            }

            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _checkout);
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
