#!/usr/bin/env bash
# Terra vs Astra on one proc (Execute, legacy look): the same brief and the same effort
# (high) through both models. Astra's arm is the art in ../legacy/execute; this runs
# Terra's arm with that run's exact prompt, into terra/.
cd "$(dirname "$0")"
[ -f ../legacy/execute/prompt.txt ] || { echo "run ../legacy/run.sh execute first"; exit 1; }
mkdir -p terra && cp ../legacy/execute/prompt.txt terra/prompt.txt
( cd terra && timeout 2400 codex exec --skip-git-repo-check -s workspace-write -m gpt-6.1-terra -c model_reasoning_effort='"high"' - < prompt.txt > codex.log 2>&1; echo "codex exit $?" >> codex.log )
echo "terra: $(ls terra/*.png 2>/dev/null | wc -l) images"
