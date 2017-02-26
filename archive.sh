#!/usr/bin/env bash

set -euo pipefail

showUsage () {
  cat <<EOF
Usage: $0 [-h|--help] [-c|--conf mailman.conf] [archive]

Examples:
  \$ $0 -c kantinen.org--bestyrelsen.conf 2015-March
  \$ $0 -c onlineta.org--sysadmin.conf
  \$ $0 2015-March
  \$ $0
EOF
}

showHelp () {
  echo ""
  showUsage
  echo ""
  cat <<EOF
See README.md for more information.
EOF
}

CONF="mailman.conf"

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help )
      showHelp
      exit 0
      ;;
    -c | --conf )
      shift
      CONF="$1"
      shift
      ;; 
    * )
      break
      ;;
  esac
done

if [ ! -f "${CONF}" ]; then
  echo "Missing a ${CONF}"
  showHelp
  exit 1
fi

. ${CONF}

if [ -z "$BASEURL" ]; then
  echo "BASEURL missing in ${CONF}"
  showHelp
  exit 1
fi

if [ -z "$LIST" ]; then
  echo "LIST missing in ${CONF}"
  showHelp
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "USERNAME missing in ${CONF}"
  showHelp
  exit 1
fi

if [ -z "$PASSWORD" ]; then
  echo "PASSWORD missing in ${CONF}"
  showHelp
  exit 1
fi

COOKIEJAR="$LIST/cookiejar.txt"
LISTURL="$BASEURL/$LIST"

gitignore() {
  if [ ! -f .gitignore ]; then
    echo "$1" > .gitignore
  elif ! grep "$1" .gitignore > /dev/null; then
    echo "$1" >> .gitignore
  fi
}

login() {
  # Don't attempt to re-login if login happened less than 30 minutes ago:
  if [ -f "$COOKIEJAR" ] && find "$COOKIEJAR" -mmin -30 > /dev/null; then
    curl --silent \
      --cookie "$COOKIEJAR" \
      "$LISTURL"
  else
    curl --silent \
      --data "username=${USERNAME}&password=${PASSWORD}" \
      --cookie-jar "$COOKIEJAR" \
      "$LISTURL"
  fi
}

getFile() {
  file="$1"

  filepath="$LIST/$file"
  dirpath="$(dirname "$filepath")"

  if [ ! -f "$filepath" ]; then
    # Create directory substructure:
    #install -D /dev/null "$LIST/$file"
    mkdir -p "$dirpath"
    # Linux touch command, for setting last modification -d
    #touch -d 0 "$LIST/$file"
    # OSX touch command, for setting last modification -a
    touch -a 0 "$filepath"
  fi

  # Get the file if it is stale:
  curl --cookie "$COOKIEJAR" \
    -o "$LIST/$file" \
    -z "$LIST/$file" \
    --remote-time \
    "$LISTURL/$file"
}

foreach() {
  local STREAM="$1"
  local RE="$2"
  local DO="$3"

  local Ms=$(echo "$STREAM" | grep "$RE" | sed "s/.*${RE}.*/\1/")
  echo "$Ms" | while read M; do
    $DO "$M"
  done
}

getArchive() {
  getFile "$1"
  getAttachments "$(cat "$LIST/$1")"
}

getArchives() {
  foreach "$1" \
    "\([0-9]\{4\}-[A-Z][a-z]\\+\\.txt\\.gz\)" \
    getArchive
}

getAttachments() {
  foreach "$1" \
    "$LIST\\/\(attachments\\/[0-9]\{8\}\\/.*\)>" \
    getFile
}

mkdir -p "$LIST"

gitignore "$CONF"
gitignore "$LIST/"

INDEX=$(login)

if [ $# -lt 1 ]; then
  getArchives "$INDEX"
else
  if ! echo "$INDEX" | grep "$1.txt.gz" > /dev/null; then
    cat <<EOF
Can't find $1.txt.gz..
Check if it appears in the \"Downloadable version\" column at
  $BASEURL/$LIST/
EOF
    exit 1
  fi
  getArchive "${1}.txt.gz"
fi
