#!/usr/bin/env bash

set -euo pipefail

. ./mailman.conf

COOKIEJAR="cookies.txt"
LISTURL="$BASEURL/$LIST"

function gitignore() {
  if ! grep "$1" .gitignore > /dev/null; then
    echo "$1" >> .gitignore
  fi
}

function getIndex() {
  # Don't attempt to re-login if login happened less than 30 minutes ago:
  if [ -f "$COOKIEJAR" ] && find "$COOKIEJAR" -mmin -30 > /dev/null; then
    curl --silent \
      --cookie "$COOKIEJAR" \
      "$LISTURL"
  else
    curl --silent \
      --data "username=${USER}&password=${PASSWORD}" \
      --cookie-jar "$COOKIEJAR" \
      "$LISTURL"
  fi
}

function getFile() {
  FILE=$1

  # Create directory substructure:
  install -D /dev/null "$LIST/$FILE"

  # Get the file if it is stale:
  curl --cookie "$COOKIEJAR" \
    -o "$LIST/$FILE" \
    -z "$LIST/$FILE" \
    --remote-time \
    "$LISTURL/$FILE"
}

function foreach() {
  local STREAM="$1"
  local RE="$2"
  local DO="$3"

  local Ms=$(echo "$STREAM" | grep "$RE" | sed "s/.*${RE}.*/\1/")
  echo "$Ms" | while read M; do
    $DO "$M"
  done
}

function getArchive() {
  getFile "$1"
  getAttachments "$(cat "$LIST/$1")"
}

function getArchives() {
  foreach "$1" \
    "\([0-9]\{4\}-[A-Z][a-z]\\+\\.txt\\.gz\)" \
    getArchive
}

function getAttachments() {
  foreach "$1" \
    "$LIST\\/\(attachments\\/[0-9]\{8\}\\/.*\)>" \
    getFile
}

gitignore "$COOKIEJAR"
gitignore "$LIST"

INDEX=$(getIndex)

if [ $# -lt 1 ]; then
  getArchives "$INDEX"
else
  getArchive "$1.txt.gz"
fi
