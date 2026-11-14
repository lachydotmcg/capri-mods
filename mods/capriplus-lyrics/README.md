# Capri+ Lyrics

Synced lyrics slide out of Capri's music player as a drawer in her style, line by line in time with the song, and react to the music.

- Kind: code mod
- Needs: Capri 0.8.9 or newer, on Windows

An unofficial community mod. It isn't made by or affiliated with Capri's developer, CD PROJEKT RED or Studio Trigger.

Play a song in Spotify (or any app that shows in Windows' media controls). About two seconds in, a lyrics drawer opens out of the side or bottom of her mini player:
- **The lines:** the line being sung, with the next one after it.
- **Changing lines:** each new line decodes in behind her typing caret, and the old one breaks up as it leaves.
- **With the music:** it breathes and glitches in her pink and cyan.

With her mini player off, the lyrics hang under her in her speech-bubble style instead.

Code mods run C# on your PC, so she asks before turning one on. This one asks for one permission, **music**: to see what's playing and how loud your PC's sound is, for the reactions. It never controls your music, never uses your mic, and needs no other mod. Windows only.

## Privacy and network

- **Where lyrics come from:** [LRCLIB](https://lrclib.net), a free, community-built lyrics database.
- **What's sent:** for each new song, `https://lrclib.net/api/get` gets only the song's title, artist, album and length. Nothing about you, your PC, Capri or your chats is sent, and no account or key is used.
- **What LRCLIB sees:** like any website, it sees your IP address. Requests name this mod as the app asking.
- **Saved on your PC:** lyrics found go in this mod's folder, so a song plays offline next time. Songs LRCLIB doesn't have are remembered for 3 days, so they aren't asked about again and again.
- **Turning lookups off:** Options > untick "Look up lyrics on lrclib.net" and nothing more is sent. Saved lyrics still show.
- **Copyright:** lyrics belong to their writers. This mod shows them to you from LRCLIB and doesn't share them anywhere.

## Settings

Mainframe > Mods > Capri+ Lyrics > Options:

| Setting | Default | What it does |
|---|---|---|
| Show lyrics | on | Turns the lyrics on and off |
| Look up lyrics on lrclib.net | on | Off: only lyrics already saved on your PC show |
| Lyrics for videos too | off | Also for YouTube and other videos |
| Show over fullscreen apps and games | off | Normally they hide while a fullscreen game or video is in front |
| Lines | 2 | 1 (just the line), 2 (plus the next) or 3 (plus the last) |
| Text size | 15 | Size of the current line |
| Opacity | 92% | How see-through the drawer is |
| Distance from her | 0 | Only when they hang under her (mini player off) |
| Timing | 0 ms | Moves the lyrics earlier or later, -3000 to +3000 ms |
| Hide when paused after | 10 s | How long the lyrics stay after you pause |
| Music-reactive | subtle | Off (still), Subtle, Normal (stronger, with occasional strong glitches) or Intense |

Her right-click Mods menu also has *Capri+ lyrics: on/off*, *0.25 s earlier* and *0.25 s later* (to fix the timing while a song plays), *status*, and *music diagnostics*. If Windows' Animation effects are off (Settings > Accessibility > Visual effects), the reactions stay off.

## Troubleshooting

| What you see | Try |
|---|---|
| No lyrics at all | Right-click her > Mods > *Capri+ lyrics: status*. It says whether it found the song, is waiting, or LRCLIB had nothing. Many songs, and most instrumentals, have no synced lyrics |
| Lyrics early or late | *0.25 s earlier / later* from her Mods menu until they match. It's saved |
| No drawer, lyrics under her | Her mini player is off or hidden. Turn it on in Settings > Mini player |
| Nothing while a game is fullscreen | That's on purpose. Turn on "Show over fullscreen apps" in Options |
| Too much glitching | Options > Music-reactive: Subtle or Off |
| Wrong lyrics for a song | LRCLIB matched another version. Options > "Forget saved lyrics", then play it again |
| Something else | Copy the *status* line and any lines with `Capri+ Lyrics` from `errors.txt` in Capri's folder, and ask on the Capri Discord |

## Uninstall

1. Mainframe > Mods > Capri+ Lyrics > Remove. Its drawer closes and it stops at once.
2. Capri keeps each mod's own folder after removing it. To delete the saved lyrics and settings too:
   1. Press **Mods folder** on the same Mods page.
   2. Delete the `capriplus-lyrics-data` folder there.

   (For a Microsoft Store copy of Capri, that button opens the real folder inside Windows' app storage.)

Nothing else is left behind: no other files, no settings in Capri, and nothing in the registry.

## Changes

- **1.0.0:** first public release.

## Credits

- Lyrics from [LRCLIB](https://lrclib.net).
- Uses Capri's own font, colours and player style at runtime. Nothing of Capri's is copied into this file.
- Capri+ is a fan-made, unofficial project.
