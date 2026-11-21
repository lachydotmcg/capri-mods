# Capri Voice Hub Ultimate

Deutsche Sprachbefehle für Spotify, YouTube, Apps und Spiele: direkt in Capris Call Mode, mit Zustandsprüfung und ohne zusätzlichen Python-Setup.

- Kind: code mod
- Made by: jeanvd-gif

Version 3.5.0 für Windows. Autor des eigenen Mod-Codes: Jean. Lizenz: MIT, Copyright (c) 2026 Jean.

Installation: Die einzelne capri-voice-hub.capri-code über Mainframe > Mods > Import mod importieren, Codefreigabe prüfen und einschalten. Capris Mikrofon, eine deutsche Spracherkennung und Call Mode einschalten. In den Mod-Optionen Sprachbefehle aktiv, Befehle ohne Capri/Hey Capri und Befehle ohne Namenswort im Call Mode ausführen aktivieren.

Beispiele: „Liedwiedergabe starten“, „Pausiere die Musik“, „Video fortsetzen“, „Video stoppen“, „Öffne Rechner“, „Mach Discord zu“, „Starte [Name aus der App-Liste]“. Medien zuerst in der jeweiligen Anwendung auswählen. Auch Textbefehle in Capri werden verarbeitet. Der Parser akzeptiert ganze Befehle, lehnt Negationen und zusätzliche unbekannte Sätze ab und fragt bei mehrdeutigen App-Namen nach. Keine Ausführung von LLM-generiertem Code.

WICHTIG: Namenlose Call-Mode-Befehle funktionieren nur mit dem exakt geprüften Capri-Windows-Store-Build 1.9. Native call-mode routing uses a private, strictly version-pinned in-process adapter, not a supported public API. Unsupported builds are rejected without patching Capri files. Required assembly: Capri 0.9.0.0; MVID 4EAA900C-8347-4EB2-A8E3-7A64751E5F44; executable SHA-256 C10BEA0E083249DFC9D73E24533A57EE533E55D4FE61AB12E691C6EB9B984207. Public hooks require Mod API 3. Mac/Linux are not supported by this mod.

Python, Whisper, CUDA, Ollama, API-Schlüssel und andere Mods sind für diese nativen Befehle nicht nötig. Capris bereits eingerichtete Spracherkennung bleibt Voraussetzung. Ein optionaler, separat bereitzustellender Companion kann lokale Whisper-Erkennung und ein Statusfenster ergänzen. Die Mod lädt ihn nicht herunter. Ist er bereits ab Version 3.5 installiert, startet und stoppt sie die eigene Instanz zusammen mit Capri; fremde Dienste bleiben unberührt.

PC-Zugriffe: erkannte Befehle, Medienzustand, relevante Fenstertitel, Prozessidentitäten, Startmenü-/App-Einträge sowie Registry- und Steam-/GOG-Installationsangaben. Die Mod startet erkannte Apps, steuert Medien und sendet reguläre Fensteraktionen. Eigene Optionen, Aliase und kurzlebige lokale Brückendateien liegen im Mod-Datenordner. Berechtigungen: chat, music, voice; wie jede Code-Mod besitzt sie dennoch volle Prozessrechte. Keine eigene Audioaufnahme, kein eigener Telemetrie-Server, keine Änderung geschützter Capri-Dateien und kein Zwangs-Kill. Capris eigene Sprach-/KI-Dienste behalten ihre Datenverarbeitung.

YouTube muss bereits geöffnet sein und einen eindeutig passenden Windows-Medientitel und Fenstertitel liefern. Der Video-Tab muss ausgewählt bleiben; minimierte Fenster sind möglich. Die Zuordnung prüft Titel, nicht URL oder Tab-ID. Mehrdeutigkeit wird abgewiesen; kein Ausweichen auf Spotify. Spiele benötigen einen geprüften Katalogeintrag; nicht alle Launcher werden unterstützt.

Geprüft: 619 C#-Befehlsprüfungen, 42 Adapter-, 47 Lifecycle- und 60 Katalogprüfungen. YouTube-Start/Stopp wurde auf dem genannten Build tatsächlich per Sprache im Call Mode bestätigt; Spotify-/YouTube-Zieltrennung und Rechner-Start/Stopp zusätzlich per Text. Spiele nur lesend katalogisiert, nicht live gestartet. Keine Zusage für jede Formulierung oder jedes Spiel.

Capri-Projekt und Mod-API: https://github.com/lachydotmcg/capri-desktop
Capris eigene Ressourcen behalten ihre Lizenz: https://github.com/lachydotmcg/capri-desktop/blob/main/LICENSE.md

MIT License (own mod code)
Copyright (c) 2026 Jean

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
