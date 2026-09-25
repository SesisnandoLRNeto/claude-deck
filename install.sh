#!/usr/bin/env bash
# Install claude-deck with its own Python environment.
#
# Homebrew's Python (and most Linux distributions) refuse `pip install` into the system
# interpreter (PEP 668), and a deck that depends on whatever `python3` happens to be first
# on PATH breaks the day that changes. So the deck gets a private virtualenv, and the
# `claude-deck` command is a small launcher that always uses it. Safe to run again.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
VENV="${CLAUDE_DECK_VENV:-$HOME/.local/share/claude-deck/venv}"
BIN="$HOME/.local/bin"
PY="${PYTHON:-python3}"

command -v "$PY" >/dev/null || { echo "claude-deck: $PY not found"; exit 1; }

if [ ! -x "$VENV/bin/python" ]; then
  echo "venv   -> $VENV"
  "$PY" -m venv "$VENV"
fi
"$VENV/bin/python" -m pip install -q --upgrade pip
"$VENV/bin/python" -m pip install -q -r "$REPO/requirements.txt"
"$VENV/bin/python" -c "import textual, rich; print('deps   -> textual', textual.__version__, '· rich ok')"

mkdir -p "$BIN"
rm -f "$BIN/claude-deck"            # an older install may have left a symlink or a copy here
cat > "$BIN/claude-deck" <<EOF
#!/usr/bin/env bash
# claude-deck launcher: always the deck's own virtualenv, never the system python.
exec "$VENV/bin/python" "$REPO/claude-deck" "\$@"
EOF
chmod +x "$BIN/claude-deck"
echo "cli    -> $BIN/claude-deck"
[[ ":$PATH:" == *":$BIN:"* ]] || echo "       ! $BIN is not on your PATH; add it to your shell profile"
echo "done. Run: claude-deck"
