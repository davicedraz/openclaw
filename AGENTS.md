# AGENTS.md

## Objetivo deste arquivo

Este arquivo existe para acelerar a continuidade de contexto neste projeto sem obrigar o proximo agente a reler tudo ou a explorar o repo inteiro.

A regra aqui e simples: comecar pelo contexto mais condensado e normativo, e so depois abrir arquivos mais detalhados se a tarefa realmente pedir.

## Estado atual do projeto

Este projeto ja tem um scaffold funcional para rodar um gateway OpenClaw local com Docker Compose, usando build local a partir de `vendor/openclaw`.

O que ja existe e importa:

- imagem local `openclaw:local` ja foi buildada com sucesso em uma sessao anterior
- o gateway foi ajustado para subir com `--allow-unconfigured` antes do onboarding completo
- operacao local pelo PC ja foi preparada com wrappers curtos
- o segredo da OpenAI entra em runtime por `secrets/openai_api_key.txt`
- Telegram continua sendo etapa posterior, nao pre-requisito para operar localmente
- o OpenSpec deste projeto hoje e um mapa do estado atual, nao uma change com `proposal/design/tasks`

## Ordem de leitura recomendada

Leia nesta ordem e pare assim que tiver contexto suficiente:

1. `openspec/specs/local-openclaw-gateway/spec.md`
   - fonte mais curta e normativa sobre o que o projeto ja e hoje

2. `README.md`
   - fonte principal de operacao
   - explica setup, fluxo de subida, monitoramento, TUI, dashboard e wrappers

3. `docs/notes.md`
   - observacoes curtas de produto/seguranca que ajudam a nao perder decisoes importantes

4. `docs/telegram-onboarding.md`
   - so se a tarefa envolver Telegram ou onboarding

5. `compose.yaml`
   - so se a tarefa envolver runtime, portas, volumes, secrets ou servicos

6. `scripts/`
   - so se a tarefa envolver fluxo operacional, entrypoints ou ergonomia de uso

7. `secrets/README.md`
   - so se a tarefa envolver manuseio da `OPENAI_API_KEY`

8. `vendor/openclaw/`
   - abrir apenas se a tarefa exigir entender comportamento upstream do OpenClaw
   - evitar explorar o repo vendorizado por padrao

9. nota externa de pesquisa sobre WhatsApp/Telegram
   - usar apenas quando for importante resgatar rationale, trade-offs e pesquisa comparativa

## Arquivos centrais

- `README.md`
- `compose.yaml`
- `openspec/specs/local-openclaw-gateway/spec.md`
- `docs/telegram-onboarding.md`
- `docs/notes.md`
- `scripts/compose.sh`
- `scripts/gateway-entrypoint.sh`
- `scripts/_load-openai-secret.sh`
- `secrets/openai_api_key.txt`

## Invariantes importantes

- Nao trate Telegram como requisito para teste inicial. O fluxo local via PC vem antes.
- Nao coloque `OPENAI_API_KEY` inline em `compose.yaml`.
- Nao assuma que mudar `secrets/openai_api_key.txt` exige rebuild. So precisa reiniciar os containers.
- Nao refatore `vendor/openclaw` sem necessidade clara. Esse repo foi trazido para manter proximidade com o fluxo oficial.
- Nao reabra exploracao ampla do repo se a task puder ser resolvida lendo o spec + README.

## Como operar rapidamente

Os wrappers curtos em `scripts/` sao a interface principal deste scaffold:

- `./scripts/build.sh`
- `./scripts/up.sh`
- `./scripts/down.sh`
- `./scripts/ps.sh`
- `./scripts/docker-logs.sh`
- `./scripts/health.sh`
- `./scripts/status.sh`
- `./scripts/logs.sh`
- `./scripts/tui.sh`
- `./scripts/dashboard.sh`
- `./scripts/onboard-telegram.sh`

Modelo mental correto:

- Docker sobe a infra
- `openclaw-gateway` e o servidor
- TUI, dashboard e CLI sao clientes locais
- Telegram e um canal opcional adicional

## Ponto em que o projeto esta

Infra e operacao local:

- scaffold local criado
- compose alinhado ao fluxo oficial do OpenClaw
- imagem local buildavel
- wrappers curtos criados
- OpenSpec criado como mapa do estado atual

Ainda pendente para uso real com modelo:

- preencher `secrets/openai_api_key.txt` com uma key valida
- rodar onboarding do provider/canal
- validar conversa real ponta a ponta
- validar Telegram se essa etapa for escolhida

## Armadilhas ja conhecidas

- Sem `--allow-unconfigured`, o gateway pode entrar em restart loop antes do onboarding.
- `onboard-telegram.sh` foi feito para falhar cedo se a key estiver vazia.
- A build da imagem nao depende da key da OpenAI.
- O OpenSpec CLI pode emitir erros de telemetria de rede; isso nao invalida o spec local.

## Quando aprofundar

Abra o repo vendorizado do OpenClaw apenas se uma destas condicoes for verdadeira:

- voce precisa entender um comando/flag especifico do upstream
- voce precisa alinhar nosso scaffold com uma mudanca recente do OpenClaw
- voce precisa debugar um comportamento que o README e o spec nao explicam

Se nada disso for verdade, prefira ficar no contexto deste projeto.

## Expectativa para o proximo agente

Antes de propor qualquer mudanca, assuma este fluxo:

1. entender o estado atual pelo spec
2. entender o fluxo operacional pelo README
3. mudar o minimo que resolve
4. preservar o desenho atual: local-first, secrets em runtime, Telegram como etapa posterior

Se precisar resumir o projeto em uma frase:

> Scaffold local para operar um gateway OpenClaw em VM/host dedicado com Docker Compose, segredo da OpenAI em runtime e teste local pelo PC antes de integrar Telegram.
