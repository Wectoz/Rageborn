#!/usr/bin/env bash
# Copies the addon into the WoW Forever AddOns folder (with the probe while it exists), and
# into the Classic Era one when that client is installed.
set -e
cd "$(dirname "$0")"
WOW="/mnt/c/Program Files (x86)/World of Warcraft"
DEST="$WOW/_forever_/Interface/AddOns"
ERA="$WOW/_classic_era_/Interface/AddOns"
[ -d "$DEST" ] || { echo "AddOns folder not found: $DEST" >&2; exit 1; }
for a in Rageborn RagebornProbe; do
  [ -d "$a" ] || continue
  rm -rf "${DEST:?}/$a"
  cp -r "$a" "$DEST/$a"
  echo "copied $a"
done
if [ -d "$ERA" ]; then
  rm -rf "${ERA:?}/Rageborn"
  cp -r Rageborn "$ERA/Rageborn"
  echo "copied Rageborn (Classic Era)"
fi
