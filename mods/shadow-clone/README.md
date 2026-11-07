# Shadow Clone

Your debug partner and brainstorm assistant. Capture contexts, track bugs, and get suggestions.

## Features

- **Context Capture** - Save what you're working on with notes
- **Bug Tracking** - Track bugs with IDs and context
- **Context Comparison** - Compare current state with previous captures
- **Smart Suggestions** - Get contextual ideas based on what you're doing
- **Problem Analysis** - Analyzes captured context for common issues

## Commands

- `look at this` / `regarde ça` - Capture current context
- `track this bug [description]` - Log a bug
- `list bugs` - Show open bugs
- `compare with before` - Compare with previous capture
- `any ideas?` - Get contextual suggestions
- `analyze this` - Analyze current context for problems
- `clear context` - Clear current context
- `clone help` - Show all commands

## Usage

```
You: "Capri, look at this API timeout issue"
Capri: "Got it. Context captured: API timeout issue. I'm watching this, choom."

You: "track this bug connection fails after 30 seconds"
Capri: "Bug #1 tracked: connection fails after 30 seconds. I'll remember this."

You: "any ideas?"
Capri: "Add logging to trace where it fails."

You: "list bugs"
Capri: "1 open bug: #1: connection fails after 30 seconds"
```

## How It Works

Shadow Clone captures contexts and bugs with timestamps. It provides contextual suggestions based on the type of work (bug, code, general). The compare feature shows time elapsed and context changes.

Data stored in `contexts.txt` and `bugs.txt`.

## Author

**flaque** - November 2026

## Version

1.0.0
