# OpenClaw Personal Gateway

Scaffold inicial para rodar um gateway OpenClaw em **VM/host dedicado** com **Docker Compose**, começando por **Telegram**, com a `OPENAI_API_KEY` fora do `compose.yaml`.

## Decisoes iniciais

- `Docker Compose` para subir e descer o gateway com pouco atrito.
- `vendor/openclaw` para manter o fluxo oficial de build local do OpenClaw.
- segredo via arquivo em `secrets/openai_api_key.txt`, montado como Docker secret.
- `runtime/config` e `runtime/workspace` persistidos no projeto.
- canal inicial: **Telegram**.

## Estrutura

```text
.
├── .env.example
├── compose.yaml
├── docs/
├── runtime/
│   ├── config/
│   └── workspace/
├── scripts/
│   ├── _load-openai-secret.sh
│   ├── build.sh
│   ├── cli-entrypoint.sh
│   ├── dashboard.sh
│   ├── docker-logs.sh
│   ├── down.sh
│   ├── gateway-entrypoint.sh
│   ├── health.sh
│   ├── logs.sh
│   ├── onboard-telegram.sh
│   ├── ps.sh
│   ├── status.sh
│   ├── tui.sh
│   └── up.sh
├── secrets/
│   └── README.md
└── vendor/
    └── openclaw/
```

## Por que esse desenho

### 1. Segredo fora do compose

Eu preferi **nao** colocar a key da OpenAI inline em `environment:` porque isso aumenta a chance de vazamento acidental.

Neste scaffold, a key fica em:

- `secrets/openai_api_key.txt`

E o container a recebe como Docker secret em `/run/secrets/openai_api_key`.

### 2. Config persistente

O OpenClaw guarda estado, sessoes e configuracoes em `~/.openclaw`.  
Aqui isso fica mapeado para:

- `runtime/config`
- `runtime/workspace`

Assim fica facil subir, derrubar e inspecionar o estado local.

### 3. Config de canal nao hardcoded

Eu **nao** congelei um JSON de Telegram/WhatsApp neste repo porque a superficie de configuracao do OpenClaw pode evoluir.  
Prefiro que a configuracao de canal nasca pelo onboarding/CLI da versao real instalada e caia em `runtime/config`.

## Setup rapido

## 1. Preparar variaveis nao sensiveis

```bash
cp .env.example .env.local
```

Revise pelo menos:

- `OPENCLAW_IMAGE`
- `OPENCLAW_HOST_PORT`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_HOST_PORT`
- `OPENCLAW_GATEWAY_BIND`
- `OPENCLAW_LOG_LEVEL`

## 2. Criar a key da OpenAI como secret file

Crie o arquivo:

```text
secrets/openai_api_key.txt
```

Com apenas a key em uma linha.

## 3. Repo oficial do OpenClaw

O repo oficial ja foi trazido para:

```text
vendor/openclaw
```

O build usa esse repo como contexto Docker.

## 4. Buildar a imagem local

```bash
./scripts/build.sh
```

## 5. Fazer o onboarding inicial

```bash
./scripts/onboard-telegram.sh
```

Objetivo desta etapa:

- configurar provider/model;
- definir autenticacao do gateway;
- configurar Telegram primeiro;
- deixar `dmPolicy` em modo fechado (`allowlist` ou `pairing`);
- confirmar onde o estado ficou persistido em `runtime/config`.

## 6. Subir o gateway

```bash
./scripts/up.sh
```

## 7. Ver logs

```bash
./scripts/docker-logs.sh
```

## Fluxo operacional

Pensa no sistema em 3 camadas:

1. **Infra Docker**
   - sobe e mantem o `openclaw-gateway`;
   - persiste estado em `runtime/config` e `runtime/workspace`.
2. **Gateway OpenClaw**
   - expoe a porta `18789`;
   - serve a UI web;
   - recebe comandos do CLI/TUI;
   - depois do onboarding, tambem fala com canais como Telegram.
3. **Clientes de operacao**
   - terminal local via `openclaw-cli`;
   - navegador local via dashboard/control UI;
   - canais externos, como Telegram, quando habilitados.

### O ciclo normal de uso

1. subir o gateway;
2. checar saude e status;
3. operar localmente pelo PC via TUI ou dashboard;
4. depois, se quiser, usar Telegram como canal adicional.

## Como subir e derrubar

### Subir o gateway

```bash
./scripts/up.sh
```

### Ver se o container esta de pe

```bash
./scripts/ps.sh
```

### Derrubar tudo

```bash
./scripts/down.sh
```

## Como monitorar

### 1. Logs do container Docker

Esse e o nivel mais baixo de observabilidade.  
Serve para ver startup, crash, restart loop e erros de infra.

```bash
./scripts/docker-logs.sh
```

### 2. Health do Gateway

Esse e o check rapido para saber se o Gateway esta respondendo.

```bash
./scripts/health.sh
./scripts/health.sh --json
```

### 3. Status do OpenClaw

Esse e o resumo operacional mais util.

```bash
./scripts/status.sh
./scripts/status.sh --all
./scripts/status.sh --usage
```

Use `status --usage` quando quiser um snapshot mais orientado a consumo/uso.

### 4. Logs via RPC do proprio OpenClaw

Depois que o Gateway estiver rodando, da para acompanhar logs pelo proprio OpenClaw,
sem depender so do `docker logs`.

```bash
./scripts/logs.sh
./scripts/logs.sh --json
```

## Como usar pelo PC, sem Telegram

Voce vai ter 3 jeitos principais de operar localmente:

### 1. TUI no terminal

Esse e o jeito mais proximo de "conversar com ele pelo terminal".

```bash
./scripts/tui.sh
```

Esse comando abre uma interface de terminal conectada ao Gateway.

Se quiser iniciar com uma mensagem:

```bash
./scripts/tui.sh --message "oi"
```

Se quiser entregar respostas para um canal externo no futuro, existe `--deliver`,
mas para uso local isso nao e necessario no comeco.

### 2. Dashboard / Control UI no navegador

O Gateway serve a interface web na mesma porta `18789`.

Depois que o gateway estiver de pe, abra no navegador do proprio PC:

```text
http://127.0.0.1:18789/
```

Como estamos publicando a porta apenas em loopback, isso fica acessivel localmente.

Observacoes importantes:

- conexoes locais em `127.0.0.1` sao auto-aprovadas;
- se o onboarding configurar token para o gateway, a UI pode pedir esse token na primeira conexao;
- o comando abaixo ajuda a abrir ou imprimir a URL da dashboard com o auth atual:

```bash
./scripts/dashboard.sh
```

### 3. Comandos pontuais via CLI

Para diagnostico e operacao:

```bash
./scripts/status.sh
./scripts/health.sh
./scripts/logs.sh
```

Para help e descoberta:

```bash
./scripts/compose.sh run --rm openclaw-cli --help
./scripts/tui.sh --help
./scripts/dashboard.sh --help
```

## Scripts curtos

Os wrappers abaixo existem para facilitar o uso diario e, depois, aliases no `~/.zshrc`.

### Infra

- `./scripts/build.sh`
- `./scripts/up.sh`
- `./scripts/down.sh`
- `./scripts/ps.sh`
- `./scripts/docker-logs.sh`

### Operacao local

- `./scripts/health.sh`
- `./scripts/status.sh`
- `./scripts/logs.sh`
- `./scripts/tui.sh`
- `./scripts/dashboard.sh`
- `./scripts/onboard-telegram.sh`

## Exemplo de aliases para `.zshrc`

```bash
export OPENCLAW_HOME="$HOME/Development/openclaw-personal-gateway"

alias oc-build='$OPENCLAW_HOME/scripts/build.sh'
alias oc-up='$OPENCLAW_HOME/scripts/up.sh'
alias oc-down='$OPENCLAW_HOME/scripts/down.sh'
alias oc-ps='$OPENCLAW_HOME/scripts/ps.sh'
alias oc-dlogs='$OPENCLAW_HOME/scripts/docker-logs.sh'
alias oc-health='$OPENCLAW_HOME/scripts/health.sh'
alias oc-status='$OPENCLAW_HOME/scripts/status.sh'
alias oc-logs='$OPENCLAW_HOME/scripts/logs.sh'
alias oc-tui='$OPENCLAW_HOME/scripts/tui.sh'
alias oc-dash='$OPENCLAW_HOME/scripts/dashboard.sh'
alias oc-onboard='$OPENCLAW_HOME/scripts/onboard-telegram.sh'
```

Depois o fluxo fica assim:

```bash
oc-up
oc-status --all
oc-health --json
oc-tui
oc-dash
oc-dlogs
```

## O que muda quando o Telegram entrar

Telegram **nao** substitui o uso local pelo PC.

Ele vira apenas mais um canal de entrada/saida.

Na pratica:

- voce pode continuar usando TUI e dashboard normalmente;
- o Telegram passa a ser um jeito remoto de conversar com o mesmo runtime;
- monitoramento e operacao continuam sendo feitos principalmente por `status`, `health`, `logs` e dashboard.

## Comandos uteis

### Subir

```bash
./scripts/up.sh
```

### Derrubar

```bash
./scripts/down.sh
```

### Rebuildar

```bash
./scripts/build.sh --no-cache
```

### Rodar CLI pontual

```bash
./scripts/compose.sh run --rm openclaw-cli --help
```

### TUI local

```bash
./scripts/tui.sh
```

### Dashboard local

```bash
./scripts/dashboard.sh
```

Depois abra:

```text
http://127.0.0.1:18789/
```

### Status

```bash
./scripts/status.sh --all
```

### Health

```bash
./scripts/health.sh --json
```

### Logs via RPC

```bash
./scripts/logs.sh
```

## Seguranca minima que eu manteria

- comece por **Telegram**, nao WhatsApp;
- use **Project API key** separada so para esse experimento;
- mantenha spend limit baixo;
- nao jogue segredos brutos na conversa sem necessidade;
- trate `runtime/config` como sensivel;
- prefira VM/host dedicado;
- publique as portas so em `127.0.0.1`.

## Proximos passos naturais

1. buildar a imagem;
2. fazer onboarding do Telegram;
3. validar `/status` e `/usage full`;
4. depois decidir se WhatsApp entra.
