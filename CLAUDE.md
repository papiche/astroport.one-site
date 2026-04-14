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

## `dynhost-update.sh`

Cron script (`*/5 * * * *`) updating OVH DynDNS for `astroport.one` and `www.astroport.one`. Requires a `.env` file in the same directory:

```bash
LOGIN=your-ovh-dynhost-login
PASSWORD=your-ovh-dynhost-password
```

IP detection: tries UPnP first (`upnpc`), then falls back to `api.ipify.org`. Only updates when IP changes (cached in `/tmp/dynhost_last_ip`). Logs to `~/.zen/tmp/dynhost.log`.
