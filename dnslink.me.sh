#!/bin/bash
################################################################################
# Author: Fred (support@qo-op.com)
# Version: 0.1
# License: AGPL-3.0 (https://choosealicense.com/licenses/agpl-3.0/)
################################################################################
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat <<EOF
Usage: $(basename "$0") [options]

Publie astroport.one/ sur IPFS, met à jour .chain,
et met à jour le DNSLink OVH (_dnslink / _dnslink.www sur astroport.one).

Options:
  -h, --help    Affiche cette aide

Flux:
  1. ipfs add -rwHq ./*          → nouveau CID IPFS
  2. Si CID inchangé             → exit 0 (rien à faire)
  3. Mise à jour .chain + .moats + README.md
  4. DNSLink OVH upsert (_dnslink + _dnslink.www)
  5. SSL auto via acme.sh + OVH DNS challenge

Credentials OVH (par priorité):
  a. Variables ENV: OVH_APP_KEY / OVH_APP_SECRET / OVH_CONSUMER_KEY
  b. cooperative_config.sh (Kind 30800 NOSTR)
EOF
    exit 0
fi

echo '
############################################################### ipfs
##    _    ____ _____ ____   ___  ____   ___  ____  _____    ___  _   _ _____
##   / \  / ___|_   _|  _ \ / _ \|  _ \ / _ \|  _ \_   _|  / _ \| \ | | ____|
##  / _ \ \___ \ | | | |_) | | | | |_) | | | | |_) || |   | | | |  \| |  _|
## / ___ \ ___) || | |  _ <| |_| |  __/| |_| |  _ < | |   | |_| | |\  | |___
##/_/   \_\____/ |_| |_| \_\\___/|_|    \___/|_| \_\|_|    \___/|_| \_|_____|
'

MOATS=$(date -u +"%Y%m%d%H%M%S%4N")

OLD=$(cat ${MY_PATH}/.chain 2>/dev/null)
[[ -z ${OLD} ]] \
    && GENESYS=$(ipfs add -rwHq --ignore=.git --ignore-rules-path=.gitignore ${MY_PATH}/* | tail -n 1) \
    && echo ${GENESYS} > ${MY_PATH}/.chain \
    && echo "### - (^‿‿^) - " >> ${MY_PATH}/README.md \
    && echo /ipfs/${GENESYS} >> ${MY_PATH}/README.md \
    && echo "CHAIN BLOC ZERO : ${GENESYS}" \

echo "## TIMESTAMP CHAIN SHIFTING"
cp ${MY_PATH}/.chain \
        ${MY_PATH}/.chain.$(cat ${MY_PATH}/.moats 2>/dev/null || echo "0")

echo "## CLEANING OLD CHAIN FILES"
ls -t ${MY_PATH}/.chain* 2>/dev/null | tail -n +3 | xargs rm -f 2>/dev/null || true

IPFSME=$(ipfs add -rwHq --ignore=.git --ignore-rules-path=.gitignore ${MY_PATH}/* | tail -n 1)

[[ ${IPFSME} == ${OLD} ]] && echo "No change." && exit 0

echo "## CHAIN UPGRADE"
echo ${IPFSME} > ${MY_PATH}/.chain
echo ${MOATS} > ${MY_PATH}/.moats

echo "## README UPGRADE ${OLD}~${IPFSME}"
sed -i "s~${OLD}~${IPFSME}~g" ${MY_PATH}/README.md

# ── DNSLINK OVH ───────────────────────────────────────────────────────────────
OVH_TOOL="${HOME}/.zen/Astroport.ONE/admin/system/ovh.me.sh"

if [[ -x "$OVH_TOOL" ]]; then
    echo "## IPFS SITE : ${IPFSME}"
    OVH_ZONE="astroport.one" "$OVH_TOOL" upsert "_dnslink"     "/ipfs/${IPFSME}" || true
    OVH_ZONE="astroport.one" "$OVH_TOOL" upsert "_dnslink.www" "/ipfs/${IPFSME}" || true
else
    echo "SKIP DNSLink: ${OVH_TOOL} introuvable"
fi

# ── SSL AUTO (Let's Encrypt via OVH DNS challenge) ────────────────────────────
COOP_SH="${HOME}/.zen/Astroport.ONE/tools/cooperative_config.sh"
if [[ -z "${OVH_APP_KEY:-}" && -f "$COOP_SH" ]]; then
    # shellcheck source=/dev/null
    source "$COOP_SH" 2>/dev/null
    export OVH_APP_KEY=$(coop_config_get "OVH_APP_KEY" 2>/dev/null) || true
    export OVH_APP_SECRET=$(coop_config_get "OVH_APP_SECRET" 2>/dev/null) || true
    export OVH_CONSUMER_KEY=$(coop_config_get "OVH_CONSUMER_KEY" 2>/dev/null) || true
fi

if [[ -n "${OVH_APP_KEY:-}" && -n "${OVH_APP_SECRET:-}" && -n "${OVH_CONSUMER_KEY:-}" ]]; then
    ACME="${HOME}/.acme.sh/acme.sh"
    ACME_EMAIL=$(cat "${HOME}/.zen/game/players/.current/.player" 2>/dev/null)
    ACME_EMAIL="${ACME_EMAIL:-support@qo-op.com}"
    if [[ ! -x "$ACME" ]]; then
        echo "## INSTALL acme.sh"
        curl -fsSL https://get.acme.sh | sh -s email="${ACME_EMAIL}" 2>/dev/null
    fi
    if [[ -x "$ACME" ]]; then
        echo "## SSL : astroport.one + www.astroport.one"
        export OVH_AK="$OVH_APP_KEY"
        export OVH_AS="$OVH_APP_SECRET"
        export OVH_CK="$OVH_CONSUMER_KEY"
        "$ACME" --issue --dns dns_ovh \
            -d "astroport.one" -d "www.astroport.one" 2>/dev/null \
            || "$ACME" --renew -d "astroport.one" 2>/dev/null \
            || true
    fi
fi

exit 0
