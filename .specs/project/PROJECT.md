# OpenClaw Personal Gateway

**Vision:** Operar um gateway OpenClaw local-first em host dedicado, com segredos injetados em runtime, wrappers curtos para uso diario e caminho de evolucao controlado para canais como WhatsApp e Telegram.
**For:** um operador tecnico unico, ou uma equipe muito pequena, que quer um agente pessoal/autonomo sem depender de SaaS externa nem aceitar "magica" operacional.
**Solves:** bootstrapar, endurecer e operar um runtime OpenClaw com pouca friccao, mantendo proximidade com o upstream vendorizado e reduzindo risco de leak de credenciais.

## Goals

- Subir `openclaw-gateway` localmente via Docker Compose e validar `health`, `status`, `logs`, TUI e dashboard sem commitar secrets.
- Permitir onboarding real de provider/canal trocando chaves por reinicio de container, sem rebuild da imagem.
- Sustentar dois caminhos oficiais de operacao na v1: `local-first conservador` e `WhatsApp dedicado + browser`, mantendo Telegram opcional.

## Tech Stack

**Core:**

- Framework: Docker Compose + OpenClaw vendorizado em `vendor/openclaw`
- Language: POSIX shell no scaffold raiz; TypeScript `5.9.3` no runtime upstream vendorizado
- Runtime: Docker Engine/Compose e Node.js `>=22.16.0` dentro da imagem `openclaw:local`
- Package manager: nenhum no root; upstream usa `pnpm@10.23.0`
- Database: sem banco dedicado no scaffold; estado persistido em `runtime/config` e `runtime/workspace`

**Key dependencies:**

- `openclaw@2026.3.14` vendorizado
- Docker Compose
- Vitest `4.1.0` no upstream
- OpenAI como provider principal via Docker secret
- Gemini opcional para `web_search` no perfil WhatsApp dedicado + browser

## Scope

**v1 includes:**

- Buildar a imagem local a partir de `vendor/openclaw` e subir o gateway com `--allow-unconfigured`
- Injetar `OPENAI_API_KEY` e `GEMINI_API_KEY` em runtime via arquivos locais de secret
- Operar o runtime por wrappers curtos (`build`, `up`, `down`, `ps`, `health`, `status`, `logs`, `tui`, `dashboard`)
- Documentar e suportar os caminhos `local-first conservador`, `WhatsApp dedicado + browser` e `Telegram opcional`
- Manter o planejamento e a memoria do projeto em `.specs/` usando `tlc-spec-driven`

**Explicitly out of scope:**

- Refatorar `vendor/openclaw` sem necessidade funcional clara
- Transformar o projeto em plataforma multi-tenant ou SaaS
- Mover secrets para `.env`, `compose.yaml`, codigo versionado ou qualquer artefato de documentacao
- Liberar `exec`, `elevated` ou grupos abertos por padrao

## Constraints

- Technical: segredos devem continuar fora do versionamento e entrar apenas em runtime
- Technical: Telegram nao pode virar pre-requisito para o bootstrap inicial
- Technical: o scaffold deve continuar pequeno, shell-first e proximo do fluxo oficial do OpenClaw
- Resources: a maior parte da personalizacao deve viver em `compose*.yaml`, `scripts/` e docs, nao no vendor
- Operational: qualquer fluxo novo precisa respeitar redacao minima de logs e arquivos sensiveis
