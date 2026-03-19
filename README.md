# OpenClaw Personal Gateway

Projeto para operar um gateway OpenClaw em **VM/host dedicado** com **Docker Compose**, mantendo `OPENAI_API_KEY` e `GEMINI_API_KEY` fora do `compose.yaml` e oferecendo dois caminhos oficiais: **local-first conservador** e **WhatsApp dedicado + browser**.

## Visao geral

Este repositorio oferece um scaffold local para:

- buildar uma imagem OpenClaw a partir de `vendor/openclaw`;
- opcionalmente embutir browser local gerenciado na imagem do gateway/CLI;
- opcionalmente buildar uma imagem de sandbox separada para execucao isolada de tools;
- subir o gateway com Docker Compose;
- persistir configuracao e workspace localmente;
- injetar chaves de provider em runtime via Docker secret;
- operar o runtime via CLI, TUI e dashboard;
- manter Telegram como integracao opcional;
- promover um perfil oficial de **WhatsApp dedicado + browser** com baseline conservador.

## Decisoes de arquitetura

### Segredo fora do Compose

As chaves de provider nao ficam inline em `environment:`. O projeto usa:

- `secrets/openai_api_key.txt`
- `secrets/gemini_api_key.txt`

Esses arquivos sao disponibilizados em runtime como Docker secrets:

- `/run/secrets/openai_api_key`
- `/run/secrets/gemini_api_key`

Observacao pratica:

- `openai_api_key.txt` continua sendo o secret base para o provider principal;
- `gemini_api_key.txt` e opcional e so entra no compose quando o arquivo local existe.

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

### Dois caminhos operacionais oficiais

- **local-first conservador**: subir o gateway, operar via TUI/dashboard/CLI e adicionar Telegram depois, se fizer sentido;
- **WhatsApp dedicado + browser**: usar numero separado, browser gerenciado pelo OpenClaw, `web_search` com Gemini, `web_fetch` habilitado, grupos allowlisted e baseline conservador sem `exec`/`elevated`.

## Estrutura

```text
.
├── .env.example
├── compose.sandbox.yaml
├── compose.whatsapp-browser.yaml
├── compose.yaml
├── docs/
├── runtime/
│   ├── config/
│   └── workspace/
├── scripts/
│   ├── _load-runtime-secrets.sh
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
│   ├── onboard-runtime.sh
│   ├── whatsapp-configure.sh
│   ├── onboard-whatsapp.sh
│   ├── onboard-telegram.sh
│   ├── ps.sh
│   ├── sandbox-enable.sh
│   ├── sandbox-explain.sh
│   ├── status.sh
│   ├── tui.sh
│   ├── up.sh
│   └── whatsapp-browser-enable.sh
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
- `OPENCLAW_INSTALL_BROWSER`
- `OPENCLAW_INSTALL_DOCKER_CLI`
- `OPENCLAW_SANDBOX_ENABLE`
- `OPENCLAW_SANDBOX_IMAGE`
- `OPENCLAW_HOST_PORT`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_HOST_PORT`
- `OPENCLAW_GATEWAY_BIND`
- `OPENCLAW_LOG_LEVEL`

### 2. Criar os arquivos de secret

Crie:

```text
secrets/openai_api_key.txt
secrets/gemini_api_key.txt
```

Formato esperado:

- `openai_api_key.txt`: obrigatorio para o provider principal;
- `gemini_api_key.txt`: opcional no caminho local-first, recomendado no perfil WhatsApp dedicado + browser para `web_search`.

Cada arquivo deve conter apenas a chave, em uma unica linha.

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

Se voce for seguir o perfil **WhatsApp dedicado + browser**, ajuste antes:

```bash
OPENCLAW_INSTALL_BROWSER=1
```

Esse toggle instrui o Dockerfile do vendor a embutir Chromium/Xvfb na imagem para evitar bootstrap ad-hoc do browser em runtime.

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

### 7. Escolher o caminho operacional

- **Local-first conservador**:
  - rode `./scripts/onboard-runtime.sh` para configurar provider, modelo e auth do gateway;
  - siga operando localmente por TUI/dashboard/CLI;
  - quando quiser Telegram, rode `./scripts/onboard-telegram.sh`;
  - guia dedicado: [docs/telegram-onboarding.md](docs/telegram-onboarding.md)
- **WhatsApp dedicado + browser**:
  - preencha `secrets/gemini_api_key.txt`;
  - rode `./scripts/onboard-runtime.sh` para configurar provider, modelo e auth do gateway;
  - aplique `./scripts/whatsapp-browser-enable.sh`;
  - preencha allowlists e grupos com `./scripts/whatsapp-configure.sh`;
  - faca login do canal com `./scripts/onboard-whatsapp.sh`;
  - guia dedicado: [docs/whatsapp-dedicado-browser.md](docs/whatsapp-dedicado-browser.md)

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
   - canais externos como Telegram ou WhatsApp dedicado, quando configurados.

### Ciclo normal de uso

1. subir o gateway;
2. checar saude e status;
3. operar localmente via TUI, dashboard ou CLI;
4. escolher se Telegram ou WhatsApp dedicado entram no fluxo operacional.

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

## Caminhos operacionais

### Caminho 1: local-first conservador

O projeto oferece tres formas principais de operacao local.

Antes de usar TUI/dashboard/CLI de forma real, faca o onboarding base do runtime:

```bash
./scripts/onboard-runtime.sh
```

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

### Caminho 2: WhatsApp dedicado + browser

Esse caminho sobe o mesmo runtime, mas com um baseline operacional explicito para automacao mais seria:

- numero de WhatsApp separado do pessoal;
- browser local gerenciado pelo OpenClaw com perfil `openclaw`;
- `web_search` com Gemini e `web_fetch` mantido ligado;
- grupos fechados por allowlist e configurados manualmente;
- `tools.deny = ["exec"]` e `tools.elevated.enabled = false`.

Antes do login do canal, faca o onboarding base do runtime para provider/modelo/auth:

```bash
./scripts/onboard-runtime.sh
```

Wrapper de baseline:

```bash
./scripts/whatsapp-browser-enable.sh
```

Wrapper guiado para allowlists e grupos:

```bash
./scripts/whatsapp-configure.sh
```

Login do canal:

```bash
./scripts/onboard-whatsapp.sh
```

Runbook completo:

- [docs/whatsapp-dedicado-browser.md](docs/whatsapp-dedicado-browser.md)

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
- `./scripts/onboard-runtime.sh`
- `./scripts/whatsapp-browser-enable.sh`
- `./scripts/whatsapp-configure.sh`
- `./scripts/onboard-whatsapp.sh`
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
alias oc-onboard='$OPENCLAW_HOME/scripts/onboard-runtime.sh'
alias oc-wa-enable='$OPENCLAW_HOME/scripts/whatsapp-browser-enable.sh'
alias oc-wa-config='$OPENCLAW_HOME/scripts/whatsapp-configure.sh'
alias oc-wa-login='$OPENCLAW_HOME/scripts/onboard-whatsapp.sh'
alias oc-onboard-tg='$OPENCLAW_HOME/scripts/onboard-telegram.sh'
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

## Perfil WhatsApp dedicado + browser

Esse perfil nao substitui a operacao local pelo PC. Ele adiciona um caminho oficial para ter:

- um numero dedicado de WhatsApp como superficie remota;
- um browser separado da sua sessao pessoal;
- Google/Gemini apenas na superficie do agente;
- grupos sempre fechados por allowlist explicita.

O fluxo recomendado e:

1. `OPENCLAW_INSTALL_BROWSER=1` em `.env.local`;
2. preencher `secrets/openai_api_key.txt` e `secrets/gemini_api_key.txt`;
3. rebuildar com `./scripts/build.sh`;
4. rodar `./scripts/onboard-runtime.sh` para configurar provider, modelo e auth do gateway;
5. aplicar `./scripts/whatsapp-browser-enable.sh`;
6. preencher `allowFrom` / `groupAllowFrom` / `groups` com `./scripts/whatsapp-configure.sh`;
7. logar o numero dedicado com `./scripts/onboard-whatsapp.sh`.

Detalhes e exemplos concretos:

- [docs/whatsapp-dedicado-browser.md](docs/whatsapp-dedicado-browser.md)

## Canal opcional: Telegram

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
- usar uma chave Gemini separada se for habilitar `web_search` via Gemini;
- manter spend limit baixo;
- nao colocar segredos diretamente em `compose.yaml` ou em conversas desnecessarias;
- tratar `runtime/config` como sensivel;
- tratar `runtime/workspace` como memoria privada do agente;
- preferir VM ou host dedicado;
- publicar portas apenas em `127.0.0.1`;
- manter `tools.elevated.enabled = false` para este perfil;
- negar `exec` por default quando o sandbox estiver ativo;
- tratar Telegram como etapa opcional, nao como requisito de bootstrap;
- usar numero de WhatsApp dedicado, nao o pessoal, se escolher esse canal;
- usar conta Google dedicada dentro do browser `openclaw`, com permissoes minimas.

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
5. escolher entre local-first conservador ou WhatsApp dedicado + browser;
6. concluir o onboarding do provider e, se desejado, do Telegram ou do WhatsApp dedicado;
7. testar uma conversa ponta a ponta no fluxo escolhido.
