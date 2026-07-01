# Current Status - Ashta Chamma

## Project Overview

- **Project:** Ashta Chamma - Traditional Indian board game
- **Platform:** Android, iOS & Web (Flutter)
- **Repository:** srctgt/Ashta_Chamma
- **Branch:** feat/side-dice-layout

## What Has Been Built

### Core Gameplay (Complete)
- 5x5 board with traditional layout
- 2-player mode (pass-and-play on same device)
- Shell + dice simulation
- Human vs Human mode
- Human vs AI mode (heuristic-based AI)
- CustomPainter board rendering
- Traditional Indian art style theme
- 154 tests passing

### Web Support (Complete)
- Flutter Web platform added (web/ directory with index.html, manifest.json, icons)
- Responsive layout with max-width constraints for desktop browsers
- GitHub Pages deployment workflow (.github/workflows/deploy-web.yml)
- Auto-deploys on push to main branch

### Responsive Side Dice Layout (Complete)
- Wide screens (>=700px): Board on left, dice/info side panel on right
- Narrow screens (<700px): Vertical layout (info top, board center, dice bottom)
- Side panel includes: player turn info, dice/shell animation (larger), Roll button, bonus turn indicator, status messages
- Decorative gradient top border with traditional Indian theme colors
- Card-like container with shadow and border for visual polish
- Dice/shell elements scale up in expanded mode for better visibility

### Dice/Shell Animations (Complete)
- Shell flip animation with staggered timing
- Dice spin animation with perspective rotation
- Golden glow reveal effect
- Bonus turn scale-pop animation
- Sound effects for roll, reveal, and bonus events

### Architecture

```
lib/
  models/       - Board, Pawn, Player models
  logic/        - Dice, BoardPath, MoveValidator, GameState, GameController
  ai/           - AiPlayer, MoveScorer
  ui/           - Theme, GameProvider, Screens, Widgets

web/            - Flutter Web entry point (index.html, manifest.json, icons)
.github/workflows/deploy-web.yml - GitHub Pages deployment
```

## Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| Flutter | Cross-platform (Android + iOS + Web) from single codebase |
| Provider | Lightweight state management suitable for game state |
| CustomPainter | Full control over board rendering and visual fidelity |
| Heuristic-based AI | Simple, performant AI without external dependencies |
| GitHub Pages | Free, reliable hosting for the web build |
| LayoutBuilder responsive | Adapts layout based on screen width (700px breakpoint) |

## Completed Items

- Core game logic with all rules
- 2-player pass-and-play mode
- Human vs AI mode
- CustomPainter board rendering
- Traditional Indian art style theme
- 154 unit and widget tests
- Web platform support
- Responsive layout for mobile and desktop browsers
- Deploy to GitHub Pages workflow
- Dice/shell rolling animations with sound effects
- Responsive side dice layout (board left, dice panel right on wide screens)
- Removed Chowka Bhara subtitle from home screen
- Renamed "Cowrie Shells" to "Shells" in UI

## Critical Bug Fixes

### Dice Roll Blocked by Animation Guard (Fixed)
- **Bug:** Pawns never moved after rolling 4 or 8. The game appeared stuck in the rolling phase.
- **Root Cause:** In `_onRollAnimationStatus` (dice_widget.dart), `widget.onRoll?.call()` was called while `isAnimating` was still `true`. But `provider.rollDice()` (game_provider.dart) had a guard `if (... || _isAnimating) return;` that silently blocked the roll. The `onAnimationEnd` callback (which clears `isAnimating`) was called AFTER `onRoll`, so the roll never executed.
- **Fix:** (1) Removed `_isAnimating` from `rollDice()` guard since the disabled Roll button already prevents double-taps during animation. Kept `_isAnimating` check in `selectPawn()` to prevent pawn selection during reveal. (2) Reordered callbacks in `_onRollAnimationStatus` so `onAnimationEnd` fires before `onRoll` for logical correctness.

## In Progress

- Nothing currently in progress

## Next Steps / Future Phases

1. **4-Player Mode** - Expand game logic to support 4 players with appropriate board paths
2. **Larger Board Sizes** - Support 7x7 and 9x9 board variants
3. **Pawn Movement Animations** - Animate pawns sliding along board paths
4. **Online Multiplayer** - Real-time multiplayer via Firebase or similar backend
5. **Leaderboards & Game History** - Track wins/losses, game replays, player statistics

## Last Updated

2026-06-30
