# Capri command cheat sheet

Complete command-family and alias reference for Night City 1.9.3. Braces denote placeholders; say the substituted words, not the braces.

**Quick use:** `protect me` · `scan` · `netrunner defense on` · `night city hacks` · `stand down`

## Custom programs

| Command / aliases | Templates / natural forms | Action |
|---|---|---|
| **Ghost Veil**<br>`ghost veil` | `ghost veil {custom subject}`<br>`use ghost veil on {custom subject}`<br>`cast ghost veil against {custom subject}` | Memory wipe + blindness; up to 8 seconds. Allowed in stealth. |
| **Marionette Lock**<br>`marionette lock` | `marionette lock {custom subject}`<br>`use marionette lock on {custom subject}`<br>`cast marionette lock against {custom subject}` | Stun + blindness + weapon jam; up to 6 seconds. Allowed in stealth. |
| **Dead Channel**<br>`dead channel` | `dead channel {custom subject}`<br>`use dead channel on {custom subject}`<br>`cast dead channel against {custom subject}`<br>`sever {simple possessive} comms` | Memory wipe + weapon jam; up to 8 seconds. Allowed in stealth. |
| **Neural Siphon**<br>`neural siphon` | `neural siphon {custom subject}`<br>`use neural siphon on {custom subject}`<br>`cast neural siphon against {custom subject}`<br>`drain {simple possessive} health`<br>`siphon {simple possessive} health` | Electrical effect +20% target-health damage request; +25 raw HP to V, capped by maximum. Blocked in stealth. |
| **Furnace Lock**<br>`furnace lock` | `furnace lock {custom subject}`<br>`use furnace lock on {custom subject}`<br>`cast furnace lock against {custom subject}` | Overheat + stun +30% target-health damage request. Blocked in stealth. |
| **Circuit Breaker**<br>`circuit breaker` | `circuit breaker {custom subject}`<br>`use circuit breaker on {custom subject}`<br>`cast circuit breaker against {custom subject}`<br>`fry {simple possessive} circuits` | Electrical effect + weapon jam +35% target-health damage request. Blocked in stealth. |
| **Crash Loop**<br>`crash loop` | `crash loop {custom subject}`<br>`use crash loop on {custom subject}`<br>`cast crash loop against {custom subject}`<br>`put {crash subject} in a crash loop`<br>`put {crash subject} into the crash loop`<br>`trap {crash subject} in a crash loop`<br>`trap {crash subject} into the crash loop` | Electrical effect + weapon jam; three 12% damage pulses at 0, 2 and 4 seconds. Blocked in stealth. |
| **Reaper Thread**<br>`reaper thread` | `reaper thread {custom subject}`<br>`use reaper thread on {custom subject}`<br>`cast reaper thread against {custom subject}` | Stun, then a guarded lethal request at 3 seconds. Blocked in stealth. Generic kill commands remain immediate. |

## Standard hacks

| Command / aliases | Templates / natural forms | Action |
|---|---|---|
| **Ghost Spike**<br>`ghost spike`<br>`short circuit` | `attack {target}`<br>`zap {target}`<br>`short circuit {target}` | Electrical effect + 40% target-health damage request. Bare name uses aim. |
| **Neural Burn**<br>`neural burn`<br>`burn target` | — | Overheat + 25% target-health damage request. Uses aim. |
| **Puppet Lock**<br>`puppet lock`<br>`freeze target` | `stun {target}`<br>`freeze {target}`<br>`immobilize {target}` | Stuns an NPC for up to 4 seconds. Person/default selection is nearest NPC. |
| **Optics Blackout**<br>`optics blackout`<br>`reboot optics` | `blind {target}`<br>`dazzle {target}`<br>`reboot {possessive} optics` | Blinds an NPC for up to 6 seconds. |
| **Weapon Jam**<br>`weapon jam`<br>`weapon glitch` | `jam {target}`<br>`jam {possessive} gun`<br>`jam {possessive} weapon`<br>`disable {possessive} gun`<br>`disable {possessive} weapon` | Weapon malfunction for up to 6 seconds. |
| **System Collapse**<br>`system collapse` | `knock out {target}`<br>`shut down {target}`<br>`knock {target} out` | Native collapse effect, tracked up to 8 seconds. |
| **Signal Erase**<br>`erase target`<br>`kill target` | — | Immediate native lethal request against the aimed NPC. |
| **Blackwall Breach**<br>`blackwall breach`<br>`open the blackwall` | — | Aimed NPC: Blackwall upload, guarded lethal follow-up after 5 seconds. Separate 180-second cooldown. |
| **Memory Wipe**<br>`memory wipe` | — | Native memory wipe, tracked up to 8 seconds. Bare command uses aim. |

## Natural commands

| Command / aliases | Templates / natural forms | Action |
|---|---|---|
| **Immediate lethal intent**<br>— | `kill {target}`<br>`flatline {target}`<br>`zero {target}`<br>`ice {target}`<br>`waste {target}`<br>`eliminate {target}`<br>`finish off {target}`<br>`take out {target}`<br>`take {target} out`<br>`wipe out {people}` | Chooses an immediate lethal hack, with rare Blackwall when available. Ordinary person requests choose the nearest eligible NPC. |
| **Let Capri choose**<br>`do your thing`<br>`pick a hack`<br>`choose a hack`<br>`use whatever hack you want` | `hack {target}`<br>`deal with {target}`<br>`handle {target}`<br>`mess with {target}`<br>`use {hack choice} hack on {target}`<br>`pick {hack choice} hack for {target}`<br>`choose {hack choice} hack on {target}` | Chooses an available hack for the target/health context, including appropriate custom programs. |
| **Disable / control**<br>— | `disable {target}`<br>`distract {target}`<br>`stop {target}` | Chooses a control program, such as blind, jam, stun or an appropriate custom control combo. |

## Vehicles and devices

| Command / aliases | Templates / natural forms | Action |
|---|---|---|
| **Explode / destroy**<br>— | `blow up {target}`<br>`explode {target}`<br>`destroy {target}`<br>`blow {target} up` | Vehicle: native explosion request followed by a destroyed-state check. NPC: lethal intent. Device: advertised overload/explosion action. |
| **Accelerate vehicle**<br>— | `accelerate {target}`<br>`floor {target}`<br>`floor it in {target}` | Native vehicle acceleration, released after 4 seconds. |
| **Brake vehicle**<br>— | `brake {vehicle}`<br>`stop {vehicle}` | Native vehicle brake hack, released after 4 seconds. |
| **Breach access point**<br>— | `hack {access point}`<br>`breach {access point}`<br>`crack {access point}` | Native NPC breach of the connected network. Does not fabricate minigame loot. |
| **Device off**<br>— | `turn off {device}`<br>`disable {device}` | Uses the device's exposed toggle/disable/shutdown action. |
| **Device distraction**<br>— | `distract with {target}`<br>`distract using {target}` | Uses an exposed distraction or malfunction action. |
| **Open**<br>— | `open {target}` | Uses an exposed open/toggle action, for example a compatible door. |

## Modes and scanning

| Command / aliases | Templates / natural forms | Action |
|---|---|---|
| **Combat assistance on**<br>`cover me`<br>`night city assist` | — | Periodic adaptive hacks against hostiles while V is in combat. Default opportunity interval: 18 seconds. |
| **Stand down / all stop**<br>`stand down`<br>`night city stand down` | — | Turns off assistance, chaos, protection, stealth, scans, emergency rescue and counterhacks. Cancels owned pending programs. |
| **Chaos on**<br>`chaos mode on`<br>`enable chaos mode`<br>`turn on chaos mode`<br>`go crazy`<br>`do whatever you want` | — | Picks nearby NPCs, vehicles and devices, including neutrals. Default opportunity interval: 10 seconds. Turns protection off. |
| **Chaos off**<br>`chaos mode off`<br>`disable chaos mode`<br>`turn off chaos mode`<br>`stop chaos`<br>`calm down` | — | Stops chaos and cancels owned transient/pending effects. Other mode flags retain their current settings. |
| **Continuous scan on**<br>`scan`<br>`scan around me`<br>`scan for threats`<br>`scan enemies`<br>`scan for enemies`<br>`scan the area`<br>`reveal enemies`<br>`highlight enemies` | — | Continuously tags eligible enemies, neutrals, friendlies and civilian NPCs through walls; refreshes each second. |
| **Scan off**<br>`stop scanning`<br>`scan off`<br>`clear highlights` | — | Clears owned tags and disables manual/protection scanning. Defensive hacks can keep running. |
| **Protect Me on**<br>`protect me`<br>`watch my back`<br>`cover my back`<br>`bodyguard mode on` | — | Turns off chaos/ordinary assistance. Tags NPCs and attempts a control hack every 1.5 seconds while threatened, spreading hacks across hostiles. |
| **Protection off**<br>`stop protecting me`<br>`protection off`<br>`bodyguard mode off` | — | Stops protection. A separately enabled manual scan remains on. |
| **Stealth on**<br>`stealth mode`<br>`stealth mode on`<br>`go quiet`<br>`keep it quiet` | — | Turns off chaos/protection/ordinary assistance. Uses memory wipe in combat, blocks ordinary damaging/lethal commands and suspends emergency rescue. |
| **Stealth off**<br>`stealth mode off`<br>`go loud` | — | Exits stealth; emergency rescue can resume if armed. Does not automatically re-enable other disabled modes. |
| **Emergency rescue on**<br>`emergency on`<br>`emergency rescue on`<br>`save me automatically` | — | Below 50 raw HP: up to 5 nearby hostile lethal requests +100 raw HP, capped at maximum. 120-second persistent cooldown. Suspended in stealth. |
| **Emergency rescue off**<br>`emergency off`<br>`emergency rescue off` | — | Disarms the automatic low-health rescue. |
| **Netrunner defense on**<br>`netrunner defense on`<br>`counterhack on`<br>`anti netrunner on` | — | Retaliates against the actual incoming hacker/tracer, including through walls. Silent body-drop design; corpse remains discoverable. Independent of manual cooldown. |
| **Netrunner defense off**<br>`netrunner defense off`<br>`counterhack off`<br>`anti netrunner off` | — | Disarms incoming-netrunner retaliation. |

## Help and reporting

| Command / aliases | Templates / natural forms | Action |
|---|---|---|
| **Command help**<br>`night city help` | — | Speaks the brief command help. |
| **Custom hack catalogue**<br>`night city hacks`<br>`custom hacks`<br>`list your hacks`<br>`what hacks do you have` | — | Speaks the list of eight custom programs and their effects. |
| **Status**<br>`night city status` | — | Reports link, health, modes, cooldown and crosshair target. |
| **Dashboard**<br>`night city dashboard` | — | Opens the Night City link/status window. |
| **Choose bridge folder**<br>`night city connect` | — | Opens a folder picker for the game's CapriNightCityBridge folder. |
| **Mute game reactions**<br>`night city quiet` | — | Mutes automatic event commentary. Assistance and command acknowledgements remain separate. |
| **Enable game reactions**<br>`night city reactions` | — | Re-enables important automatic event commentary. |

## Targeting

- Nearest NPC: kill him / flatline him / blind him / named custom programs. Neutral and civilian adult NPCs can be selected manually; protection/ordinary assistance attack hostiles only.
- Aim: add a supported noun phrase such as the guy in front of me; singular front/aim/crosshair requests pin aim. Bare Ghost Spike, Neural Burn, Signal Erase, Memory Wipe and Blackwall commands use aim.
- Groups: use two/both, three, four, five, a digit 1–9, all, them, guys, guards, enemies, NPCs, people, cars, vehicles or targets. Maximum is five; digits 6–9 are capped at five. Whole two-digit numbers and spelled-out numbers above five are not a supported count syntax.
- Group + in front / aiming / looking at / crosshair uses a forward cone. A group without those words uses nearby targets. Example: Ghost Veil on those three guards in front of me.
- Vehicles/devices normally use aim; explicit plural cars/vehicles chooses vehicles for a batch. The eight custom programs are NPC-only. Ordinary hacks default to 35 metres and ignore walls for discovered/loaded targets.
- Standard hack effect descriptions refer to NPCs. Compatible vehicle/device targets use their target-specific actions instead, such as braking for control or an exposed device overload for damage. Signal Erase, Thermal Shutdown and Neural Execution are the immediate lethal choices; the latter two have no dedicated spoken keyword.
- Keyword wording matters: kill target is the aimed Signal Erase alias; kill the guy chooses nearest NPC. Attack them is electrical; attack those guards goes through the broader adaptive group grammar.

## Template vocabulary

- {target}: him, her, them, it, that, this; or an optional the/that/this followed by guy, man, woman, enemy, target, gonk, dude, person, guard, one, NPC, car, vehicle, bike, motorcycle, truck, van, camera, turret, device, door, access point, terminal, vending machine, barrel, generator, robot, drone, computer or screen.
- Noun targets can add in front / in front of me / I'm looking at / I am looking at / I'm aiming at / I am aiming at / under my crosshair / over there. Use the guy in front of me for reliable singular aim routing.
- {possessive}: his, her, their, the guy's, that guy's. {simple possessive}: his, her, their. {hack choice}: empty, a, the best, a random; use/pick/choose all support on or for.
- {vehicle}: car, vehicle, bike, truck or van, optionally prefixed by the/that/this. {device}: camera, turret, device or screen with the same optional prefixes. {access point}: access point with the same prefixes, optionally followed by in front of me.
- {custom subject}: him, her, them, that, this; or an optional the/that/this/those/these/all/both/two/three/four/five/digit followed by up to three descriptive words and guy/guys/guard/guards/enemy/enemies/gonk/gonks/NPC/NPCs/target/targets/person/people. Optional noun suffix: in front / in front of me / around me / nearby / over there / behind the wall. A custom NPC program naming a vehicle/device routes to a native refusal.
- Every custom name works alone or with optional use/cast/run/upload/trigger/activate, optional a/the, then an optional subject introduced by on/against or directly: Ghost Veil him. {crash subject}: him, her, them, that guy, those guards. The crash-loop phrase supports put/trap, in/into and optional a/the.
- Broader people/group grammar accepts flatline, kill, zero, ice, waste, eliminate, wipe out, take out, blind, stun, freeze, jam, hack, mess with, deal with, attack, blow up followed by a description containing him/her/them/guy/guys/enemy/enemies/gonk/gonks/guard/guards/NPC/NPCs/people/everyone/car/cars/vehicles/targets/dude/dudes. Described attack groups become adaptive smart hacks; use the named hack for an exact effect.

## Phrasing and voice

- Night City ignores capitalization, commas, periods and common terminal punctuation. Optional address: Capri / hey Capri / hey. It accepts common leading please / just, can/could/would/will you, I need/want you to, and trailing please / now / right now / for me. Example: Capri, could you please blind those three guards now?
- Use one intent per command. Custom and broader group phrases reject their recognized markers: don't / do not / never / not / and / then / but / unless / if / why / how / should. Unmatched speech may go to Capri's ordinary conversation; this is a bounded parser rather than unrestricted language interpretation.
- Typed/local-brain voice requests use the mod dispatcher. The separate ElevenLabs agent voice route may not dispatch keyword commands.

## Modes, timing and activation

- Manual ordinary/group hacks: shared 8-second cooldown. Blackwall: 180 seconds. Protect Me: independent 1.5-second opportunities. Combat assistance: 18 seconds by current settings. Chaos: 10-second default. Scan: 1-second refresh, stays on until stopped.
- Emergency rescue: triggers strictly below 50 raw HP; requests up to five hostile eliminations and +100 raw HP, with a persistent 120-second cooldown. It starts armed each session unless configured otherwise. Netrunner defense likewise defaults on. Stand down disarms both; rearm them explicitly when wanted.
- Protect Me triggers in combat, below 45% HP, or after a recent health drop. Mode priority is stealth, protection, chaos, then ordinary assistance; use go loud before switching from stealth to protection/chaos. Turning one mode off does not necessarily turn another on.
- Stealth permits blind/jam/stun, memory wipe, Ghost Veil, Marionette Lock and Dead Channel plus compatible non-damaging vehicle/device commands. Damaging/lethal custom programs and automatic rescue are suspended. Explicit silent netrunner retaliation can remain armed.
- Native game restrictions/target protections and device action availability still apply. Upload acknowledgement is not confirmed death/destruction. Timed damage/executions are cancelled by menus, disconnection, session changes, stand down and shutdown. Native effects may expire earlier than the bridge's maximum tracking duration.
- After updates, launch/restart Cyberpunk and approve/enable Capri Night City in Capri > Mods. For a failed command, try night city status, then typing the command. Live gameplay and voice behavior are not certified by parser/mock checks.

## Optional in-game controls

- CET > Bindings > Inputs: Capri Night City: Ghost Spike is a bindable pressed-input action; it casts on the crosshair target.
- CET overlay > Capri Night City: Toggle assistance and Toggle chaos mode are UI controls, not additional spoken aliases.
