#!/bin/bash
# */5 * * * * /usr/local/bin/dynhost-update.sh
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
MY_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
MY_PATH="$MY_DIR/$(basename "$SOURCE")"

source "$MY_DIR/.env"

CACHE="/tmp/dynhost_last_ip"
mkdir -p $HOME/.zen/tmp/

HOSTS="astroport.one www.astroport.one"

TARGET="$HOME/.local/bin/dynhost-update.sh"
if [ ! -L "$TARGET" ] || [ "$(readlink -f "$TARGET")" != "$MY_PATH" ]; then
  ln -sf "$MY_PATH" "$TARGET"
fi

IP=$(upnpc -s 2>/dev/null | awk -F'= ' '/ExternalIPAddress/ {print $2}')
if [ -z "$IP" ]; then
  IP=$(curl -s https://api.ipify.org)
fi
if [ -z "$IP" ]; then
  echo "Erreur: impossible de récupérer l'IP via UPnP" >&2
  exit 1
fi


# Ne mettre à jour que si l'IP a changé
LAST=$(cat "$CACHE" 2>/dev/null)
if [ "$IP" = "$LAST" ]; then
  exit 0
fi

for HOST in $HOSTS; do
  RESULT=$(curl -s "https://www.ovh.com/nic/update?system=dyndns&hostname=${HOST}&myip=${IP}" \
    -u "${LOGIN}:${PASSWORD}")
  echo "$(date) | $HOST | $IP | $RESULT" >> $HOME/.zen/tmp/dynhost.log
done

echo "$IP" > "$CACHE"
