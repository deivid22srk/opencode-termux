<p align="center">
  <a href="https://opencode.ai">
    <picture>
      <source srcset="packages/console/app/src/asset/logo-ornate-dark.svg" media="(prefers-color-scheme: dark)">
      <source srcset="packages/console/app/src/asset/logo-ornate-light.svg" media="(prefers-color-scheme: light)">
      <img src="packages/console/app/src/asset/logo-ornate-light.svg" alt="OpenCode logo">
    </picture>
  </a>
</p>
<p align="center">The open source AI coding agent.</p>
<p align="center">
  <a href="https://opencode.ai/discord"><img alt="Discord" src="https://img.shields.io/discord/1391832426048651334?style=flat-square&label=discord" /></a>
  <a href="https://www.npmjs.com/package/opencode-ai"><img alt="npm" src="https://img.shields.io/npm/v/opencode-ai?style=flat-square" /></a>
  <a href="https://github.com/anomalyco/opencode/actions/workflows/publish.yml"><img alt="Build status" src="https://img.shields.io/github/actions/workflow/status/anomalyco/opencode/publish.yml?style=flat-square&branch=dev" /></a>
</p>

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.zh.md">简体中文</a> |
  <a href="README.zht.md">繁體中文</a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.de.md">Deutsch</a> |
  <a href="README.es.md">Español</a> |
  <a href="README.fr.md">Français</a> |
  <a href="README.it.md">Italiano</a> |
  <a href="README.da.md">Dansk</a> |
  <a href="README.ja.md">日本語</a> |
  <a href="README.pl.md">Polski</a> |
  <a href="README.ru.md">Русский</a> |
  <a href="README.bs.md">Bosanski</a> |
  <a href="README.ar.md">العربية</a> |
  <a href="README.no.md">Norsk</a> |
  <a href="README.br.md">Português (Brasil)</a> |
  <a href="README.th.md">ไทย</a> |
  <a href="README.tr.md">Türkçe</a> |
  <a href="README.uk.md">Українська</a> |
  <a href="README.bn.md">বাংলা</a> |
  <a href="README.gr.md">Ελληνικά</a> |
  <a href="README.vi.md">Tiếng Việt</a>
</p>

[![OpenCode Terminal UI](packages/web/src/assets/lander/screenshot.png)](https://opencode.ai)

---

### Installation

```bash
# YOLO
curl -fsSL https://opencode.ai/install | bash

# Package managers
npm i -g opencode-ai@latest        # or bun/pnpm/yarn
scoop install opencode             # Windows
choco install opencode             # Windows
brew install anomalyco/tap/opencode # macOS and Linux (recommended, always up to date)
brew install opencode              # macOS and Linux (official brew formula, updated less)
sudo pacman -S opencode            # Arch Linux (Stable)
paru -S opencode-bin               # Arch Linux (Latest from AUR)
mise use -g opencode               # Any OS
nix run nixpkgs#opencode           # or github:anomalyco/opencode for latest dev branch
```

> [!TIP]
> Remove versions older than 0.1.x before installing.

### Installation on Termux (Android)

This fork ships an idempotent one-command installer for Termux that installs Bun
(official Android build), clones the repository, installs dependencies, and puts
the `opencode` command on your `$PATH`:

```bash
pkg install -y curl && curl -fsSL https://raw.githubusercontent.com/deivid22srk/opencode-termux/dev/install-termux.sh | bash
```

The installer downloads a **ready-made bundle from GitHub Actions** (source +
already-installed dependencies — nothing is compiled or resolved on the device,
which also avoids the `EACCES: failed to link package` that `bun install` hits
on Android). If the bundle is unavailable it falls back to source mode with
`bun install --backend=copyfile` on Termux.

After it finishes, start the server (needed for the [VibeBridge](https://github.com/deivid22srk/VibeBridge) extension and other HTTP clients):

```bash
OPENCODE_TOOL_API=1 opencode serve --port 4096
# optionally protect it when exposing to your LAN:
OPENCODE_SERVER_PASSWORD="your-password" OPENCODE_TOOL_API=1 opencode serve --port 4096 --hostname 0.0.0.0
```

`OPENCODE_TOOL_API=1` enables the direct tool API (`GET /tool`,
`POST /tool/:name`) used by VibeBridge's **site-driven agent mode**: you chat
through the DeepSeek/ChatGPT/Gemini etc. UI and the tools (read, write, edit,
bash...) execute here, as if the site's model were a native OpenCode model.
See the [VibeBridge](https://github.com/deivid22srk/VibeBridge) README.

Notes:
- OpenCode runs from source with Bun — no binary compilation required.
- The script is idempotent: run it again to update an existing installation.
- Validated on Linux (x64, Debian); **not yet validated on a real Android/Termux
  device**. Known Android caveats: the interactive terminal (PTY) features may not
  work (`bun-pty` ships no bionic build), and ripgrep is installed via `pkg` because
  the automatically downloaded glibc binary does not run on Android. If you hit an
  issue, re-run the installer — it resumes where it stopped. See `CHANGES.md`.

#### Common Termux problems

**1. `CANNOT LINK EXECUTABLE "curl": cannot locate symbol "SSL_set_quic_tls_early_data_enabled"`**

This is not an installer issue: your Termux `curl` is broken because packages
are out of sync — `libcurl` was built against a newer OpenSSL than the
installed `libopenssl`. Until fixed, **every** program that links libcurl fails
(including `git`, which the installer uses to clone). Fix the environment
first:

```bash
termux-change-repo                   # select a mirror (e.g. Mirror group → All)
apt update && apt full-upgrade -y    # re-syncs libcurl and libopenssl
curl --version                       # should work now
```

Then re-run the install command. If you would rather avoid `curl`, `wget`
doesn't depend on libcurl and fetches the installer just as well:

```bash
pkg install -y wget && wget -qO- https://raw.githubusercontent.com/deivid22srk/opencode-termux/dev/install-termux.sh | bash
```

**2. `No mirror or mirror group selected`**

Termux has no mirror configured — without one `apt` cannot download packages,
which is exactly why problem 1 happens and never self-heals. Run
`termux-change-repo`, pick a mirror from the list, then run `apt update`
again. Non-interactive alternative:

```bash
echo "deb https://packages.termux.dev/apt/termux-main stable main" > "$PREFIX/etc/apt/sources.list"
apt update && apt full-upgrade -y
```

**3. Nothing above helped**

The package state may be too old or inconsistent to fix in place. Back up your
data, uninstall and reinstall the Termux app (current build from
[GitHub](https://github.com/termux/termux-app/releases) or F-Droid — the Play
Store distribution is deprecated), then run the install command in a fresh
environment. The installer also detects this situation up front: if `curl` is
broken it prints the instructions above instead of failing halfway through.

### Desktop App (BETA)

OpenCode is also available as a desktop application. Download directly from the [releases page](https://github.com/anomalyco/opencode/releases) or [opencode.ai/download](https://opencode.ai/download).

| Platform              | Download                           |
| --------------------- | ---------------------------------- |
| macOS (Apple Silicon) | `opencode-desktop-mac-arm64.dmg`   |
| macOS (Intel)         | `opencode-desktop-mac-x64.dmg`     |
| Windows               | `opencode-desktop-windows-x64.exe` |
| Linux                 | `.deb`, `.rpm`, or `.AppImage`     |

```bash
# macOS (Homebrew)
brew install --cask opencode-desktop
# Windows (Scoop)
scoop bucket add extras; scoop install extras/opencode-desktop
```

#### Installation Directory

The install script respects the following priority order for the installation path:

1. `$OPENCODE_INSTALL_DIR` - Custom installation directory
2. `$XDG_BIN_DIR` - XDG Base Directory Specification compliant path
3. `$HOME/bin` - Standard user binary directory (if it exists or can be created)
4. `$HOME/.opencode/bin` - Default fallback

```bash
# Examples
OPENCODE_INSTALL_DIR=/usr/local/bin curl -fsSL https://opencode.ai/install | bash
XDG_BIN_DIR=$HOME/.local/bin curl -fsSL https://opencode.ai/install | bash
```

### Agents

OpenCode includes two built-in agents you can switch between with the `Tab` key.

- **build** - Default, full-access agent for development work
- **plan** - Read-only agent for analysis and code exploration
  - Denies file edits by default
  - Asks permission before running bash commands
  - Ideal for exploring unfamiliar codebases or planning changes

Also included is a **general** subagent for complex searches and multistep tasks.
This is used internally and can be invoked using `@general` in messages.

Learn more about [agents](https://opencode.ai/docs/agents).

### Documentation

For more info on how to configure OpenCode, [**head over to our docs**](https://opencode.ai/docs).

### Contributing

If you're interested in contributing to OpenCode, please read our [contributing docs](./CONTRIBUTING.md) before submitting a pull request.

### Building on OpenCode

If you are working on a project that's related to OpenCode and is using "opencode" as part of its name, for example "opencode-dashboard" or "opencode-mobile", please add a note to your README to clarify that it is not built by the OpenCode team and is not affiliated with us in any way.

---

**Join our community** [Discord](https://discord.gg/opencode) | [X.com](https://x.com/opencode)
