# M-PLAY PS4

**Centre multimédia homebrew pour PS4 — projet en développement**

Créateur : **Mourtadhoi DJAFFAR**  
Graphic designer : **Mourtadhoi Art**  
E-mail : Mourtadhoi.djaffar@gmail.com  
Réseaux sociaux : @Mourtadhoi.art

> **État actuel : prototype de démarrage.** Ce dépôt contient une base native C++ et une chaîne de compilation OpenOrbis/GitHub Actions. Il ne constitue pas encore un lecteur multimédia complet : l'interface graphique, les entrées DualShock 4, la lecture audio/vidéo, le streaming réseau et les opérations sur les fichiers restent à intégrer et à tester sur la console.

## Fonctionnalités et état

| Fonction | État |
|---|---|
| Base native C++ / point d'entrée | Implémenté |
| Métadonnées et icône du package | Préparées |
| Compilation automatisée par GitHub Actions | Configurée, à valider sur le premier run |
| Page d'accueil graphique | À implémenter |
| Navigation DualShock 4 | À implémenter |
| Import / analyse M3U | À implémenter |
| Streaming HTTP/HTTPS | À implémenter |
| Lecture MP4 / MP3 | À implémenter |
| Gestionnaire de fichiers interne/USB | À implémenter et vérifier selon les accès disponibles |
| Copie, collage, renommage, suppression | À implémenter avec confirmations |
| Sons d'interface | À implémenter |
| Heure système PS4 | À vérifier avec l'API disponible |
| Paramètres persistants / réinitialisation | À implémenter |
| Page À propos | Informations intégrées dans le prototype |

## Arborescence

```text
M-PLAY-PS4/
├── .github/workflows/build.yml
├── assets/README.md
├── docs/ROADMAP.md
├── docs/ARCHITECTURE.md
├── sce_sys/icon0.png
├── src/main.cpp
├── tools/make_gp4.py
├── .gitignore
├── LICENSE
├── Makefile
└── README.md
```

## Compilation automatique

1. Crée un dépôt GitHub vide nommé `M-PLAY-PS4`.
2. Téléverse le contenu de ce dossier (les fichiers, pas le ZIP lui-même).
3. Ouvre l'onglet **Actions** et active les workflows si GitHub le demande.
4. Lance **Build M-PLAY PS4** avec **Run workflow**, ou pousse un commit.
5. Consulte les journaux du workflow. Si la compilation réussit, télécharge l'artefact `M-PLAY-PS4-build` contenant le `.pkg` et `eboot.bin`.

Le premier build peut échouer si la version de la toolchain ou une dépendance système a changé. Il faut alors corriger le workflow à partir du journal exact, sans supposer que le PKG est valide avant sa génération et sa vérification.

## Compilation locale (Linux/WSL avec OpenOrbis installé)

```bash
export OO_PS4_TOOLCHAIN="/chemin/vers/OpenOrbis-PS4-Toolchain"
make
```

Le Makefile utilise les outils `clang`, `clang++`, `ld.lld`, `create-fself` et `PkgTool.Core` de la toolchain. Vérifie que `sce_sys/about/right.sprx` est disponible depuis la toolchain et copié à cet emplacement avant la génération du package.

Nettoyage :

```bash
make clean
```

## Identité du package

Les identifiants actuels sont des valeurs provisoires pour le développement :
- Titre : `M-PLAY PS4`
- Title ID : `MPLY00001`
- Content ID : `IV0000-MPLY00001_00-MPLAYPS400000000`

Ne réutilise pas ces identifiants si tu prépares plusieurs variantes distribuées. L'icône `sce_sys/icon0.png` est un PNG 512 × 512 RGB.

## Important

- Utilise uniquement des playlists et des flux auxquels tu es autorisé à accéder.
- Une compilation réussie ne prouve pas que l'application démarre sur chaque firmware ou configuration homebrew.
- Les APIs système, le stockage interne, les codecs, le réseau et la manette doivent être testés sur le matériel cible.
- N'ajoute pas de bibliothèques binaires sans vérifier leur licence, leur compatibilité PS4 et leurs dépendances.
