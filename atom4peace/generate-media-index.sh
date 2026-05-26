#!/usr/bin/env bash

set -e

OUTPUT="media.json"

# --- PARTIE 1 : GÉNÉRATION DU JSON ---
echo "📦 Generating $OUTPUT..."
echo "[" > $OUTPUT
FIRST=true

add_entry () {
  local FILEPATH="$1"
  local TYPE="$2"

  FILENAME=$(basename "$FILEPATH")
  # Enlever l'extension et remplacer tirets/points par des espaces pour le titre
  TITLE=$(echo "${FILENAME%.*}" | tr '._-' ' ' | tr '[:lower:]' '[:upper:]')

  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    echo "," >> $OUTPUT
  fi

  cat <<EOF >> $OUTPUT
  {
    "url": "$FILEPATH",
    "type": "$TYPE",
    "title": "$TITLE"
  }
EOF
}

# Scan des Vidéos
if [ -d "video" ]; then
    for file in video/*; do
      [ -f "$file" ] || continue
      case "$file" in
        *.mp4|*.webm|*.ogg|*.mov)
          add_entry "$file" "video"
          ;;
      esac
    done
fi

# Scan des PDFs
if [ -d "pdf" ]; then
    for file in pdf/*; do
      [ -f "$file" ] || continue
      case "$file" in
        *.pdf)
          add_entry "$file" "pdf"
          ;;
      esac
    done
fi

echo "]" >> $OUTPUT
echo "✅ $OUTPUT generated."

# --- PARTIE 2 : GÉNÉRATION DU INDEX.HTML (TEMPLATE ASTROPORT) ---
if [ ! -f "index.html" ]; then
  echo "📄 index.html not found, creating from template..."
  cat <<'EOF' > index.html
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Astroport.ONE — Media Library</title>
<style>
    /* Style inspiré du template Astroport.ONE */
    * { margin:0; padding:0; box-sizing:border-box; }
    body { 
        background:#050a12; 
        color:#e0f0ff; 
        font-family:'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
        padding: 2rem;
    }
    h1 { 
        font-family:'Courier New', monospace; 
        color:#00f5ff; 
        letter-spacing:3px; 
        margin-bottom: 2rem; 
        border-bottom: 1px solid rgba(0,245,255,0.2);
        padding-bottom: 0.5rem;
    }

    /* GRID */
    .mgrid {
        display:grid; 
        grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); 
        gap:1.5rem;
    }

    /* CARDS */
    .mcard {
        padding:1.5rem; border-radius:4px;
        background:rgba(0,245,255,0.03); 
        border:1px solid rgba(0,245,255,0.1);
        cursor:pointer; transition:all .25s; position:relative;
        display: flex; flex-direction: column; align-items: center; text-align: center;
    }
    .mcard:hover {
        border-color:rgba(0,245,255,0.4); 
        background:rgba(0,245,255,0.07); 
        transform:translateY(-5px);
        box-shadow: 0 5px 15px rgba(0,0,0,0.3);
    }
    .mcard-ico { font-size:2.5rem; margin-bottom:1rem; }
    .mcard h4 { 
        font-family:'Courier New', monospace; 
        font-size:.85rem; color:#00f5ff; 
        letter-spacing:1px; margin:0;
    }

    /* BADGES */
    .mbadge {
        position:absolute; top:.6rem; right:.6rem;
        font-family:'Courier New', monospace; font-size:.6rem; 
        padding:.2rem .5rem; border-radius:2px; font-weight: bold;
    }
    .mbadge-pdf { background:rgba(255,100,68,0.2); color:#ff6644; border:1px solid #ff6644; }
    .mbadge-video { background:rgba(0,255,136,0.15); color:#00ff88; border:1px solid #00ff88; }

    /* MODAL */
    #mmModal {
        display:none; position:fixed; inset:0; z-index:900;
        background:rgba(2,5,10,0.95); backdrop-filter:blur(10px);
        align-items:center; justify-content:center; padding:1rem;
    }
    #mmModal.open { display:flex; }
    .mm-box {
        width:min(95vw, 1100px); height:min(90vh, 750px);
        background:#050a12; border:1px solid rgba(0,245,255,0.3);
        border-radius:8px; display:flex; flex-direction:column; overflow:hidden;
    }
    .mm-head {
        display:flex; align-items:center; justify-content:space-between;
        padding:1rem; border-bottom:1px solid rgba(0,245,255,0.1); background:rgba(0,245,255,0.05);
    }
    #mm-ttl { font-family:'Courier New', monospace; font-size:0.9rem; color:#00f5ff; }
    .mm-cls { 
        background:none; border:1px solid rgba(255,255,255,0.2); color:white;
        width:30px; height:30px; cursor:pointer; border-radius:4px;
    }
    .mm-cls:hover { background: #ff4444; border-color:#ff4444; }
    #mm-body { flex:1; background:#000; display: flex; align-items: center; justify-content: center; }
    #mm-body iframe, #mm-body video { width:100%; height:100%; border:none; }
</style>
</head>
<body>

    <h1>// MÉDIAS_DISPONIBLES</h1>

    <div class="mgrid" id="mgrid">
        <!-- Contenu généré par JS -->
    </div>

    <!-- MODAL VIEWER -->
    <div id="mmModal" onclick="if(event.target===this)closeMedia()">
        <div class="mm-box">
            <div class="mm-head">
                <span id="mm-ttl">NOM_DU_FICHIER</span>
                <button class="mm-cls" onclick="closeMedia()">✕</button>
            </div>
            <div id="mm-body"></div>
        </div>
    </div>

    <script>
        const mgrid = document.getElementById('mgrid');

        async function loadMedia() {
            try {
                const response = await fetch('media.json');
                const data = await response.json();
                
                if(data.length === 0) {
                    mgrid.innerHTML = "<p>Aucun média trouvé.</p>";
                    return;
                }

                mgrid.innerHTML = data.map((item, index) => `
                    <div class="mcard" onclick="openMedia(${index}, ${JSON.stringify(data).replace(/"/g, '&quot;')})">
                        <span class="mbadge ${item.type === 'video' ? 'mbadge-video' : 'mbadge-pdf'}">
                            ${item.type.toUpperCase()}
                        </span>
                        <div class="mcard-ico">${item.type === 'video' ? '🎬' : '📄'}</div>
                        <h4>${item.title}</h4>
                    </div>
                `).join('');
            } catch (err) {
                mgrid.innerHTML = "<p>Erreur lors du chargement de media.json. Utilisez un serveur local (Live Server ou python -m http.server).</p>";
            }
        }

        function openMedia(index, data) {
            const item = data[index];
            document.getElementById('mm-ttl').textContent = item.title;
            const body = document.getElementById('mm-body');
            body.innerHTML = '';

            if (item.type === 'video') {
                const v = document.createElement('video');
                v.src = item.url;
                v.controls = true;
                v.autoplay = true;
                body.appendChild(v);
            } else {
                const f = document.createElement('iframe');
                f.src = item.url;
                body.appendChild(f);
            }

            document.getElementById('mmModal').classList.add('open');
            document.body.style.overflow = 'hidden';
        }

        function closeMedia() {
            document.getElementById('mmModal').classList.remove('open');
            document.getElementById('mm-body').innerHTML = '';
            document.body.style.overflow = '';
        }

        document.addEventListener('keydown', e => { if(e.key === 'Escape') closeMedia(); });

        loadMedia();
    </script>
</body>
</html>
EOF
  echo "✅ index.html created."
fi

echo "🚀 All done. Open index.html in a web server to see the gallery."
