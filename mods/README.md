# Capri Lyrics

Les paroles synchronisées de Spotify, sur un bandeau translucide posé devant l'écran — et Capri
peut s'asseoir dessus, s'y allonger, et vivre sa vie par-dessus. On peut le redimensionner par le
coin, et quand on la jette à travers l'écran, les lettres partent en glitch puis reviennent.

Un mod autonome pour **Capri Desktop 0.8.9** (Mod API 3) : `capri-lyrics.capri-code`.

---

## Ce que fait le mod

- **Suit Spotify.** Il lit le morceau en cours dans la session média de Windows, via l'API
  `ICapriMusic` de Capri, et affiche ses paroles.
- **Karaoké synchronisé.** Les paroles LRC défilent ligne par ligne. La ligne courante s'affiche
  en gros plan — jusqu'à 1,55× sa taille de base pour remplir la largeur — avec un remplissage
  progressif rose → cyan au rythme de la chanson. Si le service ne fournit que du texte simple,
  le bandeau l'affiche quand même (mention `APPROX.`).
- **Un bandeau cyberpunk.** Translucide et surtout **noir**, en **une seule teinte unie** (plaque
  alpha 158, RGB 3,4,6) : aucune bande, aucune ligne, aucun dégradé visible à travers le noir.
  Police d'affichage condensée (Bahnschrift SemiBold Condensed), légère perspective en trapèze,
  micro-glitches visuels du karaoké toutes les ~3,4 s (aucun son), et un cadre **vivant** : liseré
  rose → cyan en diagonale qui respire, filet intérieur, équerres HUD aux coins, segments lumineux
  qui parcourent les bords, **égaliseur à quatre barres**, **losange pilote**, rail de progression
  gradué avec une tête pulsée, et deux ergots de signal qui encadrent la ligne courante.
- **Il ne lague plus, et il ne saccade plus.** Le rendu du lancer a été réécrit : polices et
  largeurs de glyphes mises en cache, lignes de contexte déchirées en une passe, perspective
  précalculée et surfaces réutilisées. Surtout, la peinture a sa propre boucle rapide : **~60 fps
  pendant un lancer, ~30 fps pendant la lecture, ~18 fps au repos**, au lieu d'une frame toutes
  les 80 ms. Le karaoké est interpolé entre deux mesures du lecteur, donc la ligne se remplit et
  le rail avance en continu. Une frame complète coûte ~4,1 ms hors Capri et ~5,4 ms à l'écran.
- **Redimensionnable.** Le coin inférieur droit sert de poignée : on maintient et on glisse pour
  changer la taille du bandeau (560×170 à 1600×420), comme une fenêtre normale. La taille est
  retenue d'une session à l'autre.
- **Les paroles réagissent aux lancers de Capri.** Quand on la jette à travers l'écran, chaque
  lettre se décale, tourne, change d'échelle, saute ailleurs en laissant une trace, puis se
  replace quand elle atterrit. Le titre et le liseré frémissent aussi pendant le vol.
- **Un bouton CC.** Un petit bouton `CC` se colle à gauche du cœur du mini-player. Un clic ouvre
  ou ferme les paroles. Il suit le mini-player image par image quand on le déplace.
- **Click-through.** Seul l'en-tête attrape la souris (pour déplacer le bandeau) et le coin
  inférieur droit (pour le redimensionner). Le corps laisse passer les clics : le bandeau ne
  gêne ni un jeu ni un navigateur.
- **Capri dessus.** Le bandeau est une vraie fenêtre-siège, comme le mini-player : elle peut
  s'asseoir sur son bord, marcher dessus et s'y allonger. À l'ouverture, elle s'assied dessus par
  défaut (réglable : s'asseoir, s'allonger ou rester où elle est). Le mini-player reste un siège
  en même temps.

---

## Installation

1. Lance Capri.
2. Ouvre **Mainframe** (clic droit sur la bulle Capri → *Mainframe*).
3. Onglet **CAPRI → Mods**.
4. Clique **Importer un mod…** et choisis `capri-lyrics.capri-code`.
5. Capri lit l'en-tête et affiche les permissions demandées :
   - `music` — savoir quel morceau joue et où il en est ;
   - `hotkeys` — enregistrer le raccourci `Ctrl+Alt+L`.
6. Approuve le mod, puis active-le. Il démarre tout de suite.

> **Windows uniquement.** Le mod utilise WinForms, `System.Drawing` et l'API Win32. Sur Mac et
> Linux, Capri le refuse à l'import en nommant ces parties Windows. C'est normal : rien d'autre
> n'est modifié.

Au premier lancement, le bandeau est **fermé** : seul le bouton `CC` apparaît (quand Spotify
joue). La position, la taille, la taille du texte et la pose choisie sont retenues d'une session
à l'autre.

---

## Utilisation

| Action | Comment |
| --- | --- |
| Ouvrir / fermer les paroles | Clic sur le bouton **CC**, ou **Ctrl+Alt+L**, ou menu **Paroles (CC)**. |
| Déplacer le bandeau | Glisser son **en-tête** (la bande du haut). La position est mémorisée. |
| Redimensionner le bandeau | Glisser le **coin inférieur droit** (le curseur devient une double flèche). La taille est mémorisée. |
| Changer la taille du texte | Mainframe → **Options → Lyrics** → curseur *Taille du texte* (16 à 38 px). |
| Choisir la pose à l'ouverture | Options → **Quand les paroles s'ouvrent** : *s'assied dessus*, *s'allonge dessus* ou *reste où elle est*. |
| Déplacer Capri avec le bandeau | Glisser l'en-tête : elle reste sur son bord et suit le mouvement, sans téléportation. |
| Remettre le bandeau en bas au centre | Options → **Recentrer la fenetre**. |
| Demander à voix haute | « Capri, affiche les paroles » / « Capri, cache les paroles ». |

Le bouton `CC` n'apparaît que lorsque **Spotify** est la source du morceau. Le bandeau, lui,
suit n'importe quel morceau exposé par la session média de Windows.

### Les états du bandeau

| Badge | Sens |
| --- | --- |
| `SYNCHRO` | Paroles synchronisées (LRC), karaoké actif. |
| `APPROX.` | Paroles trouvées, mais sans horodatage : affichage simple. |
| `CHARGEMENT` | Recherche en cours sur le réseau. |
| `INSTRUMENTAL` | Le titre est instrumental : pas de paroles à afficher. |
| `PAS DE PAROLES` | Aucun service n'a de paroles pour ce titre (nouvel essai après 3 jours). |
| `HORS LIGNE` | Réseau indisponible ou services muets : réessai au prochain morceau. |
| *(rien)* | Rien en lecture. |

---

## D'où viennent les paroles

1. **lrclib.net** — `GET /api/get` avec artiste, titre, album et durée (le plus précis).
2. **lrclib.net** — `GET /api/search` si la recherche exacte échoue.
3. **api.lyrics.ovh** — repli en texte simple.

Les résultats sont mis en cache localement, pour ne pas redemander le même morceau. Un « pas de
paroles » est réessayé au bout de **3 jours** (les services se complètent avec le temps).

Rien n'est envoyé d'autre que **l'artiste, le titre, l'album et la durée**. Aucun compte, aucun
jeton, aucune donnée d'écoute, aucune télémétrie.

---

## Fichiers et données

| Chemin | Contenu |
| --- | --- |
| `%LOCALAPPDATA%\Capri\mods\capri-lyrics.capri-code` | Le mod installé. |
| `%LOCALAPPDATA%\Capri\mods\capri-lyrics-data\store.json` | Réglages : ouvert/fermé, position, taille du bandeau, taille du texte, pose (`sit`, `lie`, `none`). |
| `%LOCALAPPDATA%\Capri\mods\capri-lyrics-data\lyrics-cache.jsonl` | Cache des paroles (500 morceaux max, UTF-8). |
| `%LOCALAPPDATA%\Capri\errors.txt` | Journal de Capri : lignes `mod capri-lyrics`. |

Supprimer `capri-lyrics-data` remet le mod à zéro (paroles rouvertes au prochain morceau, position
par défaut). Le mod, lui, reste installé.

---

## Limites honnêtes

- **Windows seulement** (WinForms, GDI+, `user32`).
- **Pas de permission `network` dans l'API 3.** Le mod utilise `System.Net` directement, comme
  tout code mod (qui a déjà un accès complet au PC). Seuls artiste/titre/album/durée sortent.
- **Le bandeau est une fenêtre ordinaire**, pas une fenêtre d'outil : c'est ce qui permet à
  `Ledges` de le proposer comme siège. Son propriétaire caché le garde hors de la barre des
  tâches et d'Alt+Tab, et il ne prend jamais le focus. Le mini-player garde son propre siège :
  les deux coexistent.
- **Il faut de la place au-dessus du bandeau.** Capri a besoin de sa hauteur de corps comme
  « plafond » (environ 0,62× sa taille, soit ~174 px pour une Capri de 280 px) pour s'asseoir.
  Collé tout en haut de l'écran, le bandeau reste utilisable pour les paroles, mais elle ne peut
  pas s'y percher ; descendez-le d'une centaine de pixels.
- **Toutes les paroles n'existent pas.** Certains titres n'ont ni LRC ni texte ; d'autres n'ont
  qu'un texte non synchronisé. Le badge le dit franchement.
- **Le LRC peut dériver** de quelques dixièmes de seconde selon l'édition du morceau. Le tag
  `[offset:…]` fourni par la source est respecté ; il n'y a pas de réglage manuel de décalage.
- **Plein écran exclusif** (jeux) : le bandeau, comme toute fenêtre classique, passe derrière.
- **Capri garde son libre arbitre** : elle se lève pour parler, danser ou suivre une idée. Le mod
  ne la force pas à rester sur le bandeau ; il la pose à l'ouverture selon la pose choisie, puis
  la laisse vivre.
- **Le bandeau est sous sa fenêtre**, comme son mini-player : elle apparaît toujours devant les
  paroles, jamais l'inverse.

---

## Dépannage

| Symptôme | Piste |
| --- | --- |
| Pas de bouton `CC` | Spotify doit jouer, et le mini-player doit être visible. Le `CC` suit le mini-player. |
| Le raccourci ne fait rien | `Ctrl+Alt+L` est peut-être déjà pris : le journal le dit, utilise le `CC` ou le menu. |
| `PAS DE PAROLES` | Le titre n'est pas encore référencé ; nouvel essai automatique après 3 jours. |
| `HORS LIGNE` | Vérifie la connexion ; le mod réessaie au morceau suivant. |
| Le bandeau a disparu de l'écran | Options → **Recentrer la fenetre**. |
| Le mod ne démarre plus après une modification | Capri vérifie l'empreinte du fichier : réimporte et réapprouve le mod. |

---

## Vérifications

- **123 tests moteur** (LRC, JSON, sources, cache, mise en page, géométrie du `CC`, poses,
  perspective sans couture, surface recyclée, redimensionnement, rendu du glitch) : tous passent
  hors de Capri, sans réseau.
- **Vérificateur d'import** : en-tête, compilation avec le compilateur de Capri, une seule classe
  `ICapriMod`, permissions réelles, API 3 → `VERIFIED`.
- **Contrôle réseau réel** (`tests/LiveCheck.cs`) : lrclib et lyrics.ovh, avec le parseur du mod.
  Dernier passage : `LIVE OK` sur Daft Punk, Coldplay, Dua Lipa et Angèle (LRC synchronisé) +
  repli texte via lyrics.ovh.
- **Runtime Capri** : bouton `CC` 42×42 à côté du cœur, bandeau à la taille du plateau (le liseré
  néon est rentré : fenêtre = plaque = siège) et **redimensionnable** (vérifié 920×224 → 1040×284
  → 920×224, taille restaurée après relance ; poussé à la main jusqu'à 1100×211 sans
  débordement), hit-test en-tête/coin = `HTCLIENT`, corps = `HTTRANSPARENT`, paroles récupérées et
  mises en cache, Capri assise sur le bord (`Lyrics: Capri is sitting on the lyrics.`), et le `CC`
  qui suit le mini-player pendant qu'on le glisse (déplacement mesuré identique au pixel). La
  fenêtre du bandeau porte le style `0x00090008` (layered + topmost, sans `TOOLWINDOW` ni
  `NOACTIVATE`).
- **Performances** : présentation de la frame **1,90 → 0,79 ms** hors écran (canvas DIB recyclé),
  frame complète **4,06 ms** hors écran et **5,40 ms** à l'écran ; boucle adaptative 60/30/18 fps
  selon l'activité.
- **Livrable** : `149 746` octets, SHA-256 `80cbf7c6…f4bf2`.

Pour compiler, tester et vérifier :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

Pour le contrôle réseau (facultatif) :

```powershell
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
& $csc /nologo /target:exe /out:build\live.exe /r:System.dll /r:System.Core.dll `
  /r:System.Drawing.dll /r:System.Windows.Forms.dll `
  build\CapriDesktop.cs build\mod.cs tests\LiveCheck.cs
.\build\live.exe
```

---

## Détails techniques

Voir [DOCUMENTATION.md](DOCUMENTATION.md) : architecture, sources et format du cache, géométrie,
intégration aux sièges de Capri, réflexion, performances et limites.
