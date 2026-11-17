# Capri Browser

A full web browser built into Capri. Capri can see the page you're on and use it with you: she opens sites, finds videos, controls playback, summarises pages and reads them out loud.

- Kind: code mod
- Version: 0.7
- Made by: tob7as
- Needs: **Capri 0.9.4 or newer** (it uses the larger 1 MB code mod limit to grow; 0.7 itself is about 256 KB) and the Microsoft Edge WebView2 engine (built into Windows 11)
- Windows only

## Say this

| Say | She does |
| --- | --- |
| "open Capri Browser" | Opens the browser |
| "open YouTube" / "open my browser" | Opens it in Capri Browser (Chrome, Edge and "my browser" all mean Capri Browser) |
| "find me a funny video" | Searches, picks a good one and plays it (or the first episode of a show) |
| "play the newest MrBeast video" | Plays the newest upload |
| "find me a Roblox game to play" | Searches Roblox, Steam, itch.io or the web, scrolls and opens the best one |
| "let's play snake" / "play wiki race" / "quiz me" | Starts that game (downloads it first if needed) |
| "bookmark this" | Adds the page to your bookmarks (Speed Dial). Also in the tab's right-click menu, or Ctrl+D |
| "what's new in Capri Browser?" | Tells you the update notes, then asks if you want her to remember them |
| "find a random website" | Opens a random interesting site (Site Roulette) |
| "add to my notes ..." / "note this down" / "write that down" | Puts what you said in a new Capri note |
| "research this" / "look into ..." / "do some research on ..." | Looks it up, then saves what she found in a new note |
| "pause" / "skip 30 seconds" / "louder" | Controls the video |
| "pop the video out" | Puts the video in a small floating window |
| "summarise this page" | Tells you what the page is about in a few lines |
| "read this to me" | Reads the page out loud |
| "find this cheaper" | Looks for the same thing at a lower price, and for coupon codes |

### Discord (off until you turn it on)

Turn on **Message via Discord in the browser** in Settings > Capri features. Capri finds the person, server or channel, then tells you exactly who and what and **waits for you to say yes** before she sends, calls or joins. She only acts on your own yes, never on something she read on a page.

| Say | She does |
| --- | --- |
| "message Sam on Discord hi" / "reply to Sam on Discord ok" / "open my Discord and tell Sam hi" | Opens Sam's chat, asks "Send "hi" to Sam?", sends on your yes |
| "call Sam on Discord" / "video call Sam" | Opens Sam's chat, asks, then starts the call on your yes |
| "open Minecraft general on Discord" | Opens that server and text channel |
| "join Minecraft gaming vc" | Finds the voice channel, asks, then joins on your yes |

She uses the Discord tab you already have open, and picks the closest name in your direct messages. If nobody there matches, she tries Discord's search and stops if its top result doesn't match the name.

## Also in it

- Ad blocking, plus warnings for scam sites and risky downloads
- Notes with screenshots, links and pictures
- History by topic and a weekly wrap-up
- Games: Wiki Race (with co-op codes), Guess the Site, Typing Race and Survival, Quiz, and more from Browser addons
- Achievements and browsing stats
- Capri's look: her colours, takeover animation and a hologram while she talks
- Every feature can be turned off in Settings

## What it changes in Capri

- **It replaces two of her tools.** While the mod is on, her `open_app` (for browsers) and `open_website` tools open pages in Capri Browser instead of your normal browser.
- **It adds a `capri_browser` tool** she uses to open, search, read, click, type and scroll. On messaging and social sites (Discord, Gmail, Outlook, WhatsApp, Messenger, Facebook, Instagram, X, Reddit, Telegram, Slack, Teams, LinkedIn, TikTok, Snapchat, Bluesky) a click, typing or Enter **waits for your yes**, so text on a page can't make her send something.
- **It moves your real mouse and presses keys** for some video controls: it clicks the video and presses F for full screen on sites that need a real click.

## What it sends, and where

Every turn, her brain gets a short note about the browser: the **title and address of the tab in front** (when a private tab is in front she gets nothing about it), and the **sites you use most**. Page text only goes to her brain when you ask her about a page. Private tabs are never read, and they are left out of the tab list she sees.

The mod itself (not the pages you visit) contacts:

| Host | Why |
| --- | --- |
| raw.githubusercontent.com ([tob7as/Browser-addons](https://github.com/tob7as/Browser-addons)) | Games, game lists, languages, the settings, Speed Dial, results, Games and History looks, video-site, search-engine and achievement lists, help, the Welcome page and update notes. The Welcome page offers **Download browser** (all at once, with progress) or **Download quietly in the background**; until then the browser uses small built-in English defaults |
| en.wikipedia.org (or your language's Wikipedia), www.bing.com, html.duckduckgo.com | Answers for "look up ..." and "research this", Wiki Race, and finding videos and games |
| www.google.com/s2/favicons, github.githubassets.com, and each Speed Dial site | Little site icons for Speed Dial and the sidebar |
| api.nuget.org | Microsoft's WebView2 package, downloaded once only if you set up video playback |

Some games you open from the Games page fetch from graphql.anilist.co, en.wikipedia.org and www.gamerpower.com.

### Browser addons are pinned

Browser addons hold only text, pages and lists, and the mod only uses them if they are **exactly** the ones this version shipped with:

- Everything is fetched from one commit, never from `main`.
- The mod carries the SHA-256 of every file, and throws away anything that doesn't match.
- There are no automatic updates. **Update all** only installs the files this version is pinned to; new or changed files come with a new version of the mod.
- Games run under a strict Content Security Policy (their own scripts, pictures, and only the APIs listed above). The typing race never gets text from your pages.
- The settings and Welcome styles are only used if they contain no urls, escapes, imports or anything else that can load something.

## Saved on your PC

- Like any browser, it keeps its own profile in Capri's data folder: **cookies, sign-ins and passwords you choose to save**, history, bookmarks and settings. Nothing in it is sent anywhere by the mod. Private tabs keep nothing.
- No telemetry and no API keys inside.
