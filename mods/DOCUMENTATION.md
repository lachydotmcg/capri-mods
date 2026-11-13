# Capri Lyrics — documentation technique

Mod autonome pour **Capri Desktop 0.8.9** (Mod API 3), livré sous forme d'un unique fichier
`capri-lyrics.capri-code` (C# 5, Windows). Ce document couvre l'architecture, les formats, les
choix d'intégration à Capri, les tests et les limites.

- Identifiant : `capri-lyrics`
- Version : `1.2.1`
- Auteur : `Suoh`
- Permissions déclarées : `music`, `hotkeys`
- API requise : `api 3`
- Build actuel : 149 746 octets, SHA-256 `80cbf7c6c2f88289af2f34aa56635dd0ae8c559da497bdea5b83242a667f4bf2`

---

## 1. Vue d'ensemble

```
                 ICapriMusic (Windows media session)
                          │  Changed / Now
                          ▼
  ┌──────────────────────────────────────────────────────────┐
  │ LyricsMod                                                │
  │  Tick (80 ms) ──► morceau courant ──► clé de cache       │
  │       │                                  │               │
  │       │                                  ├─ cache disque ─┴─► LyricsWindow
  │       │                                  └─ ThreadPool ──► lrclib / lyrics.ovh
  │       │                                                        │
  │       ├─ WatchMini / FollowCc ──► CcWindow (30×30, à gauche du cœur)
  │       ├─ pose à l'ouverture ──► ICapriBody.MoveTo / Move        │
  │       └─ rien d'autre : le bandeau est un siège que Ledges trouve seul
  │                                                          │
  │  Frame (15 ms) ──► WatchThrow ──► Animate + Redraw ───────┘
  └──────────────────────────────────────────────────────────┘
                          │
                          ▼
                 fenêtres layered (Win32), sous celle de Capri
```

Deux fenêtres :

1. **`LyricsWindow`** — le bandeau (920×224 par défaut, redimensionnable, en-tête 38 px,
  5 lignes autour de la courante, perspective en trapèze, cadre animé, lettres qui glitchent
  quand Capri est lancée).
2. **`CcWindow`** — le bouton `CC` (30×30 + halo 6 px = 42×42), collé au mini-player.

Les deux sont **layered** et toujours au premier plan, puis replacées **juste sous la fenêtre de
Capri** (`Win32.Beneath`), comme son mini-player. Le bandeau n'est **pas** une fenêtre d'outil :
il ne porte ni `WS_EX_TOOLWINDOW` ni `WS_EX_NOACTIVATE`, pour que `Ledges` l'accepte comme siège ;
son propriétaire caché (WinForms, `ShowInTaskbar = false`) le garde hors de la barre des tâches
et d'Alt+Tab, et `WM_MOUSEACTIVATE → MA_NOACTIVATE` l'empêche de voler le focus. Le `CC`, lui,
reste une fenêtre d'outil / never-activate.

---

## 2. Structure du fichier

| Bloc | Rôle |
| --- | --- |
| En-tête `// capri-mod:` | Métadonnées lues par Capri à l'import (id, nom, version, permissions, API). |
| `LyricLine`, `Lyrics` | Modèle : lignes horodatées, statut, source, instrumental, LRC/texte. |
| `Json` | Lecteur JSON minimal (lrclib / lyrics.ovh) : objets plats, chaînes échappées, nombres, booléens. |
| `LyricsParser` | Parseur LRC (horodatages multiples, `[offset:…]`), recherche binaire `IndexAt`, `Fraction`, `EvenLines`, `JoinLrc`. |
| `LyricsSource` | Construction des URL et mapping des réponses des trois sources. |
| `LyricsCache` | Cache JSONL, 500 entrées, réessai des « none » après 3 jours, écriture atomique. |
| `LyricLayout` | Première ligne visible pour une fenêtre de 5 lignes, garde de bornes (`HasLine`). |
| `LyricsPose` | Pose d'ouverture (`sit`, `lie`, `none`) et migration de l'ancien `lyrics.autolie`. |
| `CcGeometry` | Position et taille du bouton `CC` à partir du plateau du mini-player et de son échelle. |
| `Art` | Palette, polices partagées (cache), plaque unie à liseré diagonal animé et équerres HUD, lignes karaoké avec ergots, glitch de lancer (`GlitchText`/`DrawGlyph`, largeurs de glyphes en cache), perspective sans couture (`Tilt`, table précalculée et bitmap réutilisée). |
| `Win32`, `BandForm` | Fenêtres layered, `UpdateLayeredWindow`, `Beneath`, `KeepOnTop`, DPI, hit-test, styles de siège. |
| `LyricsWindow` | Le bandeau : rendu animé, déplacement par l'en-tête, redimensionnement par le coin, clic traversant, position et taille. |
| `CcWindow` | Le bouton `CC` : rendu, clic, suivi du mini-player (`SlideWith`). |
| `MoverWindow` | `NativeWindow` accroché au mini-player (`WM_MOVE`/`WM_WINDOWPOSCHANGED`) pour déplacer le `CC` sans repeindre. |
| `LyricsMod` | `ICapriMod` : cycle de vie, tick, sources, pose, options, commandes vocales. |

Le fichier est **auto-suffisant** : aucune référence hors `System.dll`, `System.Core.dll`,
`System.Drawing.dll`, `System.Windows.Forms.dll`. C'est exactement ce que Capri fournit à son
compilateur CodeDOM.

---

## 3. Contraintes de plateforme

- **C# 5.** Le compilateur de Capri est celui du .NET Framework (`csc v4.0.30319`). Pas
  d'interpolation de chaînes, pas de `?.`, pas de membres à corps d'expression, pas de
  `nameof`, pas de tuples.
- **Windows uniquement.** WinForms, GDI+, `user32`/`gdi32`. Capri refuse le mod sur Mac et Linux
  à l'import.
- **Pas de permission `network` dans l'API 3.** Un code mod tourne déjà avec un accès complet au
  PC ; le mod utilise `System.Net.HttpWebRequest` directement. Il demande donc seulement
  `music` et `hotkeys`. Aucune permission supplémentaire n'est revendiquée à tort.
- **`Ledges` n'a qu'un seul « siège propre » (`OwnSeat`), celui du mini-player.** Le bandeau ne
  l'utilise pas : il se présente comme une fenêtre ordinaire (§ 7.1) et `Ledges.Seatable`/`Showing`
  l'acceptent seuls. Les deux sièges coexistent donc.
- **Une fenêtre layered + `NOACTIVATE` ne passe pas `Ledges.Seatable`.** Le bandeau abandonne ces
  deux styles ; son propriétaire caché et `WM_MOUSEACTIVATE` remplacent ce qu'ils apportaient.

---

## 4. Flux de données

### 4.1 Morceau courant

`ICapriMusic.Changed` signale un changement de morceau ; `ICapriMusic.Now` donne le morceau et
`CapriTrack.At()` la position de lecture. Le mod ne dépend pas de Spotify pour le bandeau : il
affiche ce que la session média de Windows expose. Le **bouton `CC`**, lui, n'apparaît que si
`track.App` ou `track.AppId` contient `spotify` (insensible à la casse).

### 4.2 Clé de morceau

```
key = artist.ToLowerInvariant().Trim() + "|" + title.ToLowerInvariant().Trim() + "|" + round(length)
```

La durée sépare les éditions/remix. Une clé vide (titre vide) met le bandeau en veille.

### 4.3 Recherche

Ordre strict, sur le `ThreadPool` (jamais sur le thread UI) :

1. `GET https://lrclib.net/api/get?artist_name=…&track_name=…&album_name=…&duration=…`
2. `GET https://lrclib.net/api/search?artist_name=…&track_name=…`
3. `GET https://api.lyrics.ovh/v1/{artist}/{title}`

Chaque requête : `User-Agent: CapriLyrics/1.2.1 (Capri Desktop mod)`, `Accept: application/json`,
TLS 1.2 forcé, timeout 7 s, décompression gzip/deflate, lecture UTF-8.

Règles de sélection :

- lrclib `/api/get` : `instrumental` → statut `instrumental` ; sinon `syncedLyrics` (LRC) →
  statut `ok` synchronisé ; sinon `plainLyrics` → texte réparti uniformément, `APPROX.`.
- lrclib `/api/search` : première entrée **synchronisée** valide ; sinon première entrée texte ;
  les instrumentaux sont ignorés.
- lyrics.ovh : texte simple, entités HTML décodées, réparti uniformément.

Un résultat vide ou nul n'est **pas** mis en cache comme succès. Si les trois sources échouent,
le statut `none` est mémorisé et réessayé après **3 jours**. Une erreur réseau donne `error`
(`HORS LIGNE`) sans empoisonner le cache.

### 4.4 Parseur LRC

- Horodatage : `[m:ss]`, `[mm:ss.xx]`, `[mm:ss:xxx]`, minutes jusqu'à 3 chiffres.
- Plusieurs horodatages sur une ligne : la même phrase est dupliquée à chaque temps.
- `[offset:+/-ms]` appliqué à tous les temps, borne à 0.
- Lignes sans horodatage (métadonnées `[ar:…]`, `[ti:…]`) ignorées.
- Tri stable par temps, puis par texte.
- `IndexAt` : binaire, dernière ligne dont le temps est ≤ `t + 1 ms`.
- `Fraction` : progression entre la ligne courante et la suivante (dernière ligne : +4 s),
  bornée 0..1 ; pilote le remplissage karaoké.

Texte simple : lignes non vides, métadonnées `[…]` retirées, réparties sur la durée du morceau
(ou 6 s/ligne si la durée est inconnue).

---

## 5. Cache disque

`%LOCALAPPDATA%\Capri\mods\capri-lyrics-data\lyrics-cache.jsonl`

Un objet JSON par ligne :

```json
{"k":"damso|pa pa paw|216","t":"Pa Pa Paw","a":"Damso","o":"lrclib","i":false,
 "s":"[00:12.34] …","p":"…","d":216.0,"at":1762984077}
```

| Champ | Sens |
| --- | --- |
| `k` | Clé de morceau (§ 4.2). |
| `t`, `a` | Titre et artiste renvoyés par la source. |
| `o` | Source : `lrclib` ou `lyrics.ovh`. |
| `i` | Instrumental. |
| `s` | LRC re-sérialisé (vide si non synchronisé). |
| `p` | Texte simple (repli). |
| `d` | Dernier temps connu des lignes, ou 0. |
| `at` | Date Unix de récupération. |

- **500 entrées maximum**, les plus récentes gardées.
- **Écriture atomique** : fichier `.tmp` puis remplacement.
- **Sauvegarde au plus toutes les 8 s** (`SaveSoon`) pour ne pas marteler le disque.
- Fichier UTF-8 **sans BOM**, lecture tolérante (une ligne corrompue est ignorée).
- Les « none » expirés sont ignorés à la lecture → nouvelle requête.

Le fichier est du JSONL pour survivre à une écriture interrompue sans parseur de tableau.

---

## 6. Interface

### 6.1 Bandeau

| Élément | Valeur (unités 96 DPI) |
| --- | --- |
| Plateau / fenêtre | 920 × 224 par défaut, redimensionnable de 560 × 170 à 1600 × 420 (liseré néon rentré, aucun halo : fenêtre = plaque = siège) |
| En-tête | 38 px |
| Lignes visibles | 5 (la courante ± 2) |
| Ligne courante | `lyrics.size` × 1,3 (16–38 → 20,8–49,4 px), jusqu'à × 1,55 pour remplir la largeur |
| Lignes de contexte | `lyrics.size` × 0,5 |
| Alpha du panneau | 158, RGB (3, 4, 6), **une seule teinte unie** |
| Marge interne | 24 px |
| Barre de progression | rail gradué (16 repères) à 11 px du bas, tête pulsée |
| Perspective | trapèze, bord haut à 96,6 % de la largeur |
| Poignée de redimensionnement | coin inférieur droit, 26 × 26 px, chevrons lumineux |

- **Palette** : plaque quasi noire `rgba(3,4,6,158)`, cyan `#3AD6EB`, rose `#FF2E88`, encre
  `#E8ECF0`, gris `#7A808A`. La fenêtre lit donc **plus noir que bleu**, tout en restant
  translucide. Le remplissage est **plat** : ni reflet, ni dégradé, ni scanlines, ni trait
  d'en-tête — aucune ligne ne traverse le noir.
- **Typographie** : police d'affichage condensée `Bahnschrift SemiBold Condensed` (replis
  `Bahnschrift SemiBold SemiConden`, `Bahnschrift SemiBold`, `Bahnschrift Condensed`,
  `Bahnschrift`), en gras pour la ligne courante, puis `CapriDesktop.Look.Mono` / Consolas pour
  le reste. Rien à installer : Bahnschrift est livré avec Windows 10/11.
- **En-tête** : badge `CC`, **égaliseur à quatre barres** (il danse quand la chanson joue, il
  retombe en veille sinon), titre — artiste, mot d'état (`SYNCHRO`, `APPROX.`, `CHARGEMENT`,
  `INSTRUMENTAL`, `PAS DE PAROLES`, `HORS LIGNE`) et un **losange pilote** qui respire (il s'emballe
  pendant un lancer). Le titre frémit quand Capri vole.
- **Corps** : ligne courante centrée, à 130 % de la taille choisie et agrandie jusqu'à × 1,55
  tant qu'elle tient dans la largeur, avec un remplissage karaoké rose → cyan. Les deux lignes
  précédentes et les deux suivantes restent à 50 %, atténuées. Deux **ergots de signal** (trait +
  losange) suivent les extrémités réelles de la ligne courante, mesurées par `Art.Row`.
- **Entrée de ligne** : la nouvelle ligne arrive légèrement trop grande (× 1,06) et 5 px plus bas,
  puis se pose en **220 ms**.
- **Glitch visuel** : toutes les ~3,4 s (créneau de 110 ms, 2 créneaux sur 31), la ligne courante
  se dédouble en rose/cyan décalés et se déchire en bandes pendant **220 ms**. Aucun son.
- **Cadre vivant** : `Art.Plate` anime un liseré **rose → cyan en diagonale** (respiration
  sinusoïdale à 2,1 rad/s), un **filet intérieur** qui fait office de bezel, **trois équerres HUD**
  (haut-gauche, haut-droit, bas-gauche) avec leur nœud, deux **runners** courts (cyan en haut, rose
  en bas) qui parcourent les bords en sens inverse et portent une **bille de tête**, et des
  **chevrons de redimensionnement** rayonnant dans le coin bas-droit. Rien ne traverse la plaque :
  aucun trait horizontal sur le noir.
- **Progression** : un rail à **16 graduations**, rempli en rose → cyan, avec une **tête pulsée**
  (halo + cœur clair) qui marque la position exacte.
- **Perspective** : l'image finie est déformée en trapèze par `Art.Tilt(bitmap, 0.966f)`,
  **ligne par ligne en pixels** (`LockBits` + `Marshal.Copy`), bord haut conservé à `y = 0` ; le
  bas garde sa largeur. Aucune bande empilée, donc aucune couture visible sur le noir translucide.
- **Clic traversant** : `WM_NCHITTEST` renvoie `HTTRANSPARENT (-1)` partout, sauf dans l'en-tête
  (déplacement) et dans le coin inférieur droit (redimensionnement).
- **Redimensionnement** : glisser le coin bas-droit change la taille logique (`BandSize` borne à
  560×170 – 1600×420), redessine pendant le geste, puis mémorise `lyrics.band` (`w,h`) au
  relâchement. Le bandeau reste ancré en haut à gauche, donc le siège suit son bord haut.
- **Déplacement** : pendant le glissement, `SlideTo` déplace la **dernière image déjà rendue**
  (aucun redessin) ; le rendu complet n'a lieu qu'au relâchement. Le siège de Capri lit les bornes
  réelles de la fenêtre à chaque frame : elle suit le mouvement au lieu de téléporter à la fin.
- **Lancer de Capri** : `WatchThrow` lit le champ privé `thrown` de sa fenêtre par réflexion ; à
  défaut, un corps qui traverse l'écran à plus de 1500 px/s compte comme un lancer. Pendant le
  vol, `Impact` vaut 1 et chaque lettre est dessinée séparément (`GlitchText` / `DrawGlyph`) avec
  décalage, rotation, échelle, saut et fantôme ; après l'atterrissage, l'effet retombe en ~900 ms.
- **Redessin** : une boucle de frame séparée (timer de 15 ms) peint le bandeau tant qu'il est
  ouvert : ~60 fps pendant un lancer, ~30 fps pendant la lecture, ~18 fps au repos. Le tick de
  80 ms ne peint plus ; il ne fait que lire la musique, le `CC` et le siège, puis marquer ce qui a
  changé. Le karaoké est lissé entre deux échantillons par `Playhead()`, donc la progression glisse
  au lieu de sauter cinq fois par seconde. Rien n'est peint quand le bandeau est fermé.
- **Position et taille** : plateau mémorisé dans `lyrics.pos` (`x,y`), taille dans `lyrics.band`
  (`w,h`), bornés à l'écran au relâchement (`Clamp`). Défaut : centré en bas de l'écran principal,
  24 px au-dessus de la zone de travail.
- **DPI** : toute la géométrie est multipliée par l'échelle DPI de la fenêtre
  (`Win32.DpiScale`).
- **Z-order** : `Beneath(fenêtre de Capri)` à chaque redessin et à chaque tick ; si la fenêtre de
  Capri n'est pas connue, `KeepOnTop`.

### 6.2 Bouton `CC`

| Élément | Valeur |
| --- | --- |
| Position logique | `(253, 73)` dans le plateau du mini-player |
| Taille | 30 × 30 |
| Halo | 6 px |
| Fenêtre | 42 × 42 |
| Écart avec le cœur | 6 px |

Le plateau et l'échelle viennent de `CapriDesktop.MiniPlayer` (`Plate`, `ScaleShown`), lus par
réflexion. Le bouton est repeint selon l'état (allumé = paroles ouvertes) et masqué si le
mini-player est absent/invisible ou si le morceau n'est pas Spotify.

Pour un suivi **image par image**, `WatchMini` accroche un `MoverWindow : NativeWindow` à la
fenêtre du mini-player : chaque `WM_MOVE` / `WM_WINDOWPOSCHANGED` (0x0003 / 0x0047) appelle
`CcWindow.SlideWith`, qui ne fait que déplacer la fenêtre déjà peinte (aucun texte redessiné
pendant le glissement). Le tick de 80 ms reste là pour l'échelle, la visibilité et l'apparition
du mini-player. `ReleaseMiniMover` détache le hook à l'arrêt.

### 6.3 Interaction

| Entrée | Effet |
| --- | --- |
| Clic `CC` | `Toggle()` |
| `Ctrl+Alt+L` | `Toggle()` (si le raccourci est libre) |
| Menu **Paroles (CC)** | `Toggle()` |
| Glisser l'en-tête | Déplace le plateau, mémorise `lyrics.pos` |
| Glisser le coin bas-droit | Redimensionne le plateau (560×170 – 1600×420), mémorise `lyrics.band` |
| Jeter Capri | Pendant le vol et ~0,9 s après l'atterrissage, les lettres glitchent puis reviennent |
| « affiche/montre/mets/active/lance/ouvre » + « parole » | `TurnOn` |
| « cache/masque/enlève/retire/coupe » + « parole » | `TurnOff` |

`Heard` n'intercepte que les phrases qui contiennent explicitement « parole » ; tout le reste
est rendu à Capri.

### 6.4 Options (Mainframe → Options → Lyrics)

- **Quand les paroles s'ouvrent** (`lyrics.pose`) : *Capri s'assied dessus* (`sit`, défaut),
  *Capri s'allonge dessus* (`lie`) ou *Capri reste où elle est* (`none`). Changer la pose
  pendant que le bandeau est ouvert la repose 0,3 s plus tard.
- **Taille du texte** 16–38 px (`lyrics.size`, défaut 25), appliquée en direct.
- **Recentrer la fenetre** : replace le plateau au centre bas et enregistre la position.

L'ancienne clé `lyrics.autolie` (booléenne) est migrée une fois : `true` → `lie`, `false` →
`none`, puis supprimée (§ 9).

---

## 7. Intégration aux sièges de Capri

### 7.1 Une vraie fenêtre-siège, sans `OwnSeat`

Le bandeau **ne s'enregistre pas** comme siège. Il se présente comme une fenêtre ordinaire et
`Ledges` le découvre tout seul, exactement comme le mini-player :

- pas de `WS_EX_TOOLWINDOW` (0x80) : `Ledges.Seatable` l'accepte ;
- pas de `WS_EX_NOACTIVATE` (0x08000000) : `Ledges.Showing` ne le rejette plus ;
- `ShowInTaskbar = false` fait de la fenêtre de Capri son propriétaire caché : hors barre des
  tâches, hors Alt+Tab ;
- `WM_MOUSEACTIVATE` renvoie `MA_NOACTIVATE (3)` : cliquer le bandeau ne vole jamais le focus ;
- `Glow = 0` et liseré rentré : la fenêtre fait exactement la taille du plateau (920 × 224 par
  défaut, 560×170 à 1600×420 après redimensionnement), donc ses bornes sont exactement le bord
  visible sur lequel Capri se tient.

Deux sièges coexistent ainsi : celui du mini-player (`OwnSeat`, inchangé) et le bandeau, que
`Ledges` traite comme n'importe quelle fenêtre de l'écran. `OwnSeat` n'est plus appelé par le mod,
et il n'y a donc plus de reprise de siège ni de `ReleaseSeat` dans la boucle.

`Ledges` met en cache la liste des fenêtres pendant **1 seconde**. Le mod appelle
`Ledges.Invalidate()` après un déplacement, une ouverture, une fermeture ou un recentrage, pour
que le rescan voie le bandeau tout de suite.

### 7.2 Pose à l'ouverture

À l'ouverture (`TurnOn`), selon `lyrics.pose` :

- **`sit`** (défaut) : elle s'assied sur le bord haut du bandeau ;
- **`lie`** : elle s'y allonge ;
- **`none`** : le mod ne la touche pas.

Délai : **0,5 s** après une ouverture manuelle, **1,2 s** après une restauration au démarrage.

Séquence :

1. `PlaceOnBand()` : `Her.MoveTo(hip)` avec
   `hip = (plate.Left + plate.Width/2, plate.Top - max(8, 6×DPI))`.
   Elle se « glitche » hors/retour et tombe les derniers pixels sur le bandeau.
2. Attente **1,6 s** (le temps qu'elle atterrisse et prenne le bandeau comme siège).
3. `PoseAttempt` :
   - si `OnBand(plate)` est faux (elle a raté le bandeau), re-`PlaceOnBand` et nouvel essai ;
   - en `sit`, `Her.Move("sit_up")` (sans effet si elle est déjà assise) ;
   - en `lie`, `Her.Move("lie_down")` ; succès si la réponse contient `lying down` **et pas**
     `nothing under`.
4. Journal une seule fois par ouverture :
   `Lyrics: Capri is sitting on the lyrics.` ou
   `Lyrics: Capri is lying on the lyrics.`
5. Jusqu'à **3 tentatives**, espacées de 1,6 s.

`OnBand` reste volontairement tolérant : chevauchement horizontal avec le plateau et bas du corps
à ±4×`slack` du haut du plateau (`slack = max(30, 12×DPI)`). C'est une heuristique de proximité,
pas une vérité physique.

> **Pourquoi la réponse texte et pas `Her.Bounds` ?** En runtime, `Her.Bounds` renvoie la même
> taille (143×280) assise ou allongée. La géométrie ne permet donc pas de distinguer les poses ;
> seule la réponse de `Her.Move("lie_down")` est fiable.

### 7.3 Fermeture

`TurnOff()` :

1. `lyrics.on = false` ;
2. `Her.Move("stand_up")` **uniquement si `OnBand(band.PlateOnScreen)` est vrai**, c'est-à-dire si
   elle est réellement sur le bandeau — sinon elle reste assise sur le mini-player ;
3. masquage du bandeau, puis `Ledges.Invalidate()`.

### 7.4 Suivi, autonomie et hauteur

- **Suivi** : `HoldSeat` de Capri relit les bornes réelles de la fenêtre à chaque frame
  (`Ledges.Showing` → `DwmGetWindowAttribute` / `GetWindowRect`). Quand on glisse le bandeau,
  elle voyage avec son bord, sans téléportation ; le `CC` fait de même avec le mini-player.
- **Autonomie** : elle se lève pour parler, danser ou suivre une idée. Le mod ne la force pas à
  rester ; la pose est une invitation à l'ouverture, pas une contrainte.
- **Hauteur nécessaire** : pour s'asseoir, Capri a besoin de sa hauteur de corps au-dessus du
  bandeau (`Size × (SitY − PerchedRight.Top) ≈ 0,62 × Size`, soit ~174 px pour une Capri de
  280 px). Un bandeau collé en haut de l'écran affiche les paroles, mais elle ne peut pas s'y
  percher ; il faut le descendre d'une centaine de pixels.

---

## 8. Cycle de vie et threading

- `Start(ICapriHost)` : résout la réflexion, lit `lyrics.pose` (avec migration), `lyrics.size` et
  le cache, s'abonne à `Music.Changed`, construit les fenêtres sur le thread UI, ajoute le menu,
  les options et le raccourci, journalise la version, puis restaure l'état (`lyrics.on`).
- `Stop()` : désabonne les événements, retire le raccourci, sauve le cache, arrête les deux timers,
  détache le hook du mini-player (`ReleaseMiniMover`), détruit les fenêtres.
- `Heard(string)` : commandes vocales (§ 6.3).
- **Tick 80 ms** (`System.Windows.Forms.Timer`, thread UI) :
  - récupère un résultat réseau prêt (`pending` protégé par `fetchLock`) ;
  - met le cache à jour et marque le bandeau (`Dirty`) ;
  - accroche le mini-player si besoin (`WatchMini`) et suit sa position (`FollowCc`) ;
  - met à jour la position karaoké ; la peinture est laissée à la boucle de frame.
- **Frame 15 ms** (`System.Windows.Forms.Timer`, thread UI) : ne fait rien si le bandeau est
  fermé. Sinon `WatchThrow()` met à jour `Impact` selon le champ `thrown` (ou la vitesse du corps),
  puis `Animate()` + `Redraw()` peignent une frame si le délai adaptatif est écoulé : 14 ms
  (~60 fps) pendant un lancer, 30 ms (~30 fps) pendant la lecture, 55 ms (~18 fps) au repos. Un
  saut d'`Impact` force la frame immédiatement. Le rythme est mesuré au `Stopwatch`, pas à
  `Environment.TickCount` (dont le pas de 10–16 ms causait justement la saccade).
- Les téléchargements tournent sur le `ThreadPool` ; un **ticket** (`fetchTicket`) annule
  implicitement une réponse devenue obsolète quand le morceau a changé.
- `OnUi(...)` marshale toute manipulation de fenêtre sur le thread UI.
- **Aucune reprise de siège** dans la boucle : le bandeau est un siège ordinaire, découvert par
  `Ledges`, et le mini-player garde son `OwnSeat` en permanence.

---

## 9. Réglages persistés (`store.json`)

| Clé | Type | Défaut | Sens |
| --- | --- | --- | --- |
| `lyrics.on` | booléen | `false` | Paroles ouvertes à la restauration. |
| `lyrics.pos` | `"x,y"` | vide | Coin haut-gauche du plateau (fenêtre = plateau). |
| `lyrics.band` | `"w,h"` | `920,224` | Taille logique du plateau, bornée 560×170 – 1600×420. |
| `lyrics.size` | nombre | `25` | Taille du texte courant, bornée 14–40 au chargement et 16–38 dans l'UI. |
| `lyrics.pose` | `"sit"` / `"lie"` / `"none"` | `sit` | Pose de Capri à l'ouverture. |

Migration depuis 1.0.0 : si `lyrics.pose` est absent et `lyrics.autolie` présent, `true` → `lie`,
`false` → `none`, puis la clé `lyrics.autolie` est **supprimée** du store. Les variantes
françaises (`allongé`, `jamais`, `non`…) sont acceptées à la lecture.

Le store de Capri sérialise tout en chaînes ; `Store.Flag` et `Store.Number` font la conversion.

---

## 10. Points de réflexion

L'API 3 ne couvre pas ces éléments ; le mod les lit par réflexion, avec repli silencieux.

| Cible | Usage | Si absent |
| --- | --- | --- |
| `CapriDesktop.MiniPlayer.Plate` (propriété) | Rectangle du mini-player. | Pas de bouton `CC`. |
| `CapriDesktop.MiniPlayer.ScaleShown` (propriété) | Échelle du mini-player. | Pas de bouton `CC`. |
| Champ privé `player` de la fenêtre de Capri | Retrouver l'instance du mini-player. | Pas de bouton `CC`. |
| Champ privé `thrown` de la fenêtre de Capri | Savoir que Capri est en vol. | Repli : vitesse du corps > 1500 px/s. |
| `CapriDesktop.Ledges.Invalidate()` | Forcer le rescan (déplacement, ouverture, fermeture, recentrage). | La pose peut échouer pendant la seconde de cache. |
| `CapriDesktop.Look.Mono(...)` | Police mono de Capri pour l'en-tête et les replis. | Repli Consolas. |

Le mod n'appelle **plus** `Ledges.OwnSeat` : le bandeau est une fenêtre ordinaire que `Ledges`
découvre seul, et le mini-player conserve son `OwnSeat`. Aucun de ces accès n'est indispensable au
simple affichage des paroles : le bandeau, le cache et les sources fonctionnent sans réflexion.

---

## 11. Tests et vérification

### 11.1 Tests moteur — 122/122

`tests/TestRunner.cs`, exécuté hors de Capri, sans réseau :

- parseur LRC : horodatages, fractions, multi-horodatages, `[offset]`, tri, lignes invalides ;
- `IndexAt` / `Fraction` / `EvenLines` / `JoinLrc` (aller-retour) ;
- garde de bornes `LyricLayout.HasLine` : index `-1` avant le premier horodatage, index hors
  tableau, liste nulle (le crash corrigé en 1.1.0) ;
- lecteur JSON : chaînes échappées, Unicode, nombres, booléens, objets multiples ;
- sources : mapping lrclib get/search, ovh, instrumentaux, entités HTML, sélection ;
- cache : clé, relecture, expiration des `none` à 3 jours, plafond de 500, JSONL tolérant ;
- mise en page : première ligne visible, lignes courtes, bornes ;
- poses : `sit` par défaut, variantes `lie`/`none`, migration `lyrics.autolie`, clé vide ;
- géométrie : bornes par défaut du bandeau 920×224, `CcGeometry` à plusieurs échelles ;
- redimensionnement : défaut conservé, minima/maxima appliqués, demande vide retombant sur
  le défaut ;
- perspective : `Art.Tilt` rétrécit le bord haut, le garde à `y = 0`, laisse le bas pleine
  largeur, et une plaque translucide reste **d'une seule couleur sans couture** ;
- lancer : `Art.Plate` et `Art.Row` avec `impact = 1` (lettres tournées, décalées, fantômes) se
  rendent sans exception ;
- divers : normalisation de clé, statuts, décodage.

### 11.2 Vérificateur d'import — `VERIFIED`

`build/VerifyMod.cs` reproduit ce que Capri vérifie :

- en-tête complet et valide ;
- fichier < 256 Ko ;
- permissions réelles (`music`, `hotkeys`) ;
- `requires: api 3` ;
- compilation avec le compilateur .NET Framework en C# 5 ;
- exactement une classe `ICapriMod` ;
- classe instanciable ;
- namespace non réservé.

Sortie : `VERIFIED: the mod is importable as-is.`

### 11.3 Contrôle réseau réel — `LIVE OK`

`tests/LiveCheck.cs` (facultatif, hors build) interroge lrclib et lyrics.ovh avec **le code du
mod** (`LyricsSource`, `LyricsParser`) et vérifie :

- résultat synchronisé avec au moins 4 lignes ;
- temps ordonnés et premier temps plausible ;
- aller-retour LRC (écriture puis relecture) sans perte ;
- `IndexAt` et `Fraction` cohérents ;
- repli texte lyrics.ovh.

Dernier passage :

| Titre | Résultat |
| --- | --- |
| Daft Punk — Get Lucky | lrclib, synchronisé, 112 lignes |
| Coldplay — Yellow | lrclib, synchronisé, 37 lignes |
| Dua Lipa — Levitating | lrclib, synchronisé, 74 lignes |
| Angèle — Bruxelles je t'aime | lrclib, synchronisé, 56 lignes |
| Coldplay — Yellow (lyrics.ovh) | texte simple, 40 lignes |

### 11.4 Vérifications runtime (Capri 0.8.9)

- `Capri lyrics CC` : fenêtre 42×42, à gauche du cœur.
- `Capri lyrics` : fenêtre exactement à la taille du plateau — `920×224` au défaut, `1100×211`
  à la dernière vérification (taille choisie à la main, écrite dans `lyrics.band`) — style étendu
  `0x00090008` (layered + topmost, **sans** `TOOLWINDOW` ni `NOACTIVATE`), propriétaire caché non
  nul, sous la fenêtre de Capri.
- Livrable : `149 746` octets, SHA-256 `80cbf7c6…f4bf2` ; journal 1.2.1 :
  `Capri Lyrics 1.2.1 started.`
- Test de hit-test : en-tête → `HTCLIENT (1)`, corps → `HTTRANSPARENT (-1)`, coin bas-droit →
  `HTCLIENT (1)`.
- Test de redimensionnement : glisser le coin de **+120, +60** fait passer la fenêtre de
  `920×224` à `1040×284`, sans déplacer son coin haut-gauche ; le retour à `920×224` est exact.
  La taille est écrite dans `lyrics.band` et restaurée au démarrage ; elle a depuis été poussée à
  la main jusqu'à `1100×211` (et jusqu'à la hauteur minimale de 170), sans débordement.
- Animation et nouveaux éléments (rendu hors écran, pixels comptés) : égaliseur cyan/rose présent
  dans l'en-tête, losange pilote lumineux, 23 pixels de graduation sur le rail, ergots rose/cyan
  de la ligne courante, plaque **uniforme** (1 629 échantillons identiques, 0 différent) et
  en-tête qui change de **3 539** pixels en 250 ms sans qu'aucune parole ne défile.
- Performances de la boucle de frame : voir §12 (présentation `1,90 → 1,87 ms` à l'écran,
  `0,79 ms` hors écran ; frame complète `4,06 ms` hors écran).
- Paroles lrclib récupérées et mises en cache UTF-8 valide.
- Restauration de position : `lyrics.pos = 51,271` → fenêtre à `51,271`.
- Siège : bandeau à `51,271`, corps de Capri à `588,2,376,376` ; hanche = `271` = bord haut du
  bandeau, donc elle est assise exactement dessus et suit le bandeau déplacé.
- `CC` : glissement synthétique du mini-player de `1325,275` à `1411,317` ; delta mini
  `(86,42)`, delta `CC` `(86,42)`, mesurés **bouton encore enfoncé**.
- Journal : `Lyrics: Capri is sitting on the lyrics.` après la pose ; plus aucune
  `IndexOutOfRangeException` avant le premier horodatage.

---

## 12. Performances

- Tick de 80 ms très léger : lecture de `Music.Now`, position, géométrie du `CC`, hook éventuel
  du mini-player, `WatchThrow` (une lecture de champ et une position). Aucune allocation de
  bitmap tant que le bandeau est fermé.
- Bandeau ouvert : la boucle de frame peint à un rythme adaptatif — 14 ms (~60 fps) pendant un
  lancer, 30 ms (~30 fps) pendant la lecture, 55 ms (~18 fps) au repos. Le timer demande 15 ms,
  soit le quantum Windows ; le `Stopwatch` décide ensuite de peindre ou non. Le karaoké est lissé
  par `Playhead()` entre deux échantillons du tick, donc la progression et le rail avancent par
  petits pas au lieu de sauter. L'entrée de ligne (220 ms), les glitches (220 ms toutes les ~3,4 s)
  et le lancer forcent simplement plus de frames.
- **La présentation ne coûte plus rien.** `UpdateLayeredWindow` recevait un `Bitmap.GetHbitmap`
  neuf à chaque frame ; la bande garde maintenant un `Win32.LayeredCanvas` (une section DIB 32 bpp,
  un DC mémoire, un DC écran) et y copie la frame en un seul `memcpy`. Mesure hors écran à
  1100 × 211 : présentation **1,90 → 0,79 ms** (−58 %), frame complète **5,15 → 4,06 ms**.
  À l'écran (DWM), la présentation reste autour de **1,87 ms** et la frame complète **5,40 ms**
  (dessin 2,10 ms, déformation 1,43 ms). Le lancer, lui, reste à ~4,1 ms hors écran.
- **Ce qui a été supprimé du chemin chaud** :
  - les polices sont **créées une fois puis partagées** (`Art.Fonts`, clé visage + taille +
    style) ; aucun appelant ne les libère plus (elles sont prêtées, pas possédées) ;
  - un seul `StringFormat` typographique partagé au lieu d'un clone par ligne et par frame ;
  - `GlitchText` met en cache la largeur de chaque glyphe par ligne (`GlyphWidths`), les chaînes
    d'un caractère (`CharText`) et la hauteur de police, et réutilise un `Matrix` + un pinceau :
    plus de mesure ni d'allocation par lettre ;
  - les lignes de contexte, pendant le vol, se déchirent **en une seule ligne** (deux `DrawString`)
    au lieu d'être dessinées lettre par lettre : le rendu est identique à cette taille ;
  - `Art.Tilt` précalcule une fois par taille et par échelle une table de correspondance
    (`TiltFrom`/`TiltBlend`, poids entiers 8 bits) et n'alloue plus ni tableau ni bitmap par frame ;
  - la surface de dessin et la copie déformée sont **réutilisées** tant que la taille ne change
    pas (`surface`, `warped`), au lieu de deux bitmaps par frame ;
  - le `CC` et le tick ne repeignent plus : la boucle de frame est le seul peintre, ce qui évite
    les doubles rendus d'un même changement d'état.
- **Perspective** : `Art.Tilt` déforme l'image **ligne par ligne** en mémoire (`LockBits` +
  `Marshal.Copy`), une seule fois par rendu complet. Aucune bande `DrawImage` empilée, donc
  aucune couture sur le noir translucide.
- **Redimensionnement** : chaque pas de souris sur la poignée redessine la plaque à sa nouvelle
  taille ; le relâchement borne et mémorise. Le glissement d'en-tête, lui, ne redessine pas.
- **Glissement** : `SlideTo` réutilise la dernière image rendue ; aucun texte, contour ni
  perspective recalculé tant que le bouton de la souris est enfoncé. Le rendu complet attend le
  relâchement.
- **Suivi du `CC`** : `SlideWith` ne fait que déplacer la fenêtre déjà peinte sur chaque
  `WM_MOVE` du mini-player, sans repeindre ; le tick ne s'occupe que de l'échelle et de la
  visibilité.
- Aucune requête réseau sur le thread UI ; timeouts courts (7 s) ; une seule requête par morceau
  et par ticket.
- Cache mémoire + disque : un morceau déjà vu s'affiche sans réseau.
- Sauvegarde disque au plus toutes les 8 s.

---

## 13. Limites connues

1. **Windows seulement** (WinForms/GDI+/Win32).
2. **Pas de permission `network`** dans l'API 3 : `System.Net` direct, avec les mêmes garanties
   de confidentialité (artiste, titre, album, durée uniquement).
3. **Hauteur nécessaire pour s'asseoir** : il faut ~0,62 × la taille de Capri d'espace au-dessus
   du bandeau (~174 px pour une Capri de 280 px). Collé en haut de l'écran, le bandeau reste
   parfait pour les paroles, mais elle ne peut pas s'y percher.
4. **Disponibilité des paroles** : certains titres n'ont rien, d'autres seulement du texte. Les
   « none » sont réessayés après 3 jours.
5. **Dérive LRC** : le tag `[offset]` de la source est respecté, mais il n'existe pas de réglage
   manuel de décalage.
6. **Plein écran exclusif** : une fenêtre classique passe derrière un jeu en plein écran exclusif.
7. **Capri autonome** : elle se lève pour parler/danser ; le mod ne la force pas à rester sur le
   bandeau après la pose d'ouverture.
8. **Ordre Z** : le bandeau est *sous* la fenêtre de Capri, par choix, pour qu'elle reste visible
   devant les paroles.
9. **Le `CC` dépend du mini-player** : s'il est masqué, le bouton disparaît (le raccourci et le
   menu restent disponibles).
10. **Heuristique de pose** : `Her.Bounds` ne distingue pas les poses ; la réussite de
    l'allongement est lue dans la réponse de `Move("lie_down")`, et `OnBand` reste une
    approximation de proximité.
11. **Glitch volontaire** : la ligne courante se déchire brièvement toutes les ~3,4 s ; c'est un
    effet visuel assumé, sans option pour le couper.
12. **Lancer détecté par réflexion** : le champ `thrown` n'est pas public. S'il disparaît d'une
    version de Capri, le repli (vitesse du corps) reste approximatif et peut rater un lancer très
    court ; l'affichage des paroles n'est jamais affecté.
13. **La taille du bandeau ne peut pas descendre sous 560×170** : en dessous, cinq lignes de
    paroles et l'en-tête ne tiennent plus lisiblement.

---

## 14. Compilation, installation, approbation

### Compiler et tester

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

Le script : stub API → compilation du mod avec les mêmes références que Capri → **123 tests** →
vérificateur d'import.

### Installer

```text
%LOCALAPPDATA%\Capri\mods\capri-lyrics.capri-code
```

### Approuver

Capri mémorise l'empreinte SHA-256 du fichier dans
`%LOCALAPPDATA%\Capri\mods\approved.txt` :

```text
capri-lyrics <sha256-minuscule-sans-tirets>
```

Toute modification du fichier change l'empreinte : le mod est alors considéré comme non approuvé
et ne démarre pas. Après une mise à jour, réimporte/réapprouve le mod (ou mets à jour la ligne
`approved.txt`), puis relance Capri. Les mods ne sont chargés qu'au démarrage.

### Journal

```powershell
Get-Content "$env:LOCALAPPDATA\Capri\errors.txt" | Select-String "capri-lyrics"
```

Lignes attendues :

```text
Capri Lyrics 1.2.1 started. Toggle with the CC button beside the heart, or Ctrl+Alt+L.
Lyrics: Capri is sitting on the lyrics.
```

Erreurs explicites : `couldn't put Capri on the lyrics`, `couldn't settle Capri on the lyrics`,
`Ctrl+Alt+L is already taken`.
