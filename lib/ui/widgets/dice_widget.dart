import 'dart:math';

import 'package:flutter/material.dart';

import '../../logic/dice.dart';
import '../../logic/game_state.dart';
import '../sound_service.dart';
import '../theme.dart';

/// Widget that displays the dice/shell area with rolling animations.
///
/// Shows the current roll result and provides a roll button.
/// For shell mode, displays 4 shell icons (filled = mouth up) with
/// flip animations when rolling.
/// For regular dice mode, shows the dice value with dots pattern and
/// a spinning animation when rolling.
class DiceWidget extends StatefulWidget {
  /// The current dice result (null if not rolled yet).
  final DiceResult? diceResult;

  /// The dice mode.
  final DiceMode diceMode;

  /// Whether the roll button is enabled.
  final bool canRoll;

  /// Callback when the roll button is pressed.
  final VoidCallback? onRoll;

  /// Current game phase.
  final GamePhase phase;

  /// Whether an animation is currently playing (controlled by parent).
  final bool isAnimating;

  /// Callback to notify parent when animation starts.
  final VoidCallback? onAnimationStart;

  /// Callback to notify parent when animation ends.
  final VoidCallback? onAnimationEnd;

  /// Whether the widget is in expanded (side panel) mode with more space.
  final bool expanded;

  const DiceWidget({
    super.key,
    required this.diceResult,
    required this.diceMode,
    required this.canRoll,
    required this.phase,
    this.onRoll,
    this.isAnimating = false,
    this.onAnimationStart,
    this.onAnimationEnd,
    this.expanded = false,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  /// Main animation controller for the rolling animation.
  late AnimationController _rollController;

  /// Controller for the result reveal glow effect.
  late AnimationController _revealController;

  /// Controller for the bonus turn text animation.
  late AnimationController _bonusController;

  /// Individual shell flip controllers (4 shells with staggered timing).
  late List<AnimationController> _shellControllers;

  /// Dice spin animation.
  late Animation<double> _spinAnimation;

  /// Dice bounce animation.
  late Animation<double> _bounceAnimation;

  /// Reveal glow opacity animation.
  late Animation<double> _glowAnimation;

  /// Bonus text scale animation.
  late Animation<double> _bonusScaleAnimation;

  /// Whether the rolling animation is currently active.
  bool _isRolling = false;

  /// Random values shown during dice animation cycling.
  int _animatingDiceValue = 1;

  /// Random shell states during animation.
  List<bool> _animatingShells = [false, false, false, false];

  /// Timer for cycling random values during animation.
  final Random _random = Random();

  /// The last dice result that triggered animation completion.
  DiceResult? _lastAnimatedResult;

  /// Sound service for playing sound effects.
  final SoundService _soundService = SoundService();

  @override
  void initState() {
    super.initState();

    _soundService.initialize();

    // Main roll animation: 1.2 seconds for shells, 1 second for dice
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Reveal glow: quick pulse
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Bonus text animation
    _bonusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Shell controllers with staggered timing
    _shellControllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (index * 100)),
      ),
    );

    // Dice spin: multiple rotations that slow down
    _spinAnimation = CurvedAnimation(
      parent: _rollController,
      curve: Curves.easeOutCubic,
    );

    // Bounce effect near the end
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 10),
    ]).animate(_rollController);

    // Glow animation
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(_revealController);

    // Bonus scale: pop in
    _bonusScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _bonusController,
      curve: Curves.easeOutBack,
    ));

    _rollController.addStatusListener(_onRollAnimationStatus);
    _rollController.addListener(_onRollTick);
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When a new dice result arrives and we are not already animating,
    // trigger the reveal animation
    if (widget.diceResult != null &&
        widget.diceResult != oldWidget.diceResult &&
        widget.diceResult != _lastAnimatedResult &&
        !_isRolling) {
      _lastAnimatedResult = widget.diceResult;
      _playRevealAnimation();
    }
  }

  void _onRollTick() {
    if (!_isRolling) return;

    // Cycle random values during animation to create the "spinning" effect
    final progress = _rollController.value;

    // Slow down cycling as animation progresses
    final shouldCycle = progress < 0.8;
    if (shouldCycle && mounted) {
      setState(() {
        if (widget.diceMode == DiceMode.cowrieShells) {
          _animatingShells = List.generate(4, (_) => _random.nextBool());
        } else {
          _animatingDiceValue = _random.nextInt(6) + 1;
        }
      });
    }
  }

  void _onRollAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Stop all shell repeating controllers
      for (final controller in _shellControllers) {
        controller.stop();
        controller.reset();
      }

      setState(() {
        _isRolling = false;
      });

      // Notify parent that animation is done BEFORE calling roll logic
      // so that isAnimating is cleared before rollDice() executes.
      widget.onAnimationEnd?.call();

      // Now call the actual roll logic
      widget.onRoll?.call();

      // Play result reveal sound
      _soundService.playResultReveal();
    }
  }

  /// Starts the rolling animation.
  void _startRollAnimation() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
      _animatingDiceValue = _random.nextInt(6) + 1;
      _animatingShells = List.generate(4, (_) => _random.nextBool());
    });

    // Notify parent animation has started
    widget.onAnimationStart?.call();

    // Play sound
    if (widget.diceMode == DiceMode.cowrieShells) {
      _soundService.playShellThrow();
    } else {
      _soundService.playDiceRoll();
    }

    // Start the main roll animation
    _rollController.reset();
    _rollController.forward();

    // Start shell flip animations with stagger
    if (widget.diceMode == DiceMode.cowrieShells) {
      for (int i = 0; i < _shellControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 150), () {
          if (mounted && _isRolling) {
            _shellControllers[i].reset();
            _shellControllers[i].repeat(reverse: true);
          }
        });
      }
    }
  }

  void _playRevealAnimation() {
    _revealController.reset();
    _revealController.forward();

    // Bonus turn animation
    if (widget.diceResult?.grantsBonusTurn == true) {
      _bonusController.reset();
      _bonusController.forward();
      _soundService.playBonusTurn();
    }
  }

  @override
  void dispose() {
    _rollController.removeStatusListener(_onRollAnimationStatus);
    _rollController.removeListener(_onRollTick);
    _rollController.dispose();
    _revealController.dispose();
    _bonusController.dispose();
    for (final controller in _shellControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expanded) {
      return _buildExpandedLayout();
    }
    return _buildCompactLayout();
  }

  /// Compact layout for narrow screens (horizontal row).
  Widget _buildCompactLayout() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AshtaChammaTheme.cream,
        border: Border(
          top: BorderSide(
            color: AshtaChammaTheme.boardLines,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dice display area
          Expanded(
            child: _buildDiceDisplay(),
          ),
          // Roll button
          _buildRollButton(),
        ],
      ),
    );
  }

  /// Expanded layout for side panel (vertical column with more space).
  Widget _buildExpandedLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dice display area (larger)
        Expanded(
          child: Center(
            child: _buildDiceDisplay(large: true),
          ),
        ),
        const SizedBox(height: 16),
        // Roll button (larger in expanded mode)
        _buildRollButton(large: true),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDiceDisplay({bool large = false}) {
    if (!_isRolling && widget.diceResult == null) {
      return Center(
        child: Text(
          'Tap Roll to start',
          style: TextStyle(
            color: AshtaChammaTheme.subtitleColor,
            fontSize: large ? 16 : 14,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_rollController, _revealController]),
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Roll value display with glow
            _buildValueDisplay(large: large),
            SizedBox(height: large ? 12 : 4),
            // Shell or dice icons
            if (widget.diceMode == DiceMode.cowrieShells)
              _buildAnimatedShellDisplay(large: large)
            else
              _buildAnimatedDiceDots(large: large),
            // Bonus turn indicator
            _buildBonusTurnIndicator(large: large),
          ],
        );
      },
    );
  }

  Widget _buildValueDisplay({bool large = false}) {
    final displayValue = _isRolling
        ? (_animatingDiceValue.toString())
        : (widget.diceResult?.value.toString() ?? '');

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _glowAnimation.value > 0
                ? [
                    BoxShadow(
                      color:
                          AshtaChammaTheme.gold.withAlpha(
                            (200 * _glowAnimation.value).toInt(),
                          ),
                      blurRadius: 12 * _glowAnimation.value,
                      spreadRadius: 4 * _glowAnimation.value,
                    ),
                  ]
                : null,
          ),
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRolling ? _bounceAnimation.value : 1.0,
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: large ? 48 : 32,
                    fontWeight: FontWeight.bold,
                    color: _isRolling
                        ? AshtaChammaTheme.deepRed.withAlpha(150)
                        : AshtaChammaTheme.deepRed,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimatedShellDisplay({bool large = false}) {
    final shells = _isRolling
        ? _animatingShells
        : (widget.diceResult?.shellResults ?? [false, false, false, false]);

    final shellSize = large ? 32.0 : 20.0;
    final spacing = large ? 6.0 : 3.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final mouthUp = shells[index];
        if (_isRolling && index < _shellControllers.length) {
          return AnimatedBuilder(
            animation: _shellControllers[index],
            builder: (context, child) {
              final flipValue = _shellControllers[index].value;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateX(flipValue * pi)
                    ..setTranslationRaw(
                      0.0,
                      sin(flipValue * pi * 2) * 4, // bounce up/down
                      0.0,
                    ),
                  child: _buildShellCircle(mouthUp, size: shellSize),
                ),
              );
            },
          );
        }

        // Static shell (after animation or when no result yet)
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: _buildShellCircle(mouthUp, size: shellSize),
        );
      }),
    );
  }

  Widget _buildShellCircle(bool mouthUp, {double size = 20}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: mouthUp ? AshtaChammaTheme.ochre : Colors.transparent,
        border: Border.all(
          color: AshtaChammaTheme.boardLines,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildAnimatedDiceDots({bool large = false}) {
    final value = _isRolling
        ? _animatingDiceValue
        : (widget.diceResult?.value ?? 1);

    if (_isRolling) {
      return AnimatedBuilder(
        animation: _spinAnimation,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // perspective
              ..rotateY(_spinAnimation.value * pi * 4) // spin
              ..rotateX(sin(_spinAnimation.value * pi) * 0.3), // wobble
            child: _buildDiceBox(value, large: large),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        final scale = _rollController.isAnimating ? _bounceAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: _buildDiceBox(value, large: large),
        );
      },
    );
  }

  Widget _buildDiceBox(int value, {bool large = false}) {
    final boxSize = large ? 60.0 : 40.0;
    final dotSize = large ? 9.0 : 6.0;
    final dotSpacing = large ? 5.0 : 3.0;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(large ? 10 : 6),
        border: Border.all(color: AshtaChammaTheme.boardLines, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Center(
        child: _buildDotsPattern(value, dotSize: dotSize, spacing: dotSpacing),
      ),
    );
  }

  Widget _buildDotsPattern(int value,
      {double dotSize = 6, double spacing = 3}) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(
        value,
        (_) => Container(
          width: dotSize,
          height: dotSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AshtaChammaTheme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBonusTurnIndicator({bool large = false}) {
    if (_isRolling) return const SizedBox.shrink();

    if (widget.diceResult?.grantsBonusTurn != true) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _bonusScaleAnimation,
      builder: (context, child) {
        final scale = _bonusController.isAnimating
            ? _bonusScaleAnimation.value
            : 1.0;
        return Padding(
          padding: EdgeInsets.only(top: large ? 8 : 4),
          child: Transform.scale(
            scale: scale,
            child: Text(
              'Bonus turn!',
              style: TextStyle(
                color: AshtaChammaTheme.gold,
                fontWeight: FontWeight.bold,
                fontSize: large ? 16 : 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRollButton({bool large = false}) {
    final canPress = widget.canRoll && !_isRolling && !widget.isAnimating;

    return ElevatedButton(
      onPressed: canPress ? _startRollAnimation : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canPress
            ? AshtaChammaTheme.terracotta
            : AshtaChammaTheme.terracotta.withAlpha(100),
        foregroundColor: AshtaChammaTheme.cream,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 36 : 24,
          vertical: large ? 18 : 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(large ? 12 : 8),
        ),
      ),
      child: Text(
        _isRolling ? '...' : 'Roll',
        style: TextStyle(
          fontSize: large ? 22 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
