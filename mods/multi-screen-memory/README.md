# Multi-Screen Memory

Remember what was on your screen. Track screen history and find previous contexts.

## Features

- **Screen Snapshots** - Save important screens manually
- **Auto-capture** - Automatically captures context switches
- **History Tracking** - Keeps last 50 screen snapshots
- **Search** - Find previous screens by keyword
- **View Counts** - Tracks how often you revisit contexts

## Commands

- `save this screen [description]` - Mark current screen as important
- `what was on screen before` - Recall previous screen
- `screen history` - Show recent screens (last 8)
- `find that page [keyword]` - Search screen history
- `screen help` - Show all commands

## Usage

```
You: "Capri, save this screen API documentation"
Capri: "Screen saved as 'API documentation'. I'll remember this."

You: "what was on screen before"
Capri: "Before this: API documentation, 5 minutes ago."

You: "screen history"
Capri: "Recent screens: API documentation (5m ago), Code editor (10m ago), Terminal (15m ago)"

You: "find that page Python"
Capri: "Found: Python tutorial, 2 hours ago."
```

## How It Works

Multi-Screen Memory captures screen descriptions with timestamps. It automatically detects context switches when you mention opening/switching apps. Saved screens get higher priority in searches. The mod tracks view counts to identify frequently revisited contexts.

Data stored in `screen-memory/history.txt`.

## Author

**flaque** - November 2026

## Version

1.0.0
