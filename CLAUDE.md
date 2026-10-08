# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Static IPFS site for Astroport.ONE — a presentation/showcase page with a live 3D network visualization. No build step, no package manager. The entire frontend lives in a single `index.html`.

## Publishing to IPFS

```bash
# Ajouter récursivement et récupérer le CID racine
ipfs add -r --wrap-with-directory .
# Le dernier CID affiché (sans nom de fichier) est le CID racine
```

Access: `https://ipfs.copylaradio.com/ipfs/<CID>/`

## Architecture de `index.html`

The file is one self-contained HTML page with three logical layers:

1. **CSS** (lines ~8–264) — Two color themes via `body.sp` class (CYBER = cyan `#00f5ff`, SOLAR = green `#7fd67f`). No external stylesheet.

2. **HTML structure** (lines ~265–444) — Sections: `#hero` (canvas), `#network`, `#dragons`, `#zen`, `#commons`, `#media` (dynamic grid), plus a modal `#mmModal` for media playback.

3. **JavaScript** (lines ~446–766) — Three.js globe with 12 mock nodes, orbiting "dragon" service dots, particle flows on links, raycaster for hover tooltip and click→side panel. All node data (hostnames, services, health) is hardcoded static arrays — this is demo data, not live.

## Navigation commune (4 pages : index, architecture, capitaine, install)

Le menu `<nav>` est **dupliqué à l'identique** dans les quatre pages (pas de build, pas d'include) : ACCUEIL · ARCHITECTURE · GUIDE CAPITAINE · NOUS RECRUTONS · GITHUB, la page courante porte `class="on"`. Toute nouvelle page ou tout nouveau lien doit être reporté dans les quatre fichiers, ainsi que le pied de page (même liste de liens). Les ancres internes d'une page sont dans la barre `.subnav` (collante, sous le menu) ; `capitaine.html` garde sa barre d'étapes numérotées. Le menu hamburger s'active sous 1040 px (5 liens + CYBER/SOLAR + LIVE sur l'accueil). Le thème CYBER/SOLAR est mémorisé dans `localStorage` (`uplanet.theme`) et suit d'une page à l'autre.

## `architecture.html`

Page statique annexe (même charte CYBER/SOLAR que `install.html`) qui explique les couches du système d'information : scène p5.js (`libs/p5.min.js`, v1.9.4 embarquée comme `three.min.js`, pas de CDN) avec cinq plans empilés (réseau, identités, NOSTR, dragons, économie) et une horloge 4D qui rejoue les cycles réels des scripts ; SVG isométrique de la grille UMAP/SECTOR/REGION ; frise de 9 jours. Les stations de la scène sont fictives ; les durées (12 h balise, 20h12, 7 jours, 9 jours, 50 min…) sont celles de `_12345.sh`, `20h12.process.sh`, `NOSTRCARD.refresh.sh` et `DRAGON_p2p_ssh.sh` : à mettre à jour si ces scripts changent.

## `capitaine.html`

Guide pas à pas pour les Capitaines (ports de la box, Nginx Proxy Manager, NextCloud, PAF et énergie, mode LIVE). Mêmes conventions que `install.html` (charte CYBER/SOLAR, aucune dépendance externe hors les libs UPlanet chargées par `document.write` comme dans `index.html`). Les hôtes NPM du configurateur (`HOSTS` dans le script) reprennent `install/setup/setup_npm.sh` d'Astroport.ONE : à garder alignés si ce script change. Les captures `img/npm-proxy-hosts.jpg` et `img/npm-custom-locations.jpg` viennent d'une vraie station. Le panneau LIVE lit les événements kind 30850 via `UPlanetHeartbox` (`hardware.energy` et `hardware.solar` pour la consommation PowerJoular et la production Victron).

## `media.json` — critical for IPFS

IPFS has no server-side directory listing. The media section (`index.html:745–763`) tries `media.json` first; if absent, it falls back to parsing nginx autoindex HTML (fails on IPFS).

**Update `media.json` whenever files are added to `pdf/` or `video/`.**

```json
[
  { "url": "video/filename.mp4", "type": "video", "title": "DISPLAYED TITLE" },
  { "url": "pdf/filename.pdf",   "type": "pdf",   "title": "DISPLAYED TITLE" }
]
```
Supported types: `"video"` (mp4, webm, ogg, mov), `"pdf"`.

Title is displayed as-is in uppercase monospace; the fallback scanDir auto-generates titles by stripping extension and replacing `_-+` with spaces.

## `microledger.me.sh`

Script de publication : `ipfs add` du répertoire → met à jour `.chain` → git commit/push → DNSLink OVH upsert (`_dnslink.astroport.one` + `_dnslink.www.astroport.one`) → SSL auto via acme.sh + OVH DNS challenge.

L'A record `astroport.one` est **statique** (IP de la gateway publique `ipfs.copylaradio.com`). NPM sur la gateway proxifie `astroport.one:443` → `127.0.0.1:8080` (Kubo) avec `proxy_set_header Host $host` pour activer la résolution DNSLink. Le contenu est mis à jour uniquement via le TXT `_dnslink`.
