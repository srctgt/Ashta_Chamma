import 'dart:math';

/// The type of dice/shell being used.
enum DiceMode {
  /// Traditional cowrie shells (4 shells, values: 1, 2, 3, 4, 8).
  cowrieShells,

  /// Regular 6-sided dice (values: 1-6).
  regularDice,
}

/// Result of a dice/shell roll.
class DiceResult {
  /// The value rolled.
  final int value;

  /// Whether this roll grants a bonus turn.
  final bool grantsBonusTurn;

  /// Whether this roll allows a pawn to enter the board.
  final bool allowsEntry;

  /// Individual shell results (only for cowrie mode). true = mouth up.
  final List<bool>? shellResults;

  const DiceResult({
    required this.value,
    required this.grantsBonusTurn,
    required this.allowsEntry,
    this.shellResults,
  });

  @override
  String toString() =>
      'DiceResult(value: $value, bonus: $grantsBonusTurn, entry: $allowsEntry)';
}

/// Simulates dice/cowrie shell rolls.
class Dice {
  final DiceMode mode;
  final Random _random;

  Dice({
    this.mode = DiceMode.cowrieShells,
    Random? random,
  }) : _random = random ?? Random();

  /// Rolls the dice/shells and returns the result.
  DiceResult roll() {
    switch (mode) {
      case DiceMode.cowrieShells:
        return _rollCowrieShells();
      case DiceMode.regularDice:
        return _rollRegularDice();
    }
  }

  /// Creates a DiceResult from a specific cowrie shell value (for testing/replay).
  static DiceResult cowrieResult(int value) {
    assert(
      value == 1 || value == 2 || value == 3 || value == 4 || value == 8,
      'Cowrie shell value must be 1, 2, 3, 4, or 8',
    );
    return DiceResult(
      value: value,
      grantsBonusTurn: isBonusTurnValue(value, DiceMode.cowrieShells),
      allowsEntry: isEntryValue(value, DiceMode.cowrieShells),
    );
  }

  /// Creates a DiceResult from a specific regular dice value (for testing/replay).
  static DiceResult regularResult(int value) {
    assert(value >= 1 && value <= 6, 'Regular dice value must be 1-6');
    return DiceResult(
      value: value,
      grantsBonusTurn: isBonusTurnValue(value, DiceMode.regularDice),
      allowsEntry: isEntryValue(value, DiceMode.regularDice),
    );
  }

  /// Forces a roll that produces an entry value (4 or 8) for cowrie shells.
  /// Randomly picks between 4 (all mouth up) and 8 (all mouth down).
  DiceResult forceEntryRoll() {
    switch (mode) {
      case DiceMode.cowrieShells:
        return _forceCowrieEntryRoll();
      case DiceMode.regularDice:
        // For regular dice, entry value is 6
        return const DiceResult(
          value: 6,
          grantsBonusTurn: true,
          allowsEntry: true,
        );
    }
  }

  DiceResult _forceCowrieEntryRoll() {
    // Randomly pick between 4 (Chamma - all mouth up) and 8 (Ashta - all mouth down)
    final allMouthUp = _random.nextBool();
    if (allMouthUp) {
      // Chamma: all 4 shells mouth up = value 4
      return const DiceResult(
        value: 4,
        grantsBonusTurn: true,
        allowsEntry: true,
        shellResults: [true, true, true, true],
      );
    } else {
      // Ashta: all 4 shells mouth down = value 8
      return const DiceResult(
        value: 8,
        grantsBonusTurn: true,
        allowsEntry: true,
        shellResults: [false, false, false, false],
      );
    }
  }

  DiceResult _rollCowrieShells() {
    // Simulate 4 cowrie shells, each with 50% chance mouth-up
    final shells = List.generate(4, (_) => _random.nextBool());
    final mouthUpCount = shells.where((s) => s).length;

    final value = _cowrieValue(mouthUpCount);
    return DiceResult(
      value: value,
      grantsBonusTurn: isBonusTurnValue(value, DiceMode.cowrieShells),
      allowsEntry: isEntryValue(value, DiceMode.cowrieShells),
      shellResults: shells,
    );
  }

  DiceResult _rollRegularDice() {
    final value = _random.nextInt(6) + 1;
    return DiceResult(
      value: value,
      grantsBonusTurn: isBonusTurnValue(value, DiceMode.regularDice),
      allowsEntry: isEntryValue(value, DiceMode.regularDice),
    );
  }

  /// Converts mouth-up count to cowrie shell value.
  static int _cowrieValue(int mouthUpCount) {
    switch (mouthUpCount) {
      case 0:
        return 8; // Ashta - all mouth down
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 4; // Chamma - all mouth up
      default:
        throw ArgumentError('Invalid mouth-up count: $mouthUpCount');
    }
  }

  /// Returns the cowrie shell value for a given mouth-up count.
  /// Exposed for testing purposes.
  static int cowrieValueFromMouthUp(int mouthUpCount) {
    return _cowrieValue(mouthUpCount);
  }

  /// Checks if a value grants a bonus turn for the given mode.
  static bool isBonusTurnValue(int value, DiceMode mode) {
    switch (mode) {
      case DiceMode.cowrieShells:
        return value == 4 || value == 8;
      case DiceMode.regularDice:
        return value == 6;
    }
  }

  /// Checks if a value allows a pawn to enter the board.
  static bool isEntryValue(int value, DiceMode mode) {
    switch (mode) {
      case DiceMode.cowrieShells:
        return value == 4 || value == 8;
      case DiceMode.regularDice:
        return value == 6;
    }
  }
}
