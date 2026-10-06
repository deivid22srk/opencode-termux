<p align="center">
  <a href="https://opencode.ai">
    <picture>
      <source srcset="packages/console/app/src/asset/logo-ornate-dark.svg" media="(prefers-color-scheme: dark)">
      <source srcset="packages/console/app/src/asset/logo-ornate-light.svg" media="(prefers-color-scheme: light)">
      <img src="packages/console/app/src/asset/logo-ornate-light.svg" alt="Logo do OpenCode">
    </picture>
  </a>
</p>
<p align="center">O agente de programação com IA de código aberto.</p>
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

### Instalação

```bash
# YOLO
curl -fsSL https://opencode.ai/install | bash

# Gerenciadores de pacotes
npm i -g opencode-ai@latest        # ou bun/pnpm/yarn
scoop install opencode             # Windows
choco install opencode             # Windows
brew install anomalyco/tap/opencode # macOS e Linux (recomendado, sempre atualizado)
brew install opencode              # macOS e Linux (fórmula oficial do brew, atualiza menos)
sudo pacman -S opencode            # Arch Linux (Stable)
paru -S opencode-bin               # Arch Linux (Latest from AUR)
mise use -g opencode               # qualquer sistema
nix run nixpkgs#opencode           # ou github:anomalyco/opencode para a branch dev mais recente
```

> [!TIP]
> Remova versões anteriores a 0.1.x antes de instalar.

### Instalação no Termux (Android)

Este fork inclui um instalador de comando único e idempotente para o Termux, que
instala o Bun (build oficial para Android), clona o repositório, instala as
dependências e deixa o comando `opencode` disponível no PATH:

```bash
pkg install -y curl && curl -fsSL https://raw.githubusercontent.com/deivid22srk/opencode-termux/dev/install-termux.sh | bash
```

O instalador baixa um **bundle pronto do GitHub Actions** (fonte + dependências
já instaladas — nada é compilado ou resolvido no aparelho, o que também evita o
`EACCES: failed to link package` do `bun install` no Android). Se o bundle não
estiver disponível, ele cai automaticamente para o modo fonte, com
`bun install --backend=copyfile` no Termux.

Ao terminar, inicie o servidor (necessário para a extensão
[VibeBridge](https://github.com/deivid22srk/VibeBridge) e outros clientes HTTP):

```bash
OPENCODE_TOOL_API=1 opencode serve --port 4096
# opcional: proteja o servidor se ele ficar visível na sua rede
OPENCODE_SERVER_PASSWORD="uma-senha" OPENCODE_TOOL_API=1 opencode serve --port 4096 --hostname 0.0.0.0
```

`OPENCODE_TOOL_API=1` habilita a API direta de ferramentas (`GET /tool`,
`POST /tool/:name`) usada pelo **modo agente em sites** da VibeBridge: você
conversa pela própria interface do DeepSeek/ChatGPT/Gemini etc. e as
ferramentas (ler, escrever, editar, bash...) executam aqui, como se o modelo do
site fosse um modelo nativo do OpenCode. Veja o README da
[VibeBridge](https://github.com/deivid22srk/VibeBridge).

Observações:
- O OpenCode roda direto do fonte com o Bun — não é preciso compilar binário.
- O script é idempotente: rode de novo para atualizar uma instalação existente.
- Validado em Linux (x64, Debian); **ainda não validado em um aparelho
  Android/Termux real**. Limitações conhecidas no Android: os recursos de terminal
  interativo (PTY) podem não funcionar (o `bun-pty` não tem build bionic) e o
  ripgrep é instalado via `pkg` porque o binário glibc baixado automaticamente não
  roda no Android. Se algo falhar, rode o instalador de novo — ele retoma de onde
  parou. Veja `CHANGES.md`.

#### Problemas comuns no Termux

**1. `CANNOT LINK EXECUTABLE "curl": cannot locate symbol "SSL_set_quic_tls_early_data_enabled"`**

Não é um problema do instalador: o `curl` do seu Termux está quebrado porque os
pacotes estão dessincronizados — o `libcurl` foi compilado contra um OpenSSL mais
novo do que a `libopenssl` instalada. Enquanto não corrigir, **todos** os
programas que usam libcurl falham (o `git`, que o instalador usa para clonar,
incluído). Conserte o ambiente primeiro:

```bash
termux-change-repo                   # selecione um mirror (ex.: Mirror group → All)
apt update && apt full-upgrade -y    # sincroniza libcurl e libopenssl
curl --version                       # deve funcionar agora
```

Depois rode novamente o comando de instalação. Se quiser evitar o `curl`, o
`wget` não depende do libcurl e baixa o instalador do mesmo jeito:

```bash
pkg install -y wget && wget -qO- https://raw.githubusercontent.com/deivid22srk/opencode-termux/dev/install-termux.sh | bash
```

**2. `No mirror or mirror group selected`**

O Termux está sem mirror configurado — sem isso o `apt` não consegue baixar
pacotes, e é exatamente por isso que o problema 1 acontece e não se corrige
sozinho. Rode `termux-change-repo`, escolha um mirror na lista e rode
`apt update` de novo. Alternativa não interativa:

```bash
echo "deb https://packages.termux.dev/apt/termux-main stable main" > "$PREFIX/etc/apt/sources.list"
apt update && apt full-upgrade -y
```

**3. Nada acima resolveu**

O estado dos pacotes pode estar muito antigo ou inconsistente para conserto
in-place. Faça backup dos seus dados, desinstale e reinstale o app Termux
(versão atual do [GitHub](https://github.com/termux/termux-app/releases) ou
F-Droid — a distribuição pela Play Store está descontinuada) e rode o comando
de instalação num ambiente novo. O instalador também detecta esse caso
antecipadamente: se o `curl` estiver quebrado, ele avisa com as instruções
acima antes de tentar qualquer coisa.

### App desktop (BETA)

O OpenCode também está disponível como aplicativo desktop. Baixe diretamente pela [página de releases](https://github.com/anomalyco/opencode/releases) ou em [opencode.ai/download](https://opencode.ai/download).

| Plataforma            | Download                           |
| --------------------- | ---------------------------------- |
| macOS (Apple Silicon) | `opencode-desktop-mac-arm64.dmg`   |
| macOS (Intel)         | `opencode-desktop-mac-x64.dmg`     |
| Windows               | `opencode-desktop-windows-x64.exe` |
| Linux                 | `.deb`, `.rpm` ou AppImage         |

```bash
# macOS (Homebrew)
brew install --cask opencode-desktop
# Windows (Scoop)
scoop bucket add extras; scoop install extras/opencode-desktop
```

#### Diretório de instalação

O script de instalação respeita a seguinte ordem de prioridade para o caminho de instalação:

1. `$OPENCODE_INSTALL_DIR` - Diretório de instalação personalizado
2. `$XDG_BIN_DIR` - Caminho compatível com a especificação XDG Base Directory
3. `$HOME/bin` - Diretório binário padrão do usuário (se existir ou puder ser criado)
4. `$HOME/.opencode/bin` - Fallback padrão

```bash
# Exemplos
OPENCODE_INSTALL_DIR=/usr/local/bin curl -fsSL https://opencode.ai/install | bash
XDG_BIN_DIR=$HOME/.local/bin curl -fsSL https://opencode.ai/install | bash
```

### Agents

O OpenCode inclui dois agents integrados, que você pode alternar com a tecla `Tab`.

- **build** - Padrão, agent com acesso total para trabalho de desenvolvimento
- **plan** - Agent somente leitura para análise e exploração de código
  - Nega edições de arquivos por padrão
  - Pede permissão antes de executar comandos bash
  - Ideal para explorar codebases desconhecidas ou planejar mudanças

Também há um subagent **general** para buscas complexas e tarefas em várias etapas.
Ele é usado internamente e pode ser invocado com `@general` nas mensagens.

Saiba mais sobre [agents](https://opencode.ai/docs/agents).

### Documentação

Para mais informações sobre como configurar o OpenCode, [**veja nossa documentação**](https://opencode.ai/docs).

### Contribuir

Se você tem interesse em contribuir com o OpenCode, leia os [contributing docs](./CONTRIBUTING.md) antes de enviar um pull request.

### Construindo com OpenCode

Se você estiver trabalhando em um projeto relacionado ao OpenCode e estiver usando "opencode" como parte do nome (por exemplo, "opencode-dashboard" ou "opencode-mobile"), adicione uma nota no README para deixar claro que não foi construído pela equipe do OpenCode e não é afiliado a nós de nenhuma forma.

---

**Junte-se à nossa comunidade** [Discord](https://discord.gg/opencode) | [X.com](https://x.com/opencode)
