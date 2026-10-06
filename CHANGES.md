# CHANGES — fork `deivid22srk/opencode-termux`

Este fork parte de `anomalyco/opencode` (branch `dev`) e mantém mudanças **pequenas
e documentadas** para facilitar o merge com o upstream.

## Resumo

A integração com a extensão [VibeBridge](https://github.com/deivid22srk/VibeBridge)
**não exigiu nenhuma mudança no código-fonte do OpenCode**: o servidor já possui,
nativamente, tudo o que um cliente externo precisa:

- **CORS embutido** (`packages/server/src/cors.ts`): origens `http://localhost:*` e
  `http://127.0.0.1:*` já são aceitas por padrão; outras podem ser liberadas com
  `opencode serve --cors <origem>` (repetível) ou pela config `server.cors`.
- **Autenticação embutida** (`packages/opencode/src/server/auth.ts`): definindo a env
  `OPENCODE_SERVER_PASSWORD` (usuário padrão `opencode`, via
  `OPENCODE_SERVER_USERNAME`), todas as rotas passam a exigir
  `Authorization: Basic base64(usuario:senha)`, com fallback `?auth_token=` para SSE.
- **API HTTP v1 completa** (spec em `GET /doc`): sessões, prompts com streaming por
  SSE (`/event`), ferramentas, permissões (`/permission/:id/reply`), perguntas
  (`/question/:id/reply`), modelos/agentes (`/config/providers`, `/agent`), comandos
  (`/command`), MCP (`/mcp`), abort (`/session/:id/abort`).
- **Roteamento por projeto**: query `?directory=<caminho absoluto>` (ou header
  `x-opencode-directory`) seleciona em qual pasta o OpenCode atua.

Manter zero alterações de código preserva o histórico limpo para `git merge upstream/dev`.

## O que foi adicionado neste fork

| Arquivo | Descrição |
|---|---|
| `install-termux.sh` | Instalador de comando único, idempotente, para Termux (Android) e Linux: atualiza pacotes (`pkg update/upgrade`), instala `git curl unzip ripgrep bash`, baixa o **Bun oficial para Android** (`bun-linux-aarch64-android.zip`, versão fixada em `1.3.14` via `packageManager`), clona/atualiza este repositório em `~/opencode-termux`, roda `bun install` e cria o comando `opencode` no `$PATH` (wrapper que executa o fonte com `bun run`). Variáveis opcionais: `REPO_URL`, `REPO_BRANCH`, `INSTALL_DIR`, `BUN_VERSION`. |
| `README.md` | Nova seção **"Installation on Termux (Android)"** com o comando de instalação, como iniciar o servidor para a VibeBridge e as limitações conhecidas. |
| `README.br.md` | Mesma seção em português ("Instalação no Termux (Android)"). |
| `CHANGES.md` | Este arquivo. |

## Por que rodar do fonte com Bun (e não compilar binário)

- `opencode serve` não precisa de toolchain Go nem de compilação: `bun install` +
  `bun run ./src/index.ts serve` são suficientes (SQLite via `bun:sqlite`, embutido).
- O Bun publica builds oficiais para Android aarch64/x64 — sem dependência de
  repositórios de terceiros (TUR).
- Compilar o binário único (`bun build --compile`) para Android/bionic não é
  suportado e traria mais pontos de falha no Termux.

## Limitações conhecidas no Termux (honestas)

- O instalador foi **validado em Linux x64 (Debian)** nos dois caminhos (instalação
  nova e re-execução idempotente). **Ainda não foi validado em um aparelho
  Android/Termux real** — o script trata os casos conhecidos, mas teste em
  dispositivo é bem-vindo.
- **PTY/terminal interativo**: o pacote `bun-pty` só distribui binários
  glibc/musl; no Android (bionic) o `dlopen` falha silenciosamente no load e os
  recursos de terminal interativo do OpenCode podem não funcionar. As ferramentas
  de bash/leitura/edição do agente não dependem disso.
- **ripgrep**: o OpenCode baixa um binário glibc do ripgrep quando não encontra
  `rg` no PATH; esse binário não roda no bionic. O instalador resolve isso
  instalando `ripgrep` via `pkg`.
- **Espaço em disco**: a instalação consome aproximadamente 2 GB (código shallow +
  `node_modules` do monorepo).

## Como atualizar este fork com o upstream

```bash
git remote add upstream https://github.com/anomalyco/opencode.git
git fetch upstream dev
git merge upstream/dev     # os arquivos deste fork não tocam no código do servidor
git push origin dev
```

## Robustez do instalador e troubleshooting (atualização pós-feedback)

- O instalador agora faz uma **verificação prévia do curl** no Termux: se o
  binário estiver quebrado pelo caso clássico de pacotes dessincronizados
  (`CANNOT LINK EXECUTABLE "curl": cannot locate symbol
  "SSL_set_quic_tls_early_data_enabled"` — libcurl compilado contra OpenSSL
  mais novo que a libopenssl instalada), ele avisa imediatamente com o
  conserto (`termux-change-repo` + `apt update && apt full-upgrade`) em vez de
  falhar mais adiante, quando o `git` (que também usa libcurl) fosse clonar.
- Os avisos de `pkg update`/`pkg upgrade` com falha agora apontam
  explicitamente para `termux-change-repo` (mirror ausente/quebrado é a causa
  mais comum — sintoma: "No mirror or mirror group selected").
- READMEs (EN e pt-BR) ganharam a seção **"Problemas comuns no Termux"** com
  os três sintomas mais frequentes (curl quebrado, mirror não selecionado e
  ambiente irrecuperável) e os comandos de correção de cada um, incluindo a
  alternativa de instalação via `wget` (que não depende do libcurl).

## API direta de ferramentas + build no GitHub Actions (atualização v2)

Duas adições motivadas por uso real em um aparelho Termux (log de erros do
usuário: centenas de `EACCES: Permission denied: failed to link package`
durante `bun install` no aparelho).

### 1. API direta de ferramentas (opt-in, para clientes locais confiáveis)

- Novo grupo httpapi `tool` (fork): `GET /tool` lista as ferramentas
  disponíveis e `POST /tool/:name` com `{"arguments": {...}}` executa UMA
  ferramenta (bash, read, write, edit, glob, grep...) direto pelo
  ToolRegistry normal - com validação de argumentos, truncamento de saída e
  spans, mas SEM criar sessão/mensagem e SEM pedidos de permissão (o `ask` do
  contexto resolve automaticamente).
- **Opt-in via `OPENCODE_TOOL_API=1`**: um `opencode serve` comum mantém o
  comportamento interativo de sempre (permissões intactas). Sem a variável, a
  rota responde 403 com instruções.
- Motivação: a extensão VibeBridge no "modo agente em sites" (conversa no
  DeepSeek/ChatGPT etc., ferramentas executadas no OpenCode) precisa executar
  chamadas de ferramenta individuais escolhidas pelo modelo do site - o fluxo
  de sessão/prompt do OpenCode não serve para isso.
- Arquivos: `server/routes/instance/httpapi/groups/tool.ts` e
  `handlers/tool.ts` (somente adições; nenhum arquivo upstream alterado
  além do registro do grupo em `api.ts`/`server.ts`).
- Segurança: a superfície é equivalente à do modo serve normal (alguém com
  acesso HTTP já pode dirigir o agente por prompts), mas a diferença
  semântica (sem prompts de permissão) é o motivo do opt-in explícito. Use
  `OPENCODE_SERVER_PASSWORD` se o servidor estiver exposto.

### 2. Build do bundle no GitHub Actions (workflow `build.yml`)

- `.github/workflows/build.yml`: em push na branch `dev` e por dispatch,
  roda `bun install --frozen-lockfile` num runner **aarch64** (mesma
  arquitetura dos aparelhos), valida que o servidor sobe (`/global/health` +
  `GET /tool`), empacota **fonte + node_modules** em um tarball e publica na
  release rolling `termux-bundle` (além de artifact de 7 dias).
- `install-termux.sh` v2: o instalador agora **baixa o bundle pronto** e
  extrai em `~/opencode-termux` (nada é compilado/resolvido no aparelho).
  Fallback automático para o modo fonte (clone + `bun install`) se o bundle
  não estiver disponível; `INSTALL_FROM_SOURCE=1` força o modo fonte.
- No modo fonte no Termux, `bun install` agora usa `--backend=copyfile`:
  o backend padrão (hardlink) falha no filesystem do Android com o erro
  `EACCES: Permission denied: failed to link package` visto no log do
  usuário; copyfile contorna (mais lento/maior, porém confiável).
