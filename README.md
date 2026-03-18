# OpenClaw Personal Gateway

Projeto para operar um gateway OpenClaw em **VM/host dedicado** com **Docker Compose**, mantendo a `OPENAI_API_KEY` fora do `compose.yaml` e priorizando operacao local via PC antes da integracao com canais externos.

## Visao geral

Este repositorio oferece um scaffold local para:

- buildar uma imagem OpenClaw a partir de `vendor/openclaw`;
- subir o gateway com Docker Compose;
- persistir configuracao e workspace localmente;
- injetar a chave do provider em runtime via Docker secret;
- operar o runtime via CLI, TUI e dashboard;
- tratar Telegram como integracao opcional posterior.

## Decisoes de arquitetura

### Segredo fora do Compose

A chave da OpenAI nao fica inline em `environment:`. O projeto usa:

- `secrets/openai_api_key.txt`

Esse arquivo e montado como Docker secret e disponibilizado no container em:

- `/run/secrets/openai_api_key`

### Estado persistente

O OpenClaw armazena estado, sessoes e configuracoes em `~/.openclaw`. Neste projeto, esses dados sao persistidos em:

- `runtime/config`
- `runtime/workspace`

Isso permite reiniciar containers sem perder o estado operacional.

### Configuracao de canal em runtime

O repositorio nao versiona configuracoes estaticas de Telegram ou WhatsApp. A configuracao de canais deve ser criada pelo onboarding ou pela CLI da versao instalada e persistida em `runtime/config`.

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
│   ├── compose.sh
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

## Setup rapido

### 1. Preparar variaveis nao sensiveis

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

### 2. Criar o arquivo de secret da OpenAI

Crie:

```text
secrets/openai_api_key.txt
```

O arquivo deve conter apenas a chave, em uma unica linha.

### 3. Verificar o vendor do OpenClaw

O projeto assume que o repositorio oficial do OpenClaw esta disponivel em:

```text
vendor/openclaw
```

O build Docker usa esse diretorio como contexto.

### 4. Buildar a imagem local

```bash
./scripts/build.sh
```

### 5. Executar o onboarding inicial

```bash
./scripts/onboard-telegram.sh
```

Objetivos desta etapa:

- configurar provider e modelo;
- definir autenticacao do gateway;
- configurar Telegram, se essa integracao for desejada agora;
- manter `dmPolicy` em modo fechado (`allowlist` ou `pairing`);
- confirmar onde o estado foi persistido em `runtime/config`.

### 6. Subir o gateway

```bash
./scripts/up.sh
```

### 7. Acompanhar logs

```bash
./scripts/docker-logs.sh
```

## Modelo operacional

O runtime pode ser entendido em tres camadas:

1. **Infra Docker**
   - sobe e mantem o servico `openclaw-gateway`;
   - persiste estado em `runtime/config` e `runtime/workspace`.
2. **Gateway OpenClaw**
   - expoe a porta `18789`;
   - serve a UI web;
   - recebe comandos do CLI e da TUI;
   - pode integrar canais externos apos o onboarding.
3. **Clientes locais**
   - terminal local via `openclaw-cli`;
   - navegador local via dashboard/control UI;
   - canais externos como Telegram, quando configurados.

### Ciclo normal de uso

1. subir o gateway;
2. checar saude e status;
3. operar localmente via TUI, dashboard ou CLI;
4. habilitar Telegram depois, se fizer sentido para o caso de uso.

## Operacao basica

### Subir o gateway

```bash
./scripts/up.sh
```

### Verificar containers

```bash
./scripts/ps.sh
```

### Derrubar a stack

```bash
./scripts/down.sh
```

## Monitoramento

### Logs do container Docker

Camada mais baixa de observabilidade, util para startup, restart loop e erros de infraestrutura.

```bash
./scripts/docker-logs.sh
```

### Health do gateway

Check rapido para verificar se o gateway esta respondendo.

```bash
./scripts/health.sh
./scripts/health.sh --json
```

### Status do OpenClaw

Resumo operacional do runtime.

```bash
./scripts/status.sh
./scripts/status.sh --all
./scripts/status.sh --usage
```

Use `status --usage` para um snapshot mais orientado a consumo e uso.

### Logs via RPC do OpenClaw

Depois que o gateway estiver rodando, os logs tambem podem ser acompanhados via RPC.

```bash
./scripts/logs.sh
./scripts/logs.sh --json
```

## Uso local sem Telegram

O projeto oferece tres formas principais de operacao local.

### TUI no terminal

Abre uma interface de terminal conectada ao gateway.

```bash
./scripts/tui.sh
```

Exemplo com mensagem inicial:

```bash
./scripts/tui.sh --message "oi"
```

Existe suporte a `--deliver` para cenarios com canal externo, mas isso nao e necessario para a operacao local inicial.

### Dashboard / Control UI no navegador

O gateway serve a interface web na porta `18789`.

Depois que o gateway estiver de pe, abra:

```text
http://127.0.0.1:18789/
```

Como a publicacao de porta ocorre apenas em loopback, o acesso fica restrito ao host local.

Observacoes importantes:

- conexoes locais em `127.0.0.1` sao auto-aprovadas;
- se o onboarding configurar token para o gateway, a UI pode pedir esse token na primeira conexao;
- o comando abaixo ajuda a abrir ou imprimir a URL da dashboard com o auth atual:

```bash
./scripts/dashboard.sh
```

### Comandos pontuais via CLI

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

## Scripts disponiveis

Os wrappers em `scripts/` funcionam como a interface principal do projeto.

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

Fluxo tipico com aliases:

```bash
oc-up
oc-status --all
oc-health --json
oc-tui
oc-dash
oc-dlogs
```

## Integracao com Telegram

Telegram nao substitui a operacao local pelo PC. Quando habilitado, ele passa a funcionar como mais um canal de entrada e saida para o mesmo runtime.

Na pratica:

- TUI e dashboard continuam funcionando normalmente;
- Telegram adiciona uma interface remota para o mesmo gateway;
- monitoramento e operacao seguem concentrados em `status`, `health`, `logs` e dashboard.

Consulte [docs/telegram-onboarding.md](docs/telegram-onboarding.md) para o fluxo dedicado de onboarding.

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

## Consideracoes de seguranca

Minimos recomendados para operacao local:

- usar uma Project API key separada para este ambiente;
- manter spend limit baixo;
- nao colocar segredos diretamente em `compose.yaml` ou em conversas desnecessarias;
- tratar `runtime/config` como sensivel;
- preferir VM ou host dedicado;
- publicar portas apenas em `127.0.0.1`;
- tratar Telegram como etapa opcional, nao como requisito de bootstrap.

## Proximos passos

1. buildar a imagem local;
2. validar health e status do gateway;
3. concluir o onboarding do provider e, se desejado, do Telegram;
4. testar uma conversa ponta a ponta no fluxo local;
5. decidir se canais adicionais entram no escopo.
