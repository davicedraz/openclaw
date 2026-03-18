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

## Arquivos sensiveis

- `secrets/openai_api_key.txt`
  - nao ler por padrao
  - nao imprimir conteudo
  - so validar via metadados ou checks indiretos quando a tarefa exigir

## Invariantes importantes

- Nao trate Telegram como requisito para teste inicial. O fluxo local via PC vem antes.
- Nao coloque `OPENAI_API_KEY` inline em `compose.yaml`.
- Nao assuma que mudar `secrets/openai_api_key.txt` exige rebuild. So precisa reiniciar os containers.
- Nao refatore `vendor/openclaw` sem necessidade clara. Esse repo foi trazido para manter proximidade com o fluxo oficial.
- Nao reabra exploracao ampla do repo se a task puder ser resolvida lendo o spec + README.

## Prioridade maxima: seguranca e prevencao de leaks

Neste projeto, seguranca operacional e evitar vazamento de segredos tem prioridade acima de conveniencia, velocidade ou verbosidade de debug.

Assuma sempre que qualquer agent, subagent, skill, log, diff, screenshot, comando de shell, artefato OpenSpec ou resposta ao usuario pode vazar informacao sensivel se voce nao for deliberado.

### O que tratar como sensivel por padrao

- `secrets/openai_api_key.txt`
- qualquer valor de `OPENAI_API_KEY`
- arquivos em `runtime/config` que possam conter auth, tokens, pairing, session state ou credenciais
- output de onboarding, `docker logs`, `docker inspect`, `env`, `printenv`, traces e stack traces que possam ecoar secrets
- exemplos, snippets, diffs e artefatos gerados a partir de arquivos sensiveis

### Regras obrigatorias para qualquer agente

- Nunca exiba, cole, resuma literalmente ou repita o valor de nenhum secret, token, cookie, header de auth, QR payload ou credencial.
- Nunca peca ao usuario para colar secrets, tokens, cookies, QR payloads ou credenciais no chat. Peca path, nome da variavel, comportamento observado ou snippet redigido.
- Nunca use `cat`, `sed`, `awk`, `rg`, `jq`, `docker inspect`, `env` ou equivalente para despejar conteudo de arquivos/variaveis sensiveis sem necessidade critica e explicita.
- Quando precisar validar um secret, prefira checagens de presenca, tamanho, permissao, hash parcial irreversivel ou estado (`test -s`, `wc -c`, existencia do arquivo) em vez de ler o conteudo.
- Quando logs forem necessarios para debug, inspecione e compartilhe apenas trechos minimos e sempre redigidos.
- Nunca mova secrets para codigo versionado, `compose.yaml`, `.env`, fixtures, testes, propostas, designs, tasks ou exemplos.
- Nunca crie artefatos que copiem credenciais reais, mesmo "temporariamente".
- Se encontrar credencial em arquivo versionado, diff, log ou output nao redigido, pare, sinalize o risco e trate a remediacao como prioridade.
- Em caso de duvida entre observar mais contexto ou reduzir superficie de exposicao, escolha reduzir superficie de exposicao.

### Como operar com seguranca neste repo

- Prefira citar caminhos e fluxos (`secrets/openai_api_key.txt`, `/run/secrets/openai_api_key`) sem abrir o conteudo.
- Prefira descrever estrutura e comportamento de `runtime/config` sem imprimir arquivos internos, a menos que a tarefa dependa disso.
- Ao pedir ajuda ao usuario, peca snippets redigidos, nunca secrets brutos.
- Ao revisar mudancas, procure explicitamente por inline secrets, vazamento em logs, broadening de portas, permissoes excessivas e persistencia indevida de credenciais.
- Antes de finalizar qualquer tarefa que toque runtime, onboarding, logs, compose, scripts ou docs operacionais, faca um cheque mental: "isso aumenta risco de leak ou normaliza pratica insegura?".

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
5. preservar e reforcar o modelo de seguranca: segredo fora do versionamento e fora de outputs

## Checklist obrigatorio antes de dizer "pronto"

- verifique se nenhum secret real foi exposto na resposta, em snippets, em exemplos ou em artefatos gerados
- verifique se nenhuma sugestao incentiva colocar `OPENAI_API_KEY` inline, commitar secrets ou abrir portas alem do necessario
- verifique se logs, comandos e passos de validacao podem ser executados de forma redigida/minima
- se algo nao foi verificado para evitar ler material sensivel, diga isso explicitamente e explique a verificacao segura recomendada

Se precisar resumir o projeto em uma frase:

> Scaffold local para operar um gateway OpenClaw em VM/host dedicado com Docker Compose, segredo da OpenAI em runtime e teste local pelo PC antes de integrar Telegram.
