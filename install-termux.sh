#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# install-termux.sh - instala o OpenCode modificado (com suporte à VibeBridge)
# no Termux (Android) ou em qualquer Linux (Debian/Ubuntu/ARM) com UM comando:
#
#   curl -fsSL https://raw.githubusercontent.com/deivid22srk/opencode-termux/dev/install-termux.sh | bash
#
# O script é IDEMPOTENTE: pode rodar quantas vezes quiser - ele atualiza uma
# instalação existente em vez de quebrar.
#
# O que ele faz:
#   1. Atualiza pacotes (Termux) e instala git, curl, unzip, ripgrep e bash;
#   2. Instala o Bun oficial para Android aarch64 (ou para o seu Linux);
#   3. Clona este repositório (shallow) em ~/opencode-termux (ou atualiza);
#   4. Instala as dependências com `bun install` (roda direto do fonte - não
#      é preciso compilar binário);
#   5. Cria o comando `opencode` no PATH ($PREFIX/bin no Termux);
#   6. Mostra como subir o servidor para conectar a VibeBridge.
#
# Variáveis de ambiente opcionais:
#   REPO_URL      (padrão: https://github.com/deivid22srk/opencode-termux.git)
#   REPO_BRANCH   (padrão: dev)
#   INSTALL_DIR   (padrão: $HOME/opencode-termux)
#   BUN_VERSION   (padrão: 1.3.14 - a mesma do packageManager do projeto)

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/deivid22srk/opencode-termux.git}"
REPO_BRANCH="${REPO_BRANCH:-dev}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/opencode-termux}"
BUN_VERSION="${BUN_VERSION:-1.3.14}"

# ── utilidades de saída ──────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_INFO=$'\033[1;36m'; C_OK=$'\033[1;32m'; C_WARN=$'\033[1;33m'; C_ERR=$'\033[1;31m'; C_OFF=$'\033[0m'
else
  C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_OFF=""
fi
info() { printf '%s[install]%s %s\n'  "$C_INFO" "$C_OFF" "$*"; }
ok()   { printf '%s[ok]%s     %s\n'   "$C_OK"   "$C_OFF" "$*"; }
warn() { printf '%s[aviso]%s  %s\n'   "$C_WARN" "$C_OFF" "$*"; }
fail() { printf '%s[erro]%s   %s\n'   "$C_ERR"  "$C_OFF" "$*" >&2; }

trap 'fail "A instalação falhou na linha $LINENO. Leia a mensagem acima e rode o script novamente para retomar."' ERR

# ── detecção de ambiente ─────────────────────────────────────────────────────
IS_TERMUX=false
case "${PREFIX:-}" in *com.termux*) IS_TERMUX=true ;; esac
[[ -n "${TERMUX_VERSION:-}" ]] && IS_TERMUX=true

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) BUN_ARCH="aarch64" ;;
  x86_64|amd64)  BUN_ARCH="x64" ;;
  *) fail "Arquitetura não suportada pelo Bun: $ARCH (use aarch64 ou x86_64)."; exit 1 ;;
esac

if $IS_TERMUX; then
  BUN_TARGET="bun-linux-${BUN_ARCH}-android"   # build oficial do Bun para Android/Termux
  BIN_DIR="${PREFIX}/bin"
else
  BUN_TARGET="bun-linux-${BUN_ARCH}"           # build glibc padrão (Debian/Ubuntu)
  BIN_DIR="${HOME}/.local/bin"
  mkdir -p "$BIN_DIR"
fi

info "Ambiente: $([[ $IS_TERMUX == true ]] && echo "Termux (Android)" || echo "Linux") · arquitetura ${ARCH} · destino ${INSTALL_DIR}"

# ── verificação prévia: curl/git precisam do libcurl funcionando ────────────
# Sintoma clássico de Termux com pacotes dessincronizados: o libcurl foi
# compilado contra um OpenSSL mais novo que o instalado e QUALQUER binário
# que o carregue (curl, git) falha com "CANNOT LINK EXECUTABLE ... cannot
# locate symbol ...". Detectamos isso AGORA, com mensagem clara, em vez de
# falhar no meio da instalação.
if $IS_TERMUX && command -v curl >/dev/null 2>&1; then
  if ! curl --version >/dev/null 2>&1; then
    fail "O curl do seu Termux está quebrado (erro de linkagem libcurl/OpenSSL)."
    printf '%s\n' \
      "Conserte o ambiente antes de rodar este instalador:" \
      "  termux-change-repo                  # selecione um mirror" \
      "  apt update && apt full-upgrade -y   # sincroniza libcurl/libopenssl" \
      "  curl --version                      # deve funcionar agora" \
      "Detalhes: seção 'Problemas comuns no Termux' do README." >&2
    exit 1
  fi
fi

# ── 1. dependências do sistema ───────────────────────────────────────────────
if $IS_TERMUX; then
  info "Atualizando pacotes do Termux (pkg update)…"
  pkg update -y || warn "pkg update falhou — causa mais comum: mirror ausente/quebrado. Rode 'termux-change-repo', selecione um mirror e rode este script de novo. Seguindo com os índices existentes."
  info "Atualizando pacotes instalados (pkg upgrade)…"
  DEBIAN_FRONTEND=noninteractive pkg upgrade -y || warn "pkg upgrade falhou (pode haver pacotes retidos). Se o curl estiver quebrado, rode manualmente: apt update && apt full-upgrade -y — depois rode este script de novo. Seguindo mesmo assim."
  info "Instalando git, curl, unzip, ripgrep e bash…"
  pkg install -y git curl unzip ripgrep bash
else
  for cmd in git curl unzip tar; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      if command -v apt-get >/dev/null 2>&1 && { [[ $EUID -eq 0 ]] || command -v sudo >/dev/null 2>&1; }; then
        info "Instalando dependência ausente: $cmd (apt-get)…"
        if [[ $EUID -eq 0 ]]; then apt-get update -y && apt-get install -y "$cmd"; else sudo apt-get update -y && sudo apt-get install -y "$cmd"; fi
      else
        fail "Dependência ausente: '$cmd'. Instale-a manualmente e rode o script de novo."
        exit 1
      fi
    fi
  done
  # ripgrep é usado pelas ferramentas de busca do OpenCode (o binário
  # pré-compilado baixado automaticamente é glibc e NÃO roda no Android).
  if ! command -v rg >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
    info "Instalando ripgrep (usado pelas ferramentas de busca do OpenCode)…"
    if [[ $EUID -eq 0 ]]; then apt-get install -y ripgrep; else sudo apt-get install -y ripgrep || true; fi
  fi
fi
ok "Dependências do sistema prontas."

# ── 2. Bun (runtime exigido pelo projeto) ────────────────────────────────────
BUN_BIN="$(command -v bun || true)"
if [[ -n "$BUN_BIN" ]] && [[ "$(bun --version 2>/dev/null)" == "$BUN_VERSION"* ]]; then
  ok "Bun $(bun --version) já instalado ($BUN_BIN)."
else
  TMP="$(mktemp -d)"
  URL="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/${BUN_TARGET}.zip"
  info "Baixando Bun ${BUN_VERSION} (${BUN_TARGET})…"
  curl -fL --retry 3 --progress-bar "$URL" -o "$TMP/bun.zip"
  info "Instalando Bun em ${BIN_DIR}…"
  unzip -oq "$TMP/bun.zip" -d "$TMP/bun"
  mkdir -p "$BIN_DIR"
  install -m 0755 "$TMP/bun/${BUN_TARGET}/bun" "$BIN_DIR/bun"
  ln -sf "$BIN_DIR/bun" "$BIN_DIR/bunx" 2>/dev/null || true
  rm -rf "$TMP"
  BUN_BIN="$BIN_DIR/bun"
  ok "Bun $("$BUN_BIN" --version) instalado."
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "$BIN_DIR não está no PATH. Adicione ao seu ~/.bashrc:  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

# ── 3. clonar / atualizar o repositório ──────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
  info "Repositório já existe em $INSTALL_DIR - atualizando…"
  git -C "$INSTALL_DIR" fetch --depth 1 origin "$REPO_BRANCH" || warn "fetch falhou (sem internet?); usando o código já baixado."
  git -C "$INSTALL_DIR" pull --ff-only origin "$REPO_BRANCH" \
    || warn "Não foi possível avançar (pull --ff-only). A instalação continua com o código existente; se quiser forçar, remova a pasta e rode de novo."
else
  info "Clonando $REPO_URL (branch $REPO_BRANCH, shallow)…"
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi
ok "Código pronto em $INSTALL_DIR."

# ── 4. dependências do projeto ───────────────────────────────────────────────
info "Instalando dependências com bun install (pode demorar alguns minutos; ~1,5 GB de disco)…"
git -C "$INSTALL_DIR" config --global --add safe.directory "$INSTALL_DIR" 2>/dev/null || true
(cd "$INSTALL_DIR" && "$BUN_BIN" install)
ok "Dependências instaladas."

# ── 5. comando `opencode` no PATH ────────────────────────────────────────────
WRAPPER="$BIN_DIR/opencode"
info "Criando comando \`opencode\` em $WRAPPER…"
{
  echo '#!/usr/bin/env bash'
  echo '# gerado por install-termux.sh - OpenCode (fork deivid22srk/opencode-termux)'
  echo "export PATH=\"$BIN_DIR:\$PATH\""
  echo "exec \"$BUN_BIN\" run --cwd \"$INSTALL_DIR/packages/opencode\" src/index.ts \"\$@\""
} > "$WRAPPER"
chmod +x "$WRAPPER"
ok "Comando criado."

# ── 6. validação ─────────────────────────────────────────────────────────────
info "Validando a instalação…"
OC_VERSION="$("$WRAPPER" --version 2>/dev/null || echo "desconhecida")"
ok "OpenCode instalado (versão: $OC_VERSION)."

if command -v rg >/dev/null 2>&1; then
  ok "ripgrep encontrado em $(command -v rg) (busca do agente funcionará)."
else
  warn "ripgrep NÃO encontrado: as ferramentas de busca do OpenCode falharão. Instale com: pkg install ripgrep"
fi

# ── 7. instruções finais ─────────────────────────────────────────────────────
cat <<FIM

${C_OK}══════════════════════════════════════════════════════════════════${C_OFF}
 ${C_OK}OpenCode instalado com sucesso!${C_OFF}

 1) Inicie o servidor (deixe esta sessão do Termux aberta):

      opencode serve --port 4096

    (opcional, recomendado se estiver na mesma rede: proteja o servidor)
      OPENCODE_SERVER_PASSWORD="uma-senha" opencode serve --port 4096 --hostname 0.0.0.0

 2) No navegador (PC ou no próprio celular), na extensão VibeBridge:
    - clique no ícone da extensão → "▲ OpenCode panel"
    - em "⚙ Server", confirme a URL (ex.: http://127.0.0.1:4096 se o
      OpenCode roda no mesmo aparelho; ou http://IP-DO-CELULAR:4096)
    - se usar senha, preencha o campo "Password"
    - em "Project directory", informe a pasta do seu projeto no aparelho
      (ex.: /data/data/com.termux/files/home/meu-projeto)

 3) Atualizar depois é só rodar este script de novo - ele é idempotente.

 Observações:
  - O OpenCode roda aqui direto do fonte com o Bun oficial para Android.
  - Recursos de terminal interativo (PTY) do OpenCode podem não funcionar
    no Android (limitação do bun-pty); as ferramentas bash/edição funcionam.
  - Se algo falhar, rode o script novamente - ele retoma do ponto onde parou.
${C_OK}══════════════════════════════════════════════════════════════════${C_OFF}
FIM
