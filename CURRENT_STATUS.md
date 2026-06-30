# Current Status - Ashta Chamma (Chowka Bhara)

## Project Overview

- **Project:** Ashta Chamma (Chowka Bhara) - Traditional Indian board game
- **Platform:** Android, iOS & Web (Flutter)
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

### Web Support (Complete)
- Flutter Web platform added (web/ directory with index.html, manifest.json, icons)
- Responsive layout with max-width constraints for desktop browsers
- GitHub Pages deployment workflow (.github/workflows/deploy-web.yml)
- Auto-deploys on push to main branch

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

## Completed Items

- Core game logic with all rules
- 2-player pass-and-play mode
- Human vs AI mode
- CustomPainter board rendering
- Traditional Indian art style theme
- 152 unit tests
- Web platform support
- Responsive layout for mobile and desktop browsers
- Deploy to GitHub Pages workflow
- Dice/cowrie shell rolling animations with sound effects

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
