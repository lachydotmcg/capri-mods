# Gaming Coach

Track your gaming sessions, performance, and detect when you're tilting.

## Features

- **Game Timer** - Track how long each game takes
- **Win/Loss Recording** - Record results and calculate win rate
- **Tilt Detection** - Analyzes your recent games to detect tilt
- **Streak Tracking** - Tracks winning and losing streaks
- **Statistics** - Total games, win rate, hours played

## Commands

- `chrono this game` - Start game timer
- `I won` / `I lost` - Record game result
- `am I tilted` - Check if you're tilting based on recent games
- `game stats` - View overall statistics
- `streak check` - Check current win/loss streak
- `game help` - Show all commands

## Usage

```
You: "Capri, chrono this game"
Capri: "Timer game lancé. Montre ce que t'as."

You: "I won"
Capri: "W enregistrée. 23 minutes. 3 win streak, continue comme ça!"

You: "am I tilted"
Capri: "Ouais t'es tilt. 6 losses sur 10 games en 3 heures. Pause obligatoire."
```

## How It Works

Gaming Coach times your games and tracks results. It detects tilt by analyzing:
- Loss rate in recent games (last 10)
- Session length (warns if playing 2+ hours with many losses)
- Provides suggestions for breaks when appropriate

All game data is saved in `game-sessions.txt`.

## Author

**flaque** - November 2026

## Version

1.0.0
