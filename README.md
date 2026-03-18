# OpenClaw Personal Gateway

Projeto para operar um gateway OpenClaw em **VM/host dedicado** com **Docker Compose**, mantendo a `OPENAI_API_KEY` fora do `compose.yaml` e priorizando operacao local via PC antes da integracao com canais externos.

## Visao geral

Este repositorio oferece um scaffold local para:

- buildar uma imagem OpenClaw a partir de `vendor/openclaw`;
- opcionalmente buildar uma imagem de sandbox separada para execucao isolada de tools;
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

### Sandbox separado do gateway principal

Quando o sandbox esta habilitado, o projeto continua usando `openclaw:local` como imagem principal do gateway.

O que muda e apenas o ambiente de execucao de tools:

- `openclaw:local` continua sendo o runtime principal;
- `openclaw-sandbox:bookworm-slim` vira a imagem isolada para tools sandboxadas;
- o gateway precisa ser buildado com Docker CLI para conseguir orquestrar os containers de sandbox.

### Configuracao de canal em runtime

O repositorio nao versiona configuracoes estaticas de Telegram ou WhatsApp. A configuracao de canais deve ser criada pelo onboarding ou pela CLI da versao instalada e persistida em `runtime/config`.

## Estrutura

```text
.
├── .env.example
├── compose.sandbox.yaml
├── compose.yaml
├── docs/
├── runtime/
│   ├── config/
│   └── workspace/
├── scripts/
│   ├── _load-openai-secret.sh
│   ├── build.sh
│   ├── build-sandbox.sh
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
│   ├── sandbox-enable.sh
│   ├── sandbox-explain.sh
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
- `OPENCLAW_INSTALL_DOCKER_CLI`
- `OPENCLAW_SANDBOX_ENABLE`
- `OPENCLAW_SANDBOX_IMAGE`
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

Com a configuracao atual de `.env.local`, esse build inclui Docker CLI dentro de `openclaw:local`, o que e necessario para o gateway criar sandboxes Docker.

### 5. Buildar a imagem base de sandbox

```bash
./scripts/build-sandbox.sh
```

Esse passo builda localmente a imagem `openclaw-sandbox:bookworm-slim` a partir do vendor do OpenClaw. Ela nao substitui `openclaw:local`; ela existe para executar tools em ambiente isolado.

### 6. Ativar a configuracao de sandbox no runtime

```bash
./scripts/sandbox-enable.sh
```

Esse wrapper aplica o baseline recomendado para este projeto:

- `agents.defaults.sandbox.mode = "all"`
- `agents.defaults.sandbox.scope = "agent"`
- `agents.defaults.sandbox.workspaceAccess = "rw"`
- `agents.defaults.sandbox.docker.image = "openclaw-sandbox:bookworm-slim"`
- `gateway.controlUi.allowedOrigins = ["http://127.0.0.1:${OPENCLAW_HOST_PORT}"]`
- `tools.deny = ["exec"]`
- `tools.elevated.enabled = false`

Se voce ja tiver uma policy propria em `tools.deny`, ajuste esse ponto manualmente depois do bootstrap de sandbox.

Decisao atual deste scaffold:

- manter o baseline conservador acima;
- tratar este runtime primeiro como um agente pessoal focado em contexto, memoria e workspace;
- nao liberar `exec` nem `elevated` por padrao antes de sentir falta real dessa automacao.

Depois disso, o gateway precisa ser reiniciado para carregar a configuracao nova.

Observacao importante:

- o wrapper `./scripts/sandbox-enable.sh` pode subir temporariamente o gateway se ele ainda nao estiver em execucao, porque a CLI precisa falar com um gateway ativo para aplicar a configuracao;
- isso nao substitui o restart final quando voce quiser garantir que o processo do gateway recarregou a configuracao persistida.

### 7. Executar o onboarding inicial

```bash
./scripts/onboard-telegram.sh
```

Objetivos desta etapa:

- configurar provider e modelo;
- definir autenticacao do gateway;
- configurar Telegram, se essa integracao for desejada agora;
- manter `dmPolicy` em modo fechado (`allowlist` ou `pairing`);
- confirmar onde o estado foi persistido em `runtime/config`.

### 8. Subir o gateway

```bash
./scripts/up.sh
```

### 9. Validar o sandbox efetivo

```bash
./scripts/sandbox-explain.sh
```

Use esse comando para confirmar se a sessao esta realmente sandboxed, qual imagem esta em uso e como `elevated` esta sendo aplicado.

Para confirmar especificamente `tools.deny = ["exec"]`, prefira inspecionar a config persistida:

```bash
./scripts/compose.sh run --rm openclaw-cli config get tools --json
```

### 10. Acompanhar logs

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
   - quando sandbox esta habilitado, coordena containers de sandbox via Docker socket;
   - pode integrar canais externos apos o onboarding.
3. **Sandbox de tools**
   - executa tools em `openclaw-sandbox:bookworm-slim`;
   - isola execucao do host principal;
   - herda acesso ao workspace de acordo com `workspaceAccess`.
4. **Clientes locais**
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
- `./scripts/build-sandbox.sh`
- `./scripts/up.sh`
- `./scripts/down.sh`
- `./scripts/ps.sh`
- `./scripts/docker-logs.sh`

### Operacao local

- `./scripts/health.sh`
- `./scripts/status.sh`
- `./scripts/logs.sh`
- `./scripts/sandbox-enable.sh`
- `./scripts/sandbox-explain.sh`
- `./scripts/tui.sh`
- `./scripts/dashboard.sh`
- `./scripts/onboard-telegram.sh`

## Exemplo de aliases para `.zshrc`

```bash
export OPENCLAW_HOME="$HOME/Development/openclaw-personal-gateway"

alias oc-build='$OPENCLAW_HOME/scripts/build.sh'
alias oc-build-sandbox='$OPENCLAW_HOME/scripts/build-sandbox.sh'
alias oc-up='$OPENCLAW_HOME/scripts/up.sh'
alias oc-down='$OPENCLAW_HOME/scripts/down.sh'
alias oc-ps='$OPENCLAW_HOME/scripts/ps.sh'
alias oc-dlogs='$OPENCLAW_HOME/scripts/docker-logs.sh'
alias oc-health='$OPENCLAW_HOME/scripts/health.sh'
alias oc-status='$OPENCLAW_HOME/scripts/status.sh'
alias oc-logs='$OPENCLAW_HOME/scripts/logs.sh'
alias oc-sandbox-enable='$OPENCLAW_HOME/scripts/sandbox-enable.sh'
alias oc-sandbox-explain='$OPENCLAW_HOME/scripts/sandbox-explain.sh'
alias oc-tui='$OPENCLAW_HOME/scripts/tui.sh'
alias oc-dash='$OPENCLAW_HOME/scripts/dashboard.sh'
alias oc-onboard='$OPENCLAW_HOME/scripts/onboard-telegram.sh'
```

Fluxo tipico com aliases:

```bash
oc-up
oc-status --all
oc-health --json
oc-sandbox-explain
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
- tratar `runtime/workspace` como memoria privada do agente;
- preferir VM ou host dedicado;
- publicar portas apenas em `127.0.0.1`;
- manter `tools.elevated.enabled = false` para este perfil;
- negar `exec` por default quando o sandbox estiver ativo;
- tratar Telegram como etapa opcional, nao como requisito de bootstrap.

### Diferenca pratica entre gateway e sandbox

- `openclaw:local` continua sendo a imagem principal do sistema.
- `openclaw-sandbox:bookworm-slim` nao substitui o gateway; ela so executa tools isoladas.
- sem sandbox, tools rodam no ambiente principal do gateway;
- com sandbox, tools rodam em um container separado, enquanto memoria, sessoes e bootstrap continuam no mesmo runtime OpenClaw.

### Policy atual de tools

O projeto segue um baseline deliberadamente conservador:

- `tools.deny = ["exec"]`
- `tools.elevated.enabled = false`

Isso significa:

- o agente continua podendo trabalhar com memoria, sessoes e arquivos do workspace;
- o agente nao pode executar shell arbitrario por default;
- qualquer necessidade futura de automacao shell deve ser uma decisao explicita, nao um comportamento implicito.

### Debug de policy e sandbox

Se o agente nao conseguir executar algo por policy muito restritiva, o fluxo recomendado de debug e:

1. reproduzir a tentativa;
2. inspecionar a policy efetiva:

```bash
./scripts/sandbox-explain.sh
```

3. olhar os logs do gateway:

```bash
./scripts/docker-logs.sh
```

4. se precisar inspecionar a config persistida:

```bash
./scripts/compose.sh run --rm openclaw-cli config get tools --json
./scripts/compose.sh run --rm openclaw-cli config get agents.defaults.sandbox --json
```

Heuristicas uteis:

- se o pedido exigia shell, a primeira suspeita e `tools.deny = ["exec"]`;
- se o pedido exigia sair do sandbox e tocar host diretamente, a primeira suspeita e `tools.elevated.enabled = false`;
- `./scripts/sandbox-explain.sh` e a fonte mais direta para entender sandbox, imagem efetiva e gates de `elevated`;
- `./scripts/compose.sh run --rm openclaw-cli config get tools --json` e a fonte mais confiavel para confirmar `tools.deny = ["exec"]`.

## Proximos passos

1. buildar a imagem local;
2. buildar a imagem base de sandbox;
3. aplicar a configuracao com `./scripts/sandbox-enable.sh`;
4. validar `./scripts/sandbox-explain.sh`;
5. concluir o onboarding do provider e, se desejado, do Telegram;
6. testar uma conversa ponta a ponta no fluxo local;
7. decidir se canais adicionais entram no escopo.
