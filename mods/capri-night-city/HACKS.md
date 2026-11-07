# Capri custom programs — Night City 1.9.3

Say **“night city hacks”** or **“list your hacks”** for the spoken catalogue.

| Program / command | Mechanics | Stealth mode |
|---|---|---|
| **Ghost Veil** | Memory Wipe + blindness; owned effects tracked for up to 8 seconds. | Allowed |
| **Marionette Lock** | Stun + blindness + weapon malfunction, up to 6 seconds. | Allowed |
| **Dead Channel** | Memory Wipe + weapon malfunction, up to 8 seconds. | Allowed |
| **Neural Siphon** | Electrical effect + a 20% target-health damage request; +25 raw HP to V, capped by the game's maximum health. | Blocked |
| **Furnace Lock** | Overheat + stun + a 30% target-health damage request, with effects tracked up to 6 seconds. | Blocked |
| **Circuit Breaker** | Electrical effect + weapon malfunction + a 35% target-health damage request. | Blocked |
| **Crash Loop** | Electrical effect + weapon malfunction; three 12% target-health damage requests at 0, 2 and 4 seconds. | Blocked |
| **Reaper Thread** | Stun, then a native lethal request after 3 seconds if the target remains eligible. | Blocked |

These are scripted combinations and timed mechanics built on existing game effects, without extra assets or new frameworks. Native effects can expire or be rejected by the engine; their own damage can add to the explicitly scripted damage amounts. An upload acknowledgement confirms submission, not a death or complete execution of every delayed step. Quiet programs use control effects; normal AI can still notice them. “Stealth mode allowed” does not guarantee zero alert.

Examples:

- “Ghost Veil.” Selects the nearest eligible NPC, including through walls.
- “Capri, use Ghost Veil on those three armed guards in front of me.” Selects up to three eligible NPCs in the forward cone.
- “Put him in a crash loop.” / “Crash Loop on him.”
- “Drain his health.” / “Neural Siphon on that guy.”
- “Fry his circuits.” / “Circuit Breaker on him.”
- “Sever their comms.” / “Dead Channel on those guards.”
- “Reaper Thread on the guy in front of me.” Uses the aimed NPC.

These eight programs target NPCs; vehicle/device/access-point commands retain their own existing abilities. A named NPC program aimed at a vehicle/device is refused by the bridge. Bare names and ordinary person references use nearest-NPC targeting; singular “in front of me” pins aim, and groups use nearby/forward-cone selection. Up to five eligible targets can receive one group program under one shared eight-second cooldown. Siphon can request 25 HP per successfully uploaded target in a group; healing never intentionally exceeds the game's maximum. It is not resurrection.

Open-ended smart/assist/chaos/control requests can choose the new programs from their appropriate availability pools. Defensive choices remain control-only; machine selections prefer electrical/control programs. Chaos may choose Reaper Thread. Generic “kill him” keeps the existing immediate lethal choices. Explicit names always select the requested program rather than a random substitute. Natural phrasing remains a bounded intent grammar, not unrestricted language-model interpretation.

Each combo checks all required records and existing effects before applying anything. If a later component is rejected, only components newly applied by that attempt are rolled back; already-active effects from other hacks are not claimed or removed. Successful groups share the normal cooldown. Timed pulses/executions retain only EntityIDs, recheck range/protection/session, and are cancelled by menus, disconnect, session changes, stand down, or shutdown. Going into stealth cancels queued damaging programs through mode cleanup.

The existing 35-metre default range, through-wall eligibility, target protections, continuous neutral/civilian scanning, 1.5-second protective cadence, silent netrunner defense, and quieter brain-written reporting remain in place. Live gameplay and interactions with the installed mod set still need verification after restarting Cyberpunk and reapproving Capri Night City.
