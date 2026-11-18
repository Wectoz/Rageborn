#!/usr/bin/env bash
# Copies the addon folders into the WoW Forever AddOns folder.
set -e
cd "$(dirname "$0")"
DEST="/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns"
[ -d "$DEST" ] || { echo "AddOns folder not found: $DEST" >&2; exit 1; }
for a in Rageborn RagebornProbe; do
  [ -d "$a" ] || continue
  rm -rf "${DEST:?}/$a"
  cp -r "$a" "$DEST/$a"
  echo "copied $a"
done
