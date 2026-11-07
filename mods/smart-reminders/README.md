# Smart Reminders Plus

Context-aware reminders. Set time-based reminders or reminders that trigger when you return to a specific context.

## Features

- **Time-based Reminders** - "Remind me in X minutes"
- **Context-based Reminders** - "Remind me when I'm back on Visual Studio"
- **Auto-trigger** - Context reminders fire when you mention that context again
- **Reminder List** - View all active reminders
- **Persistent** - Reminders survive Capri restarts

## Commands

- `remind me in X minutes to [task]` - Set timed reminder
- `remind me when I'm back on [context] to [task]` - Set context reminder
- `list reminders` - Show active reminders
- `clear reminders` - Delete all reminders
- `reminder help` - Show all commands

## Usage

```
You: "Capri, remind me in 20 minutes to check the oven"
Capri: "Reminder set for 20 minutes from now. I'll ping you."

[20 minutes later]
Capri: "Reminder: check the oven"

You: "remind me when I'm back on Visual Studio to fix the login bug"
Capri: "Reminder set for when you're back on Visual Studio. I'm watching."

[Later when you mention Visual Studio]
Capri: "Reminder for Visual Studio: fix the login bug"
```

## How It Works

Smart Reminders tracks both time-based and context-based reminders. Context reminders wait for you to mention the trigger word in conversation, then fire automatically. Time reminders check every time you speak to Capri.

Data stored in `reminders.txt`.

## Author

**flaque** - November 2026

## Version

1.0.0
