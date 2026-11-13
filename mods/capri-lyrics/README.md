# Capri Lyrics

Mod autonome de paroles pour **Capri Desktop 0.8.9** (Mod API 3).

## Aperçu

Affiche les paroles Spotify synchronisées sur un bandeau **cyberpunk** (bouton **CC**).
Défilement fluide, gros plans du visage de Capri avec effets de glitch, fissures et zoom sur les yeux. Capri peut s'asseoir ou s'allonger pendant l'affichage.

## Fonctionnalités

- **Paroles synchronisées** (LRC) via [lrclib.net](https://lrclib.net) et [lyrics.ovh](https://api.lyrics.ovh)
- **Paroles simples** en fallback quand les paroles synchronisées sont indisponibles
- **Cache local** des paroles pour éviter les requêtes répétées
- **Affichage cyberpunk** : texte glitché, couleurs cyan/rose, fissures, zoom sur les yeux
- **Défilement fluide** avec la ligne courante mise en évidence
- **Bouton CC** pour afficher/masquer le bandeau
- **Poses de Capri** : assis, allongé, aucun
- Gestion des morceaux instrumentaux

## Installation

1. Placez le fichier `capri-lyrics.capri-code` dans le dossier des mods Capri :
   ```
   %LOCALAPPDATA%\Capri\mods\
   ```
2. Redémarrez Capri Desktop.
3. Le mod est automatiquement chargé et disponible.

## Utilisation

- Cliquez sur le bouton **CC** pour afficher les paroles du morceau en cours.
- Les paroles se synchronisent automatiquement avec la lecture Spotify.
- La pose de Capri (assis / allongé / aucun) peut être réglée via les commandes du mod ou les paramètres associés.

## Sources de paroles

| Source | Type | URL |
|--------|------|-----|
| lrclib.net | Synchronisées + simples | https://lrclib.net |
| lyrics.ovh | Simples | https://api.lyrics.ovh |

## Cache

Les paroles récupérées sont mises en cache localement dans le dossier du mod (fichier `lyrics-cache.jsonl`) pour un affichage instantané lors des écoutes répétées.

## Informations techniques

| Champ | Valeur |
|-------|--------|
| **ID** | `capri-lyrics` |
| **Nom** | Capri Lyrics |
| **Version** | 1.4.0 |
| **Auteur** | Suoh |
| **API requise** | 3 |
| **Permissions** | music, hotkeys |
| **Langage** | C# 5 (.NET Framework 4) |

## Compatibilité

Capri Desktop 0.8.9

## Licence

Mod communautaire. La redistribution est autorisée avec mention de l'auteur d'origine.

---
*README généré pour l'upload du mod `capri-lyrics.capri-code`.*