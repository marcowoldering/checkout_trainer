import 'package:checout_trainer/helpers/dart_scoring.dart';
import 'package:checout_trainer/helpers/darts_checkouts.dart';
import 'package:checout_trainer/repositories/custom_checkout_repository.dart';
import 'package:checout_trainer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CheckoutsPage extends StatefulWidget {
  @override
  State<CheckoutsPage> createState() => _CheckoutsPageState();
}

class _CheckoutsPageState extends State<CheckoutsPage> {
  final TextEditingController _searchController = TextEditingController();
  Map<int, List<String>> _filteredCheckouts = {};
  bool _isLoading = true;

  CustomCheckoutRepository get _repository => context.read<CustomCheckoutRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckouts();
    });
  }

  Future<void> _loadCheckouts() async {
    await _repository.initCheckouts();
    setState(() {
      _filteredCheckouts = {
        ...DartCheckouts.checkouts,
        ..._repository.checkouts,
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
        decoration: AppDecorations.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and search bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gunmetal),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                        tooltip: 'Go back',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search bar with integrated icon
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.charcoal,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gunmetal),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppColors.pureWhite),
                          decoration: InputDecoration(
                            hintText: 'Search by score...',
                            hintStyle: const TextStyle(color: AppColors.mutedGrey),
                            prefixIcon: const Icon(Icons.search, color: AppColors.mutedGrey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (query) => _filterCheckouts(query),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "CHECKOUTS",
                  style: GoogleFonts.chivo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pureWhite,
                    letterSpacing: 2,
                  ),
                ),
              ),
              // Loading / Empty / List
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.amberGold),
                  ),
                )
              else if (_filteredCheckouts.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.mutedGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No checkouts found',
                          style: GoogleFonts.chivo(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filteredCheckouts.length,
                    itemBuilder: (context, index) {
                      final key = _filteredCheckouts.keys.elementAt(index);
                      final value = _filteredCheckouts[key];
                      final isCustom = _repository.checkouts.containsKey(key);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.richBlack,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCustom ? AppColors.amberGold.withOpacity(0.5) : AppColors.gunmetal,
                            width: isCustom ? 2 : 1,
                          ),
                          boxShadow: isCustom
                              ? [
                                  BoxShadow(
                                    color: AppColors.amberGold.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
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
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              child: Row(
                                children: [
                                  // Score badge
                                  Container(
                                    width: 60,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isCustom
                                          ? AppColors.amberGold.withOpacity(0.2)
                                          : AppColors.charcoal,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$key',
                                        style: GoogleFonts.chivo(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isCustom ? AppColors.amberGold : AppColors.pureWhite,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Checkout sequence
                                  Expanded(
                                    child: Text(
                                      value?.join('  |  ') ?? 'No checkout',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.mutedGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  // Delete button for custom checkouts
                                  if (isCustom)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.crimsonRed),
                                      onPressed: () => _removeCustomCheckout(key),
                                    )
                                  else
                                    const Icon(Icons.chevron_right, color: AppColors.gunmetal),
                                ],
                              ),
                            ),
                          ),
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
  State<EditCheckoutDialog> createState() => _EditCheckoutDialogState();
}

class _EditCheckoutDialogState extends State<EditCheckoutDialog> {
  late List<TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = widget.currentCheckout
        .map((value) => TextEditingController(text: value))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isValidInput(String input) {
    if (input.isEmpty) return false;
    final scorePattern = RegExp(r'^[DT]?(1[0-9]|20|[1-9]|25|Bull)$');
    return scorePattern.hasMatch(input);
  }

  int _getIndividualScore(String input) {
    return DartScoring.calculateScore([input]);
  }

  int _getTotalScore() {
    return DartScoring.calculateScore(
      _controllers.map((c) => c.text).toList(),
    );
  }

  bool _isTotalCorrect() {
    return _getTotalScore() == widget.score &&
        _controllers.every((c) => _isValidInput(c.text));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 450.0 : screenWidth * 0.9;
    final totalScore = _getTotalScore();
    final isCorrect = _isTotalCorrect();

    return Dialog(
      backgroundColor: AppColors.richBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isCorrect ? AppColors.emeraldGreen : AppColors.gunmetal,
          width: isCorrect ? 2 : 1,
        ),
      ),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amberGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.score}',
                      style: GoogleFonts.chivo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.amberGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Checkout',
                          style: GoogleFonts.chivo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use D or T prefix for double or triple',
                          style: TextStyle(
                            color: AppColors.mutedGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Horizontal throw inputs
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < _controllers.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _ThrowInput(
                        controller: _controllers[i],
                        label: 'Throw ${i + 1}',
                        isValid: _isValidInput(_controllers[i].text),
                        score: _isValidInput(_controllers[i].text)
                            ? _getIndividualScore(_controllers[i].text)
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Total preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                      : AppColors.charcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect ? AppColors.emeraldGreen : AppColors.gunmetal,
                    width: isCorrect ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCorrect) ...[
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.emeraldGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      'Total: ',
                      style: GoogleFonts.chivo(
                        fontSize: 18,
                        color: AppColors.mutedGrey,
                      ),
                    ),
                    Text(
                      '$totalScore',
                      style: GoogleFonts.chivo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? AppColors.emeraldGreen : AppColors.pureWhite,
                      ),
                    ),
                    Text(
                      ' / ${widget.score}',
                      style: GoogleFonts.chivo(
                        fontSize: 18,
                        color: AppColors.mutedGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.chivo(
                          fontSize: 16,
                          color: AppColors.mutedGrey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isCorrect ? AppColors.crimsonGradient : null,
                        color: isCorrect ? null : AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isCorrect
                              ? () {
                                  final checkout = _controllers
                                      .map((c) => c.text)
                                      .toList();
                                  Navigator.pop(context, checkout);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              'Save',
                              style: GoogleFonts.chivo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isCorrect
                                    ? AppColors.pureWhite
                                    : AppColors.mutedGrey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThrowInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isValid;
  final int? score;
  final ValueChanged<String> onChanged;

  const _ThrowInput({
    required this.controller,
    required this.label,
    required this.isValid,
    required this.score,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.chivo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedGrey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.center,
          style: GoogleFonts.chivo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.pureWhite,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.charcoal,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid || controller.text.isEmpty
                    ? AppColors.gunmetal
                    : AppColors.crimsonRed,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid || controller.text.isEmpty
                    ? AppColors.gunmetal
                    : AppColors.crimsonRed,
                width: isValid || controller.text.isEmpty ? 1 : 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.amberGold,
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 20,
          child: Center(
            child: Text(
              score != null ? '= $score' : '',
              style: GoogleFonts.chivo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.amberGold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
