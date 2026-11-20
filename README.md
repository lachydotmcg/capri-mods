# Capri mods

Mods for [Capri](https://github.com/lachydotmcg/capri-desktop), the desktop companion. Find one you like, or share your own.

Every mod is checked for malware before it goes up here.

## Kinds of mod
- **Settings mods** (`.capri-mod`): extra names, colours and other settings. In Capri 0.8.5 or newer, a mod that only changes her colours shows under Skins.
- **Code mods** (`.capri-code`): C# that Capri compiles and runs. Code mods can do anything on your PC, so Capri asks before running one.
- **Skins** (`.capri-skin`): a zip of pictures that replace her art.
- **Skills** (`.capri-skill`): know-how for a game, like what to build and when. Capri follows it whenever she plays that game. Skills need Capri 0.8.4 or newer.
- **Companion packs** (`.capri-companion`): a companion of your own, with its own name, personality, voice and art, on instead of Capri until you turn it off. They hold no code, and her safety lines always apply. Companion packs need the Capri release after 0.9.4.

## Using a mod
In Capri 0.8.3 or newer, open Capri Mainframe and press Mods in the CAPRI band. Browse mods lists everything here with previews, downloads and ratings, and Install puts a mod in and turns it on. You can also download a mod file from here and use Import mod.

## Sharing a mod
1. Fork this repo.
2. Add a folder under `mods/` named after your mod. Put in the mod file and a short `README.md` that says what it does. Your GitHub username goes on it as the author. Add a `- Made by:` line if you'd like a different name.
3. Add a picture called `preview.png`, around 16:9, if you have one. That picture is what people see in Capri's mods window. Mods without one get a default picture.
4. Open a pull request.

Code mods can be up to 1 MB in Capri 0.9.4 or newer (256 KB before). If yours downloads extra files, like games or translations, write each file's SHA-256 in the mod and refuse any file that doesn't match. Then changing those files means a new mod version, and it's read like any other.

## What the mod check looks for
Every pull request that touches `mods/` gets the same checks Capri itself makes, and the run's summary page lists what it found. A mod that trips a hard rule can't be listed:
- A code mod over 1 MB.
- A code mod that hides its code: it unpacks or decrypts text and also loads code while it runs, so what you can read isn't what would run.
- A plug-in that isn't a plain zip in Claude's plug-in layout: over 1 MB, more than 400 files, over 8 MB unpacked, any file over 4 MB, or file names that point outside the zip.
- A plug-in whose server starts with an encoded PowerShell command, downloads something and runs it, or unpacks something hidden and runs it.
- A plug-in that runs `npx`, `bunx`, `pnpx` or `uvx` without a pinned version, so what runs can't change after it's read.
- A key written into any file of the mod.

Other things only get listed for the person reading the pull request: what a code mod can reach (programs, the network, Windows, the keyboard, what Capri is told), the sites it contacts, code that's hard to read, reaching into Capri's own settings folder, and plug-ins that pass secret-looking settings through from your environment.

To run it yourself: `python3 tools/check-mods.py my-mod-folder`.

## Submit without git
No git needed: fill in the [Submit a mod](https://github.com/lachydotmcg/capri-mods/issues/new?template=submit-mod.yml) form and drag your mod file in, zipped first. A pull request gets opened for you, with your GitHub username as the author, and it's read like any other mod before it goes up. To change something, edit your issue.

## Stay safe
- Only install mods from here, or from people you trust.
- Only get Capri itself from [capriai.app](https://capriai.app) or [its GitHub](https://github.com/lachydotmcg/capri-desktop/releases).

Questions? Ask on the [Capri Discord](https://discord.gg/capridesktop).
