#!/usr/bin/env bash
# Sets up this project on macOS (also works on Linux, which has no Roblox Studio).
# Installs Rokit when it is missing, installs the tools pinned in rokit.toml (Rojo, Selene,
# StyLua, Wally), installs the Rojo plugin for Roblox Studio and the recommended VS Code
# extensions, builds the place to check the project, and can start `rojo serve`.
# Safe to run again: each step skips what is already in place.
#
# Usage: bash tools/setup.sh [--no-serve]
set -euo pipefail

serve=true
for arg in "$@"; do
	case "$arg" in
	--no-serve) serve=false ;;
	-h | --help)
		sed -n '2,8p' "$0"
		exit 0
		;;
	*)
		echo "unknown option: $arg (use --help)" >&2
		exit 2
		;;
	esac
done

repo_url="https://github.com/ddmelo0104/roblox-rpg-game"
rokit_installer="https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh"
rokit_bin="$HOME/.rokit/bin"
place_file="roblox-rpg-game.rbxl"

step() { printf '\n==> %s\n' "$1"; }
ok() { printf '    ok: %s\n' "$1"; }
warn() { printf '    warning: %s\n' "$1"; }
has() { command -v "$1" >/dev/null 2>&1; }

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
echo "Setting up $project_root"

# Tools installed by Rokit live here; the installer only adds it to PATH for new terminals.
case ":$PATH:" in
*":$rokit_bin:"*) ;;
*) export PATH="$rokit_bin:$PATH" ;;
esac

# 1. Git: needed to receive updates and send changes; the game itself runs without it.
step "Git"
if has git && git --version >/dev/null 2>&1; then
	ok "$(git --version)"
	if [ ! -e "$project_root/.git" ]; then
		warn "this folder is not a git clone; to receive updates, clone $repo_url instead"
	fi
else
	warn "Git is not installed; on macOS, run: xcode-select --install"
fi

# 2. Rokit, the tool manager of the project.
step "Rokit (tool manager)"
if ! has rokit; then
	echo "    installing Rokit..."
	curl -sSf "$rokit_installer" | bash
fi
if ! has rokit; then
	echo "Rokit is still missing after the install. Open a new terminal and run this script again." >&2
	exit 1
fi
ok "$(rokit --version)"

# 3. The tools pinned in rokit.toml.
step "Project tools (rokit.toml)"
if ! rokit install --no-trust-check; then
	warn 'retrying without --no-trust-check; answer "y" if Rokit asks to trust a tool'
	rokit install
fi
for tool in rojo selene stylua; do
	if ! has "$tool"; then
		echo "$tool was not installed by Rokit." >&2
		exit 1
	fi
done
ok "$(rojo --version)"

# 4. The Rojo plugin, which connects Roblox Studio to `rojo serve`.
step "Rojo plugin for Roblox Studio"
if rojo plugin install; then
	ok "installed (restart Roblox Studio if it is open)"
else
	warn 'could not install it; inside Studio, get "Rojo" from the Creator Store instead'
fi

# 5. Building the place checks default.project.json and every file under src/.
step "Build the place"
rojo build -o "$place_file"
ok "$place_file"

# 6. Editor extensions recommended by the project.
step "VS Code extensions (.vscode/extensions.json)"
if has code; then
	extensions="$(grep -oE '"[A-Za-z0-9-]+\.[A-Za-z0-9-]+"' .vscode/extensions.json | tr -d '"' || true)"
	for id in $extensions; do
		code --install-extension "$id" --force >/dev/null
	done
	ok "$(echo "$extensions" | paste -sd ',' - | sed 's/,/, /g')"
else
	warn 'VS Code was not found (the "code" command); skipping'
fi

# 7. Python only regenerates docs/planejamento/BACKLOG.md; the game does not need it.
step "Python (only for tools/backlog.py)"
if has python3; then
	ok "$(python3 --version)"
else
	warn "not found; only needed to regenerate the backlog"
fi

# 8. Roblox Studio itself.
step "Roblox Studio"
if [ -d "/Applications/RobloxStudio.app" ] || [ -d "$HOME/Applications/RobloxStudio.app" ]; then
	ok "found"
else
	warn "not found; install it from https://create.roblox.com (macOS or Windows only)"
fi

step "Done"
cat <<'EOF'
Next steps:
  1. Open Roblox Studio and create a place from the Baseplate template.
  2. Plugins tab > Rojo > Connect (default address: localhost:34872).
  3. Press Play. The Output shows "[Main] server ok" and "[Main] client ok".
  The test steps of each story are in docs/planejamento/historias.
EOF

if [ "$serve" = true ]; then
	printf 'Start "rojo serve" now? [Y/n] '
	read -r answer || answer="n"
	case "$answer" in
	[nN]*) ;;
	*)
		echo "Serving the project. Keep this terminal open while you use Studio; Ctrl+C stops it."
		exec rojo serve
		;;
	esac
fi
