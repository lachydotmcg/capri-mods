# Real Music Check

Capri dances whenever a music app says something is playing, so a podcast in Spotify sets her off too, while a song you play from an MP3 or MP4 file often doesn't count at all. Real Music Check makes her wait for real music, wherever it plays.

It checks two ways:

- **A local AI music classifier, if you run one.** It asks an address on your own PC (by default `http://127.0.0.1:8765/music`) for `{"music": true}` or `{"music": false}`, in the background about once a second, so her dancing never waits on it. Anything that answers like that works, for example a small YAMNet sound classifier listening to your speakers.
- **Otherwise, a steady beat.** It runs a second copy of Capri's own beat tracker, and she only dances once a song holds a steady beat. Music locks on after about 8 seconds; talking doesn't hold a beat.

It checks whenever something is playing: a music app, any player Windows knows about (Media Player, VLC, Films & TV, a video in your browser), or a file player like MPC-HC, PotPlayer or mpv while your speakers have sound. So an MP4 music video gets her dancing, and a video essay doesn't. The rest of the time it isn't listening.

**Options:** use the classifier on/off · classifier address · also check audio files and videos in any player on/off · use the beat check on/off · how long to wait for the classifier

- Kind: code mod
- Made by: Quaisar_THM
- Needs: Capri with mod API 3 (0.8.7 or newer), Windows

### Why the mod check flags it
- **Uses the network**: only to ask the music classifier address you set (`http://127.0.0.1:8765/music` by default, which is this PC) whether music is playing. With none running nothing answers, and it uses the beat check instead.

It only talks to the classifier address you set, which is this PC by default (`127.0.0.1`), and only to ask whether music is playing. No keys, nothing sent anywhere else.
