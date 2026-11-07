# Screen Context Memory

Remember what you're working on across sessions. Track projects and time spent.

## Features

- **Context Saving** - Save your current work context
- **Session Tracking** - Automatically track time per project
- **Statistics** - See which projects take the most time
- **Context Recall** - Remember what you were doing hours or days later
- **Project List** - View all your recent projects

## Commands

- `context save [name]` - Save current context with optional name
- `what was I doing` - Recall your last context
- `context stats` - View time statistics by project
- `context list` - List recent contexts
- `context help` - Show all commands

## Usage

```
You: "Capri, context save Python homework"
Capri: "Context saved as 'Python homework'. Je retiens ça."

You: "what was I doing"
Capri: "Dernier context: Python homework. Il y a 2 heures. Temps total: 45 minutes."

You: "context stats"
Capri: "Top sessions: Python homework (45 min), API project (120 min), Bug fixing (30 min). Total tracké: 195 minutes."
```

## How It Works

Screen Context Memory saves named contexts with timestamps. When you return to a context within 60 minutes, it adds the elapsed time to that project's total. This gives you insight into how you spend your work time.

Data is stored in `contexts/sessions.txt`.

## Author

**flaque** - November 2026

## Version

1.0.0
