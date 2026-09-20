# Sourced by each Scrut document, whose initial cwd is a fresh temporary directory.
set -euo pipefail
export LC_ALL=C
export CI=true
export NO_COLOR=1
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CEILING_DIRECTORIES="$PWD"
export LAB_TMP="$PWD"
export npm_config_cache="$LAB_TMP/npm-cache"
export npm_config_userconfig="$LAB_TMP/empty.npmrc"
export npm_config_update_notifier=false
export PUB_CACHE="$LAB_TMP/pub-cache"
: > "$npm_config_userconfig"
mkdir -p "$LAB_TMP/artifacts"
