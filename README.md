# Astroport.ONE — Site vitrine IPFS + DNSLink

Site statique de présentation d’Astroport.ONE publié sur IPFS et accessible via un domaine propre grâce à DNSLink.

---

## 📁 Structure du projet

```
astroport.one/
├── index.html
├── media.json
├── video/
│   └── Astroport.mp4
└── pdf/
    ├── Astroport.ONE_Sovereign_P2P_Swarm.pdf
    └── Sovereign_Internet_Manifesto.pdf
```

---

## 🚀 Publication sur IPFS

Ajouter le dossier complet :

```bash
ipfs add -rw *
```

👉 Récupérer le **CID racine** (dernière ligne) :

```
QmXXXXXXXXXXXX
```

---

## 🌐 Configuration DNS (DNSLink)

### Configuration recommandée

```dns
A      dnslink.astroport.one      149.102.158.67
CNAME  astroport.one             dnslink.astroport.one.
A      www.astroport.one         149.102.158.67
TXT    _dnslink.astroport.one    "dnslink=/ipfs/QmXXXXXXXXXXXX"
```

---

## 🔍 Fonctionnement

* `astroport.one` → redirige vers `dnslink.astroport.one`
* `dnslink.astroport.one` → pointe vers ta gateway IPFS
* `_dnslink.astroport.one` → contient le CID IPFS

👉 La gateway :

1. lit le domaine demandé (`astroport.one`)
2. récupère l’enregistrement DNSLink
3. sert le contenu IPFS correspondant

---

## 🌍 Accès au site

```
https://astroport.one
https://www.astroport.one
```

---

## 🔄 Mise à jour du site

1. Modifier les fichiers
2. Republier :

```bash
ipfs add -rw *
```

3. Mettre à jour le DNS :

```dns
_dnslink.astroport.one "dnslink=/ipfs/NOUVEAU_CID"
```

⏱️ Attendre la propagation DNS

---

## ⚠️ Gestion des médias (`media.json`)

IPFS ne fournit pas de **listing de répertoire**.

Le site fonctionne ainsi :

1. Chargement de `media.json`
2. Fallback : parsing HTML (non fiable)

👉 `media.json` est **obligatoire**

### Format

```json
{
  "url": "video/mon-fichier.mp4",
  "type": "video",
  "title": "Titre affiché"
}
```

Types supportés :

* `"video"` (mp4, webm, ogg, mov)
* `"pdf"`

---

## 🌐 Nginx Proxy Manager (NPM)

### Ajouter un Proxy Host

**Domain Names**

```
astroport.one, www.astroport.one
```

**Forward**

```
Scheme: http
Host: 127.0.0.1
Port: 8080
```

**Options**

* Websockets: ON
* Block Exploits: ON

---

### 🔒 SSL

* Request Let’s Encrypt certificate
* Force SSL
* HTTP/2 enabled

---

### ⚠️ Important (DNSLink)

Ajouter dans **Advanced** :

```nginx
proxy_set_header Host $host;
```

👉 Nécessaire pour que DNSLink fonctionne correctement

---

### 🔁 Redirection www → root (optionnel)

```nginx
if ($host = www.astroport.one) {
    return 301 https://astroport.one$request_uri;
}
```

---

## 🧠 Notes techniques

* DNSLink utilise `_dnslink.<domaine>` (TXT)
* IPFS ne liste pas les fichiers → usage de `media.json`
* Gateway doit supporter :

  * Host header
  * DNSLink

---

## 🔥 Option avancée : IPNS

Publier :

```bash
ipfs name publish /ipfs/QmXXXXXXXXXXXX
```

DNS :

```dns
_dnslink.astroport.one "dnslink=/ipns/<PEER_ID>"
```

### Avantages

* pas de modification DNS à chaque update

### Inconvénients

* plus lent

---

## 🧭 Résumé

* Upload → `ipfs add -rw`
* DNS → A + CNAME + TXT
* Proxy → Nginx Proxy Manager
* Accès → `https://astroport.one`
* Update → changer le CID DNSLink

---

## 🚀 Améliorations possibles

* Script auto-génération `media.json`
* CI/CD IPFS
* Cache gateway + optimisation perf
* IPNS + pinning automatique

---

Si tu veux, je peux aussi te fournir :

* un script de déploiement automatique IPFS + DNS update
* ou une config complète de gateway IPFS optimisée (NGINX / Caddy) ⚡
