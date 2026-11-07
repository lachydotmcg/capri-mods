# Focus Guard

Anti-distraction protection for Capri. Start focus mode with a timer and track your distractions.

## Features

- **Focus Mode Timer** - Set focus sessions from 5 to 240 minutes
- **Distraction Tracking** - Keeps count of distractions per session
- **Statistics** - Track total focus time and distraction rate
- **Auto-save** - All stats persist between sessions

## Commands

- `focus mode 30 minutes` - Start a focus session
- `am I focused` - Check remaining time and distractions
- `focus off` - End current session early
- `focus stats` - View your focus statistics
- `focus help` - Show all commands

## Usage

```
You: "Capri, focus mode 45 minutes"
Capri: "Focus mode on pour 45 minutes. Je te surveille. Pas de slack."

You: "am I focused"
Capri: "40 minutes restant. Aucune distraction pour l'instant. Continue."

You: "focus off"
Capri: "Session focus terminée. 5 minutes sur 45. Zéro distraction. Clean."
```

## How It Works

Focus Guard tracks your focus sessions and counts distractions. When you mention distracting sites (YouTube, Reddit, Twitter, etc.) during focus mode, it catches you and increments the distraction counter.

All statistics are saved locally in `focus-stats.txt`.

## Author

**flaque** - November 2026

## Version

1.0.0
