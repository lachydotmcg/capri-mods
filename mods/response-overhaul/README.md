# Response Overhaul

Capri writes her own pet, throw, dodge, greeting and chess lines with her brain instead of repeating the built-in ones, voices them with Fish Audio and never says the same one twice.

- Kind: code mod
- Made by: Mirit0

## What it does

- **Fresh lines, permanently.** Each reaction is generated ahead of time and kept ready.
- **Pre-rendered voice.** Lines are synthesized to WAV in the background and cached, so a reaction plays the instant it is triggered instead of waiting on a voice request mid-gesture.
- **Stays out of the way.** Nothing is generated while she is chatting, speaking, running a task or working a job.

## What it sends and touches

- **Her brain.** Every new line is written by the brain you've set for her, in the background, so a cloud brain spends your tokens or free messages on it. Greetings can include your last message or a short memory note, unless it looks like a password, token or key.
- **Fish Audio.** Lines go to the Fish Audio voice you've set under VOICE to be pre-rendered.
- **Cursor lock** (off by default) pins your cursor for 5 seconds. Esc lets go.
- **Icon shuffle** (off by default) minimises your windows, takes a picture of the desktop and asks Explorer where your icons are, then plays the shuffle over it and puts your windows back after 10 seconds.
- It reaches into Capri's own reaction, chess voice and greeting code, so a new Capri version can stop it working until the mod is updated.
- The voice cache keeps up to 2,400 WAV files in its folder.

## Settings

Four switches in the mod options:

| Switch | What it does |
| --- | --- |
| Allow 5-second cursor lock | Lets her pin your cursor as payback for rough handling. Esc releases it. |
| Allow icon shuffle | A visual-only desktop icon shuffle that restores after 10 seconds. Your real icons are never moved. |
| Enable Fish Audio emotion tags | Adds `[excited]`, `[upset]` and friends to synthesis only. Your bubble text stays clean. |
| Show floating dialogue loading bar | Keeps the progress bar on screen permanently. |

### Additions

Under **ADDITIONS**, the *Choose what she generates...* button opens a menu with four groups:

- Physical reactions (pets, throws, dodges, greetings)
- Chess and minigame lines
- Quick gaming reactions (kills, deaths, wins)
- Check-ins, clones, Cyberpunk and task lines

These are additions, not settings. Switch one off and Capri simply keeps her own built-in lines for it, exactly as she shipped. Changes apply straight away.

## The loading bar
Shows on first load and when generating new groups.

## Voice

Reaction audio needs **Fish Audio** selected as her server voice under VOICE. Without it she still generates and shows the new lines, she just speaks them with whatever voice is selected, and nothing is pre-rendered.

## Files it writes

All inside its own mod folder:

- `prepared-voices/` — cached WAVs, grouped by category and topic
- `reaction-spoken-blacklists/` — everything she has said, per topic
- `reaction-shown-history/` — everything that reached the screen
- `reaction-selected-history.txt` — every line ever reserved
- `reaction-delivery-history.tsv` — a log of completed reactions

Deleting the audio cache is safe. A missing WAV is simply re-synthesized; it does not bring retired dialogue back.

## Permissions

- `chat` — to read the current conversation so she does not talk over you, and to swap a reaction line before it is spoken
- `voice` — to pre-render and play her lines
- `memory` — to generate a response for greetings

## Editing it yourself

Two options at the top of the `.capri-code` file:

- `ShowAdvancedOptions` — set to `true` to put the advanced buttons back in the options pane
- `DefaultLinesPerAction` and `LinesPerAction` — how many unique lines to keep ready per reaction, 1 to 24
