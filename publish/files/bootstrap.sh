#!/usr/bin/env bash
# One-line installer for the Escanor agent (Remote Harness agent). Run on the VM you want to control:
#   curl -fsSL https://www.escanor.in/download/agent | bash
#
# That URL sends you to the newest published copy of this script (release agent-v<version> of
# github.com/escanorlabs-source/escanor-releases). The published copy has its version and the SHA-256 of its agent download
# written in below by scripts/release-agent.sh. It downloads that agent, checks the SHA-256, installs its dependencies in a
# staging folder, and only then swaps it into $REMOTE_HARNESS_DIR (default ~/remote-harness-for-vms, where earlier installs live,
# so their settings and data carry over) and runs packages/agent/install.sh, which asks the setup questions and installs the
# systemd service. If anything fails, an earlier install is put back exactly as it was and its service keeps running.
#
# The checksum comes from the same release as the download: it catches corrupt or partial downloads, not a compromised
# release. Review the script first if that matters to you: curl -fsSL https://www.escanor.in/download/agent -o bootstrap.sh
#
# The source repository is private: nothing here clones it.
set -euo pipefail

AGENT_VERSION_BAKED="0.19.9"
AGENT_SHA256_BAKED="ede5796b8548410d6fb9fce6a15deb40736ed55ed5fea9e784256f62eaa6e83d"
DOWNLOADS="https://github.com/escanorlabs-source/escanor-releases/releases/download"
INSTALL_DIR="${REMOTE_HARNESS_DIR:-$HOME/remote-harness-for-vms}"
# Pin another published version with ESCANOR_AGENT_VERSION=0.9.5; its checksum then comes from that release.
VERSION="${ESCANOR_AGENT_VERSION:-$AGENT_VERSION_BAKED}"

if [ "$AGENT_VERSION_BAKED" = "__AGENT_VERSION__" ] && [ -z "${ESCANOR_AGENT_VERSION:-}" ]; then
  echo "This is the unpublished copy of the installer. Use: curl -fsSL https://www.escanor.in/download/agent | bash" >&2
  exit 1
fi
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "ESCANOR_AGENT_VERSION must look like 0.9.5" >&2; exit 1; }

for tool in curl tar gzip npm; do
  command -v "$tool" >/dev/null 2>&1 || { echo "$tool is required. Install it (e.g. 'sudo apt install $tool') and re-run." >&2; exit 1; }
done
if command -v sha256sum >/dev/null 2>&1; then sha() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
else echo "sha256sum (coreutils) is required." >&2; exit 1; fi
if ! command -v node >/dev/null 2>&1 || [ "$(node -e 'console.log(process.versions.node.split(".")[0])')" -lt 20 ]; then
  echo "Node.js 20+ is required. Install it (e.g. via nvm or NodeSource) and re-run. Nothing was changed." >&2
  exit 1
fi

NAME="escanor-agent-$VERSION"
URL="$DOWNLOADS/agent-v$VERSION/$NAME.tar.gz"
# Staged next to the install folder, so moving the settings, data and the new copy into place never crosses filesystems.
mkdir -p "$(dirname "$INSTALL_DIR")"
WORK="$(mktemp -d "$(dirname "$INSTALL_DIR")/.escanor-agent.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT  # replaced by one that can also restore, once something has been moved

echo "==> Downloading the Escanor agent $VERSION"
curl -fsSL --retry 3 -o "$WORK/$NAME.tar.gz" "$URL"
if [ "$VERSION" = "$AGENT_VERSION_BAKED" ]; then
  WANT="$AGENT_SHA256_BAKED"
else
  WANT="$(curl -fsSL --retry 3 "$URL.sha256" | cut -d' ' -f1)"
fi
GOT="$(sha "$WORK/$NAME.tar.gz")"
if [ "$GOT" != "$WANT" ]; then
  echo "Checksum mismatch for $NAME.tar.gz (expected $WANT, got $GOT). Nothing was installed." >&2
  exit 1
fi
echo "    SHA-256 $GOT OK"

mkdir -p "$WORK/new"
tar -xzf "$WORK/$NAME.tar.gz" -C "$WORK/new" --strip-components=1
NEW="$WORK/new"
AGENT_REL=packages/agent

# Dependencies go into the staging copy first: if npm fails (no network, wrong Node), nothing installed has been touched.
echo "==> Installing dependencies"
(cd "$NEW" && npm ci --no-fund --no-audit --workspace=@remote-harness/agent --workspace=@remote-harness/shared)
[ -x "$NEW/node_modules/.bin/tsx" ] || { echo "Dependencies did not install. Nothing was changed." >&2; exit 1; }
printf '%s\n' "$VERSION" > "$NEW/.escanor-agent-version"

PREV="$INSTALL_DIR.previous"
FAILED="$INSTALL_DIR.failed"
STEP=0  # 1 data moved into the new copy, 2 earlier install moved to $PREV, 3 new copy in place
# Put an earlier install back exactly as it was: its folder, settings and data. Its service never stopped (install.sh restarts
# it only as its very last step), so it carries on as before.
restore() {
  [ "$STEP" -gt 0 ] || return 0
  echo "==> Install failed: putting the earlier install back" >&2
  local data="$NEW/$AGENT_REL/data"
  if [ "$STEP" -ge 3 ]; then rm -rf "$FAILED"; mv "$INSTALL_DIR" "$FAILED"; data="$FAILED/$AGENT_REL/data"; fi
  if [ "$STEP" -ge 2 ]; then mv "$PREV" "$INSTALL_DIR"; fi
  if [ -e "$data" ]; then rm -rf "$INSTALL_DIR/$AGENT_REL/data"; mv "$data" "$INSTALL_DIR/$AGENT_REL/data"; fi
  echo "    restored $INSTALL_DIR" >&2
}
FRESH=1
trap 'rc=$?; if [ "$rc" -ne 0 ] && [ "$FRESH" = 0 ]; then restore || true; fi; rm -rf "$WORK"' EXIT

if [ -e "$INSTALL_DIR" ]; then
  FRESH=0
  # Settings are copied (the earlier install keeps its own); the data folder moves, because the running agent writes to it.
  if [ -f "$INSTALL_DIR/$AGENT_REL/.env" ]; then cp -p "$INSTALL_DIR/$AGENT_REL/.env" "$NEW/$AGENT_REL/.env"; fi
  rm -rf "$PREV"
  echo "==> Swapping in $VERSION (the earlier install is kept as $PREV)"
  if [ -e "$INSTALL_DIR/$AGENT_REL/data" ]; then mv "$INSTALL_DIR/$AGENT_REL/data" "$NEW/$AGENT_REL/data"; fi
  STEP=1
  mv "$INSTALL_DIR" "$PREV"; STEP=2
else
  echo "==> Installing into $INSTALL_DIR"
fi
mv "$NEW" "$INSTALL_DIR"; STEP=3

echo "==> Installing Escanor agent $VERSION"
ESCANOR_AGENT_DEPS_READY=1 "$INSTALL_DIR/packages/agent/install.sh"
FRESH=1  # done: nothing to restore
