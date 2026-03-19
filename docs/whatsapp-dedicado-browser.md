# WhatsApp dedicado + browser

Guia operacional para transformar este scaffold no perfil "numero dedicado + browser local gerenciado", mantendo o baseline conservador do projeto.

## Objetivo

Esse perfil oficializa um setup com:

- numero de WhatsApp separado do pessoal;
- browser local isolado no perfil `openclaw`;
- `web_search` com Gemini;
- `web_fetch` habilitado;
- grupos fechados por allowlist explicita;
- `exec` negado e `elevated` desligado.

## Quando usar esse caminho

Use este perfil quando voce quer um agente mais autonomo e sempre disponivel, mas ainda com superficie controlada:

- entrada principal pelo WhatsApp do agente, nao pelo seu numero pessoal;
- browser dedicado para logins e operacao web;
- poucos jobs em background, todos em sessoes `isolated`;
- nenhum anuncio automatico em grupo na v1.

Se voce ainda quer validar o runtime com a menor superficie possivel, prefira o caminho local-first do `README.md`.

## Pre-requisitos

### 1. Ajustar `.env.local`

Parta de:

```bash
cp .env.example .env.local
```

Revise pelo menos:

- `OPENCLAW_INSTALL_BROWSER=1`
- `OPENCLAW_INSTALL_DOCKER_CLI=1`
- `OPENCLAW_SANDBOX_ENABLE=1`
- `OPENCLAW_HOST_PORT`
- `OPENCLAW_GATEWAY_BIND`

`OPENCLAW_INSTALL_BROWSER=1` e o toggle que embute Chromium/Xvfb na imagem local. Sem ele, o browser pode depender de bootstrap adicional em runtime.

### 2. Criar os secrets

Crie:

```text
secrets/openai_api_key.txt
secrets/gemini_api_key.txt
```

Formato:

- uma chave por arquivo;
- uma unica linha;
- nada de aspas ou prefixos extras.

## Ordem recomendada

### 1. Rebuildar a imagem

```bash
./scripts/build.sh
```

### 2. Subir o gateway

```bash
./scripts/up.sh
```

### 3. Fazer o onboarding base do runtime

```bash
./scripts/onboard-runtime.sh
```

Objetivo desta etapa:

- configurar provider e modelo;
- definir a autenticacao do gateway;
- manter Telegram desabilitado se esse nao for o canal escolhido agora.

### 4. Aplicar o baseline do perfil

```bash
./scripts/whatsapp-browser-enable.sh
```

Esse wrapper faz quatro coisas:

- fixa `browser.enabled = true`;
- fixa `browser.defaultProfile = "openclaw"` e `browser.evaluateEnabled = false`;
- liga `tools.web.search.enabled = true`, `tools.web.search.provider = "gemini"` e mantem `tools.web.fetch.enabled = true`;
- fixa `channels.whatsapp.dmPolicy = "allowlist"` e `channels.whatsapp.groupPolicy = "allowlist"`.

Ele tambem trabalha de forma fail-closed:

- adiciona `exec` em `tools.deny` sem remover outros denies;
- mantem `tools.elevated.enabled = false`;
- se `allowFrom` ou `groupAllowFrom` ainda nao existem, cria placeholders `__PREENCHER_OWNER_E164__`;
- se `groups` ainda nao existe, cria `channels.whatsapp.groups` com o placeholder `__PREENCHER_GROUP_JID__`.

Ele tambem se recusa a aplicar o perfil se encontrar wildcards ja abertos em:

- `channels.whatsapp.allowFrom`
- `channels.whatsapp.groupAllowFrom`
- `channels.whatsapp.groups."*"`

Nessa situacao, a ideia e simples: primeiro fechar a superficie, depois aplicar o perfil.

Importante:

- os placeholders em `allowFrom` e `groupAllowFrom` deixam DM/grupo efetivamente bloqueados ate voce substituir pelos IDs reais.
- o placeholder `__PREENCHER_GROUP_JID__` impede que qualquer grupo real entre no allowlist ate voce trocar pelos JIDs corretos.

### 5. Substituir os placeholders do owner

Caminho recomendado:

```bash
./scripts/whatsapp-configure.sh
```

Esse wrapper guiado:

- mostra os valores atuais;
- pede os owners em E.164;
- deixa voce escolher se `groupAllowFrom` reaproveita os owners ou usa outra lista;
- pede os JIDs dos grupos permitidos;
- repete o prompt se voce digitar E.164/JID invalido;
- grava cada grupo com `requireMention=false`;
- mantem o placeholder fail-closed se voce ainda nao tiver os JIDs reais;
- aceita `-` no prompt de grupos para voltar explicitamente ao bloqueio fail-closed.

Fallback manual, se voce quiser controle total:

Exemplo para um owner em E.164:

```bash
./scripts/compose.sh run --rm openclaw-cli \
  config set channels.whatsapp.allowFrom '["+5511999999999"]' --strict-json

./scripts/compose.sh run --rm openclaw-cli \
  config set channels.whatsapp.groupAllowFrom '["+5511999999999"]' --strict-json
```

Se houver mais de um operador autorizado, use todos no mesmo array.

## Grupos allowlisted com ativacao "always"

No upstream, a ativacao padrao de grupo passa a funcionar como `always` quando `requireMention=false` no grupo configurado.

Entao, para liberar grupos de forma explicita e sempre ativa, preencha `channels.whatsapp.groups` com cada JID permitido e `requireMention=false`.

Exemplo:

```bash
./scripts/compose.sh run --rm openclaw-cli \
  config set channels.whatsapp.groups '{
    "120363012345678901@g.us": { "requireMention": false },
    "120363098765432109@g.us": { "requireMention": false }
  }' --strict-json
```

O passo pratico e sempre substituir o placeholder inteiro pelo mapa real de grupos.

Modelo mental correto:

- `channels.whatsapp.groups` controla quais grupos existem no allowlist;
- `channels.whatsapp.groupAllowFrom` controla quem pode acionar o bot dentro desses grupos;
- `requireMention=false` em cada grupo torna a ativacao efetiva equivalente a `always` para aquele grupo.

Nao use:

- `groupPolicy = "open"`
- `allowFrom = ["*"]`
- `groupAllowFrom = ["*"]`
- `groups."*"` neste baseline

O wildcard `groups."*"` liberaria todos os grupos, o que vai contra este perfil.

## Login do WhatsApp dedicado

Depois do baseline e dos allowlists:

```bash
./scripts/onboard-whatsapp.sh
```

Isso executa:

```bash
openclaw channels login --channel whatsapp
```

Esse wrapper faz apenas o login do canal. Ele nao substitui o onboarding base do runtime.

Fluxo esperado:

- o CLI mostra um QR;
- voce escaneia com o numero dedicado do agente;
- as credenciais ficam persistidas em `runtime/config` / `~/.openclaw` dentro do volume.

Se precisar relogar:

```bash
./scripts/onboard-whatsapp.sh --verbose
```

## Browser dedicado e conta Google

Depois do rebuild + baseline, valide o browser:

```bash
./scripts/compose.sh run --rm openclaw-cli browser status --json
./scripts/compose.sh run --rm openclaw-cli browser start
./scripts/compose.sh run --rm openclaw-cli browser open https://example.com
./scripts/compose.sh run --rm openclaw-cli browser snapshot
```

Diretriz operacional:

- use a conta Google do agente, nao a sua conta pessoal;
- trate o perfil `openclaw` como superficie separada;
- conceda o minimo de acesso necessario;
- mantenha `browser.evaluateEnabled=false` para reduzir superficie de prompt injection por JS arbitrario.

Validacao de guardrail:

```bash
./scripts/compose.sh run --rm openclaw-cli config get browser --json
```

Voce deve confirmar pelo menos:

- `enabled = true`
- `defaultProfile = "openclaw"`
- `evaluateEnabled = false`

## Validacao do web_search e web_fetch

Com `secrets/gemini_api_key.txt` presente, o wrapper `compose.sh` monta o secret Gemini no runtime automaticamente.

Checks uteis:

```bash
./scripts/compose.sh run --rm openclaw-cli config get tools.web.search --json
./scripts/compose.sh run --rm openclaw-cli config get tools.web.fetch --json
```

No runtime, valide a experiencia por TUI ou dashboard com um prompt que obrigue busca web real.

O que observar:

- `web_search` responde usando Gemini;
- `web_fetch` continua disponivel para paginas simples sem JS/login;
- `browser evaluate` e `wait --fn` nao devem ser parte do baseline.

## Primeiros jobs seguros

O baseline inicial deste repo assume poucos jobs e todos conservadores.

### Regra 1: so jobs `isolated`

Os comandos `cron add --message ...` ja caem em `sessionTarget="isolated"` por default no upstream.

### Regra 2: sem entrega por default

Para um job sem publicar nada em canal:

```bash
./scripts/compose.sh run --rm openclaw-cli cron add \
  --name "briefing-diario-local" \
  --every 1d \
  --message "Revise as pendencias do workspace e gere um resumo curto." \
  --no-deliver
```

### Regra 3: se entregar algo, entregue so ao owner DM

Exemplo:

```bash
./scripts/compose.sh run --rm openclaw-cli cron add \
  --name "briefing-owner-dm" \
  --every 1d \
  --message "Resuma os pontos mais importantes do dia em 5 bullets." \
  --announce \
  --channel whatsapp \
  --to +5511999999999
```

Fora do baseline v1:

- anuncios automaticos em grupos;
- jobs que dependem de `exec`;
- jobs com `elevated`;
- abrir grupos de forma ampla.

## Reinicio e verificacao final

Depois de ajustar allowlists/grupos e fazer login do WhatsApp:

```bash
./scripts/down.sh
./scripts/up.sh
./scripts/status.sh --all
./scripts/health.sh --json
./scripts/docker-logs.sh
```

Checklist final:

- browser sobe no perfil `openclaw`;
- `web_search` aponta para Gemini;
- `web_fetch` continua ativo;
- DM do owner responde;
- grupo nao allowlisted e ignorado;
- grupo allowlisted com `requireMention=false` funciona como always-on;
- `tools.deny` contem `exec`;
- `tools.elevated.enabled` segue `false`.
