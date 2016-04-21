#!/usr/bin/env bash

set -euo pipefail

showUsage () {
  cat <<EOF
Usage: $0 [-h|--help] [YYYY-MMMM]

Examples:
  \$ $0 2015-March
  \$ $0 2016-January
  \$ $0
EOF
}

showHelp () {
  echo ""
  showUsage
  echo ""
  cat <<EOF
Downloads the mailman2 archive described in mailman.conf together with the
(optional) year and month command-line argument. The archive will be downloaded
to \$LIST under current working directory where LIST is specified in
mailman.conf. Here is a sample mailman.conf:

  # -*- mode: conf-mode -*-
  # vim: set ft=config

  BASEURL="https://ourmailmandomain.org/mailman/private"
  LIST="ourmailinglist"
  USERNAME="mymail@mydomain.org"
  PASSWORD="password123"
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help )
      showHelp
      exit 0
      ;;
    * )
      break
      ;;
  esac
done

if [ ! -f "mailman.conf" ]; then
  echo "Missing a mailman.conf in working directory."
  showHelp
  exit 1
fi

. ./mailman.conf

if [ -z "$BASEURL" ]; then
  echo "BASEURL missing in mailman.conf"
  showHelp
  exit 1
fi

if [ -z "$LIST" ]; then
  echo "LIST missing in mailman.conf"
  showHelp
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "USERNAME missing in mailman.conf"
  showHelp
  exit 1
fi

if [ -z "$PASSWORD" ]; then
  echo "PASSWORD missing in mailman.conf"
  showHelp
  exit 1
fi

COOKIEJAR="cookies.txt"
LISTURL="$BASEURL/$LIST"

gitignore() {
  if ! grep "$1" .gitignore > /dev/null; then
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
  file=$1

  # Create directory substructure:
  install -D /dev/null "$LIST/$file"

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

gitignore "$COOKIEJAR"
gitignore "$LIST"

INDEX=$(login)

if [ $# -lt 1 ]; then
  getArchives "$INDEX"
else
  getArchive "$1.txt.gz"
fi
