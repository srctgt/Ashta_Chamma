# Current Status - Ashta Chamma (Chowka Bhara)

## Project Overview

- **Project:** Ashta Chamma (Chowka Bhara) - Traditional Indian board game
- **Platform:** Android & iOS (Flutter)
- **Repository:** srctgt/Ashta_Chamma
- **Branch:** feat/ashta-chamma-game

## What Has Been Built

### Core Gameplay (Complete)
- 5x5 board with traditional layout
- 2-player mode (pass-and-play on same device)
- Cowrie shell + dice simulation
- Human vs Human mode
- Human vs AI mode (heuristic-based AI)
- CustomPainter board rendering
- Traditional Indian art style theme
- 152 tests passing

### Architecture

```
lib/
  models/       - Board, Pawn, Player models
  logic/        - Dice, BoardPath, MoveValidator, GameState, GameController
  ai/           - AiPlayer, MoveScorer
  ui/           - Theme, GameProvider, Screens, Widgets
```

## Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| Flutter | Cross-platform (Android + iOS) from single codebase |
| Provider | Lightweight state management suitable for game state |
| CustomPainter | Full control over board rendering and visual fidelity |
| Heuristic-based AI | Simple, performant AI without external dependencies |

## In Progress

- Nothing currently in progress

## Next Steps / Future Phases

1. **Animations & Sound Effects** - Pawn movement animations, dice rolling animations, sound effects for moves and captures
2. **4-Player Mode** - Expand game logic to support 4 players with appropriate board paths
3. **Larger Board Sizes** - Support 7x7 and 9x9 board variants
4. **Online Multiplayer** - Real-time multiplayer via Firebase or similar backend
5. **Leaderboards & Game History** - Track wins/losses, game replays, player statistics

## Last Updated

2026-06-30
