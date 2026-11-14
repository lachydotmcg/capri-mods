# Capri Discord Status

Tell Capri what your Discord status should say. It shows on her Discord status ("Playing Capri") for 5 hours, then goes back to her normal one by itself. It never puts anything inappropriate or offensive on it.

- Kind: code mod
- Made by: tob7as
- Needs: Capri 0.9.0 or newer, the Discord app open, and Discord presence turned on in her settings
- Windows only

| Say | She says |
|---|---|
| hey capri update my discord capri status to "watching One Piece" | Done. My Discord status says "Watching One Piece" now. It goes back to normal in 5 hours. |
| capri put my status as playing Minecraft | Okay, "Playing Minecraft" is up on my Discord status for the next 5 hours. |
| hey capri make my capri status studying for exams | Got it. "Studying for Exams" it is, for 5 hours. |
| capri put my status back to normal | Okay, my Discord status is back to normal. |
| what's my capri status | My Discord status says Watching One Piece. It goes back to normal in 4 hours 20 minutes. |
| put my status as (something rude) | Nope, I'm not putting that on my Discord status. Pick something else. |

You can also say "set my discord status to ...", "change my capri status to ..." or "capri status: ...". To end it early, say any of "reset my status", "clear my status", "go back to normal", "set my status to default" or "no more custom status". Said out loud, it arrives in lower case, so she tidies it: "watching one piece" shows as "Watching One Piece". A status can be up to 60 characters.

Her own "Playing Capri" status can't take outside text, so while yours is up the mod switches hers off in her settings and shows yours through Discord the same way she does, with her picture and her two buttons. When yours ends, it hangs up and switches hers back on. If you switch her own status back on yourself, yours ends. If you had Discord presence off, she won't turn it on for you. Restarting Capri keeps your status until its 5 hours are up.

**Staying clean.** Two checks, one after the other. First a word list on your PC: sexual or suggestive words, swearing, slurs, hate, threats, self-harm, drugs, links, emails, phone numbers, `@mentions` and number codes like 69 and 420, even when they're disguised (`f u c k`, `sh1t`, hidden spaces). You can add your own words, one a line, to `blocked-words.txt` in the mod's folder. Then her brain is asked if the text is fine for all ages. If her brain isn't set up or doesn't answer, only the word list decides, and if it answers but isn't clear the status is refused. She never says the refused text back, and it isn't written to any log.

**What it sends.** The status goes to Discord, and to the brain you already use for the check (a few words, so it uses a tiny bit of your credit). It also asks capriai.app, the same site Capri's own status uses, whether her moving picture is there. Nothing else leaves your PC. It asks for the `settings` and `brain` permissions. It reads her Discord app id from Capri's own code, with the same id built in as a fallback, so a Capri update that changes that can stop it working until the mod is updated.
