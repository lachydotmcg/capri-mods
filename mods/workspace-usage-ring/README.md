# Workspace Usage Ring

A small ring at the top-right of the message box on Capri's Workspace page shows how much of your Claude plan you've used. Click it to see your 5-hour and weekly limits, how full each one is, and when they reset.

- Kind: code mod
- Made by: tob7as
- Needs: Capri 0.9.0 or newer, and Claude Code installed and signed in
- Windows only

There's nothing to say to it. The ring fills up as you use your plan and turns red at 85%. In the popup, press **Refresh** for a new reading.

To get the numbers, it asks Claude Code for a one-word reply on the smallest model (Haiku). It only does this while the Workspace page is open: when the page opens, every 10 minutes after that, and when you open the popup if the last reading is over 2 minutes old. Nothing runs in the background when the Workspace page is closed. Each check uses a tiny bit of your plan. The last reading is saved in the mod's own folder, so the ring shows straight away after Capri restarts.

It runs claude.exe itself (from %USERPROFILE%\.local\bin or your PATH) in its own folder, and finds the Workspace message box inside Capri's own code, so a Capri update can break it until the mod is updated.
