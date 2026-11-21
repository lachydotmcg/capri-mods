# Capri Browser

A full web browser built into Capri. Capri can see the page you're on and use it with you: she opens sites, finds videos, controls playback, summarises pages and reads them out loud.

- Kind: code mod
- Version: 2.0.0
- Made by: tob7as
- Needs: **Capri 0.9.4 or newer** on **Windows 10 or 11** (about 997 KB of readable code, under the 1 MiB code mod limit). It uses Microsoft Edge's WebView2 engine, which comes with both
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
| "add to my notes ..." / "note this down" / "write that down" | Puts what you said in a new Browser note (nothing said: the page you're on) |
| "research ..." / "look into ..." / "dig into this" | Capri Research: searches and reads several sites in hidden views of the browser (not in your tabs or history) while you carry on, then asks to bring it up, put it in your notes, or both |
| "what's the best ..." / "what's the best website for ..." | Her top picks with prices and sources, or the best sites for it |
| "fact check ..." / "is it true that ..." | True, false, partly true or not clear, with sources |
| "compare my tabs" / "which of these should I buy?" / "what have I got open?" | Compares or sums up your open tabs |
| "work out my last note" / "work out my School notes" / "... my open notes" (or right-click a note > Work on this) | Works out that note in Noted, even a screenshot (Windows reads the text in it) or a text file |
| "watch this page" / "tell me when the price drops" | Checks up to 5 pages every 20 minutes and tells you when it happens |
| "any new changes on my page?" | Checks the pages she is watching right now, asks which one if there are several, and tells you what is new on your yes |
| "find me a YouTube logo" / "find me an anime pfp" | Picture results on Bing Images, with strict safe search |
| "fill in this form with ..." | Fills in what you told her (never passwords, card, bank or ID numbers), outlines it, and sends only on your yes |
| Highlight text, right-click, Let Capri research this | Researches what you highlighted. The right-click menu is in Capri's colours (Settings > Appearance) |
| "screenshot this and add it to my notes" | Puts a screenshot of the page in a new Browser note |
| "pause" / "louder" / "next video" | Controls the video |
| "skip 2 minutes" / "go back 30 seconds" / "skip to 3:20" | Skips or rewinds the video |
| "skip the ad" / "skip intro" | Presses the Skip button with the mouse, if one is showing |
| "go back to the last video" | Opens the video you watched before this one |
| "screenshot this" | Asks which part: the whole page, what's on screen, or a bit you drag over |
| "screenshot the video" / "screenshot the comments" | Finds that part of the page and snaps just it |
| "bookmark this" / "open my bookmarks" | Bookmarks the page / opens Bookmarks |
| "reopen that tab" | Brings back the last tab you closed (Ctrl+Shift+T, or Recently closed in the menu) |
| "summarise this page and add it to my notes" | Says the summary and saves it with the page's name, link and date |
| "find the price and put it in my Shopping notes" / "add milk to my Shopping notes" | Saves it in that notebook |
| "what did I miss?" | Sums up what changed on the tab since you last looked |
| "remind me about this tonight" / "remind me in 2 hours about this" | Brings the page back then |
| "what's 20% of 85" / "what time is it in Tokyo" / "5 km in miles" | Answers straight away, no tab |
| "open custom jobs" | Opens your Custom jobs |
| Your own job's words, like "movie night" | Runs your Custom job |
| "make a job called movie night: open youtube.com, full screen" | Makes a Custom job (she checks it with you first) |
| "what jobs do I have?", "delete my movie night job" | Lists or deletes your jobs (deleting asks first) |
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

**Read new Discord messages** (off until you turn it on) keeps Discord open in a hidden tab, tells you who messaged you directly, and reads the message out loud on your yes.

Most of these also work in Capri Browser's 22 other languages (Spanish, French, German, Japanese, Korean and more).

## Ad blocker

- Blocks ad servers and trackers from **EasyList** and **EasyPrivacy** (free lists, from easylist.to) and Peter Lowe's ad server list, and hides ad boxes on pages.
- Takes away invisible layers that open an ad wherever you click, and stops pop-ups and redirects to other sites from clicks on nothing.
- Puts a red outline and a warning on fake Download buttons that go to ad sites.
- Warns you about "your PC is infected, call this number" scam pages and offers to close them.
- Click the shield for **Privacy Protection**: ads, trackers and pop-ups stopped on the page, **Turn off for this site** for ads and for trackers, and the list of blocked trackers.
- The lists come from Browser addons as `data/adblock.txt` (about 3 MB), kept as a file in the mod's folder. It keeps EasyList's licence (CC BY-SA 3.0 and GPLv3).

## Custom jobs

Make your own commands from the sidebar's Custom jobs button (or say "open custom jobs", or "make a job called movie night: open youtube.com, full screen"): **what you say** in quotes (a few ways with /, like "movie night / film time"), an optional **link** to open first, and **steps**, one a line, in whatever words you like. Any of her voice commands works as a step, and a step she doesn't know goes to her AI, which works out what you meant. A few to try:

- **summarise**, **check the comments**, **look at the prices**: she reads the page (or just that part) and tells you what it means, while a scan line in her colours sweeps the page.
- **ask Ready?**: the job waits for your yes ("no" stops it). **wait 2 minutes** or **wait for it to load** pause it, and Esc stops it any time.
- **✦ Capri learn** (a button on each job): her AI learns your job, fixes the spelling and rewords each step so she can do it, then you check it and Save.
- **Thinking card**: while she runs a job or finds something, a CAPRI // THINKING card over the page shows what she's on and how far through the job she is.
- A job with a site's link (or an `open <site>` step) finds things on that site: "find me a movie" on a movie site searches there, not YouTube.

If she still can't do a step she tells you which, and the job's card says so. Steps are only Capri Browser's own actions: a job can't run code, she never types passwords, and clicks or typing on messaging and social sites still wait for your yes. Capri learn and steps she doesn't know send only the job's words to her brain, and reading steps send the page text, like "summarise" always has (never from private tabs).

## Also in it

- **New in 2.0.1:** every game shows on the Games page straight away, and **Daily Word Search** gives everyone the same new puzzle each day (140 themes, a hard one every third day) (keep your streak, copy your time to share). Under the Speed Dial: how many ads, trackers and pop-ups the ad blocker has stopped, and the most popular free games right now. Sketchy downloads (a program from a site she doesn't know, or a file pretending to be a picture or document) wait for your yes. Game mode can switch on by itself when a full-screen game starts. Capri's notifications can all be turned off with one switch, or one by one. You choose which numbers go on the leaderboards, and a new best tells you where it would place. Research can be Short, Mid or Long, and she asks if you want her to keep researching (new sites, without repeating herself). Code Breach and Mystery Choom are retired.
- **Noted**: notes as a chat with yourself. Leave a note in the box at the bottom (Enter sends), paste or attach pictures and files, add the page's link, and make your own Noted chats (Capri only uses yours and asks "Should I add it to Shopping notes?"). Right-click a card to edit, copy, move or delete it.
- **Bookmarks**: the star on the sidebar (Ctrl+Shift+B), with folders, search, drag and drop, and Import from Opera GX, Opera, Chrome, Edge, Brave or Vivaldi (read from their file on your PC only when you press it). The star in the address box bookmarks the page (Ctrl+Shift+D).
- **Extensions**: the puzzle next to Summarise. Add Chrome-style extensions you downloaded yourself (a folder, .zip or .crx), turn them on or off, open their popup or options, or remove them. On a Chrome Web Store page, **Add to Capri Browser** downloads that extension from Google (clients2.google.com) and installs it.
- **Screenshots**: the camera next to the puzzle. Pick an area (Ctrl+Shift+X), what's on screen, or the whole page. Each one is saved in Pictures\Capri Browser, copied, and can go into Noted.
- Smoother: side panels slide, tabs grow in and shrink away, glide into place when moved and pop when picked, a red line glides to the tab you pick, menus fade in
- **Game mode** (bottom of the left sidebar): other tabs snooze, every page uses Edge's low memory level and the engine runs at idle priority, so your game gets the PC. Click it again for normal.
- Split screen: right-click a tab for two tabs side by side, with a bar to drag between them
- Tabs you have not used for 20 minutes snooze to save memory (a setting, on by default), with a moon on them; a click wakes one
- Press Esc any time to stop Capri taking control
- Offer to skip (off until you turn it on): when Skip ad, Skip intro or Skip recap shows up, she asks, and presses it on your yes
- Watch-along (off until you turn it on): she reacts now and then during videos
- Catch-up: coming back to a tab that changed, she tells you what's new, never what she already told you. Her memory keeps only fingerprints, never the words; it deletes itself after a day, and 30 days for pages on your Speed Dial or that she's watching. Ask her to find the same thing again today and you get a new one. Capri Cleaner can clear her day memory or her important memories.
- History by topic and a weekly wrap-up
- Games: Wiki Race (with co-op codes), Guess the Site, Typing Race and Survival, Quiz, and more from Browser addons
- Achievements and browsing stats
- Capri's look: her colours, takeover animation and a hologram while she talks
- Every feature can be turned off in Settings

## What it changes in Capri

- **It replaces two of her tools.** While the mod is on, her `open_app` (for browsers) and `open_website` tools open pages in Capri Browser instead of your normal browser.
- **It adds a `capri_browser` tool** she uses to open, search, read, click, type and scroll. On messaging and social sites (Discord, Gmail, Outlook, WhatsApp, Messenger, Facebook, Instagram, X, Reddit, Telegram, Slack, Teams, LinkedIn, TikTok, Snapchat, Bluesky) a click, typing or Enter **waits for your yes**, so text on a page can't make her send something.
- **It moves your real mouse and presses keys.** Before she clicks, skips, plays or scrolls on a page, the mouse glides to that spot with the takeover animation (Settings > Capri features > Move the real mouse turns this off; the action itself still happens). It only clicks for real to press a Skip button you said yes to, and for full screen on sites that need a real click (it also presses F there).

## What it sends, and where

Every turn, her brain gets a short note about the browser: the **title and address of the tab in front** (when a private tab is in front she gets nothing about it), and the **sites you use most**. Page text only goes to her brain when you ask her about a page, ask what you missed on a tab, or save something from a page to your notes. With Watch-along on, the title of the video you're watching goes to her brain now and then. Your notes, notebooks, Custom jobs and reminders stay on your PC. Private tabs are never read, and they are left out of the tab list she sees.

The mod itself (not the pages you visit) contacts:

| Host | Why |
| --- | --- |
| raw.githubusercontent.com ([tob7as/Browser-addons](https://github.com/tob7as/Browser-addons)) | The ad blocker lists, voice commands in other languages, games, game lists, languages, the settings, Speed Dial, results, Games and History looks, video-site, search-engine and achievement lists, help, the Welcome page and update notes. The Welcome page offers **Download browser** (all at once, with progress) or **Download quietly in the background**; until then the browser uses small built-in English defaults |
| en.wikipedia.org (or your language's Wikipedia), search.brave.com, www.bing.com, html.duckduckgo.com | Answers for "look up ..." and "research this", Wiki Race, finding videos and games, and picture searches |
| www.google.com/s2/favicons, github.githubassets.com, and each Speed Dial site | Little site icons for Speed Dial and the sidebar |
| capri-browser.tobiasprojects77.workers.dev (tob7as's own Cloudflare worker) | Gets the weekly leaderboards and the Featured boxes on the Games page (plain text, shown escaped, and not pinned, since they change without a mod update). Only if you pick a leaderboard name: that name, then your weekly game and browsing counts every 12 hours, and your place when you look it up. And whatever you type into the bug and idea box when you press Send, with the mod version, your Windows version and a random ID. Nothing else; your IP address is never stored (only a salted hash that changes daily, for rate limits), and Featured can be turned off in Settings |
| api.nuget.org | Microsoft's WebView2 package, downloaded once only if you set up video playback |
| clients2.google.com | The extension you press **Add to Capri Browser** on, from its Chrome Web Store page. It isn't pinned, since you pick it |

Some games you open from the Games page fetch from graphql.anilist.co, en.wikipedia.org and www.gamerpower.com. The free games under the Speed Dial come from www.gamerpower.com too, every 6 hours (turn it off in Settings > Appearance). Nothing about you is sent.

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
