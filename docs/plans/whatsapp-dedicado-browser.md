# Plano: Perfil “Número Dedicado + Browser” para automação séria

## Resumo
Implementar no scaffold um perfil operacional explícito para OpenClaw com:
- WhatsApp em número dedicado
- Browser local isolado com perfil gerenciado pelo OpenClaw
- `web_search` com Gemini e `web_fetch` habilitado
- Grupos de WhatsApp em allowlist, com ativação sempre ativa
- Apenas poucos jobs em background, todos com guardrails conservadores
- Manter a postura atual de segurança: `exec` negado e `elevated` desligado

O resultado deve deixar esse caminho como um “modo oficial” do repo, sem depender de ajustes manuais obscuros no runtime.

## Mudanças principais

### 1. Runtime e segredos
- Estender `compose.yaml` e `.env.example` para suportar `OPENCLAW_INSTALL_BROWSER=1` no build do gateway/CLI.
- Generalizar o loader de secrets hoje focado em OpenAI para também exportar `GEMINI_API_KEY` a partir de um novo secret runtime, mantendo o mesmo princípio: segredo fora de `compose.yaml` e fora de `.env.local`.
- Documentar o novo arquivo de secret para Gemini no mesmo padrão de `secrets/openai_api_key.txt`.

### 2. Perfil operacional “WhatsApp dedicado + browser”
- Criar um baseline configurável para este perfil, aplicado por wrapper/script dedicado, sem sobrescrever escolhas sensíveis do usuário.
- Esse baseline deve configurar:
  - `browser.enabled = true`
  - `browser.defaultProfile = "openclaw"`
  - `browser.evaluateEnabled = false`
  - `tools.web.search.enabled = true`
  - `tools.web.search.provider = "gemini"`
  - manter `tools.deny = ["exec"]`
  - manter `tools.elevated.enabled = false`
- O wrapper não deve tentar adivinhar dados do usuário; ele deve deixar como pendências explícitas:
  - `channels.whatsapp.allowFrom`
  - `channels.whatsapp.groupAllowFrom`
  - `channels.whatsapp.groups`

### 3. Baseline de canal WhatsApp
- Promover o fluxo de WhatsApp dedicado a caminho de primeira classe no projeto, em vez de deixar só Telegram como onboarding documentado.
- Definir o baseline de canal assim:
  - DMs: `dmPolicy = "allowlist"`
  - Grupos: `groupPolicy = "allowlist"`
  - Grupos permitidos: apenas `channels.whatsapp.groups` explicitamente listados
  - Ativação dos grupos: `always`
  - Remetentes autorizados em grupos: `groupAllowFrom` explícito
- O baseline inicial deve assumir:
  - owner/operator principal em `allowFrom`
  - grupos vazios até o operador preencher os JIDs corretos
  - nada de `groupPolicy = "open"` ou `allowFrom = ["*"]`

### 4. Browser e pesquisa
- Usar browser local isolado, não browser remoto, não browserless e não sessão pessoal anexada.
- O browser deve ser tratado como superfície operacional separada, com conta Google dedicada e permissões mínimas.
- `browser.evaluateEnabled` deve nascer desligado para reduzir prompt injection por JS arbitrário; automação deve usar snapshot/click/type/upload/download por padrão.
- `web_search` deve nascer com Gemini como provider oficial deste perfil; `web_fetch` permanece disponível para páginas simples sem JS/login.

### 5. Jobs em background
- Incluir suporte inicial a “poucos jobs” com política fechada:
  - somente jobs `isolated`
  - por padrão `delivery.mode = "none"` ou entrega apenas ao DM do owner
  - sem anúncios automáticos em grupos na v1
- O runbook deve deixar explícito que background para grupos fica fora do baseline inicial, mesmo com grupos “always active”.

### 6. Docs e ergonomia
- Atualizar `README.md` para apresentar dois caminhos claros:
  - local-first conservador
  - WhatsApp dedicado + browser
- Corrigir a inconsistência documental atual entre Telegram como “primeiro” e Telegram como “opcional”.
- Adicionar um guia operacional dedicado para:
  - build com browser
  - ativação do baseline
  - login do WhatsApp dedicado
  - configuração da conta Google dedicada
  - preenchimento manual de `allowFrom`, `groupAllowFrom` e `groups`
  - primeiros jobs seguros

## Interfaces e contratos que mudam
- Novo toggle público de build:
  - `OPENCLAW_INSTALL_BROWSER`
- Novo secret runtime:
  - `secrets/gemini_api_key.txt` -> exporta `GEMINI_API_KEY`
- Novos caminhos/configs tratados como parte do perfil:
  - `browser.enabled`
  - `browser.defaultProfile`
  - `browser.evaluateEnabled`
  - `tools.web.search.enabled`
  - `tools.web.search.provider = "gemini"`
  - `channels.whatsapp.dmPolicy`
  - `channels.whatsapp.allowFrom`
  - `channels.whatsapp.groupPolicy`
  - `channels.whatsapp.groupAllowFrom`
  - `channels.whatsapp.groups`

## Plano de testes
- Build:
  - subir imagem com `OPENCLAW_INSTALL_BROWSER=1`
  - validar que gateway sobe sem regressão no modo atual
- Browser:
  - `openclaw browser status/start/snapshot`
  - screenshot/PDF funcionando
  - `browser evaluate` e `wait --fn` bloqueados por config
- WhatsApp DM:
  - número allowlisted recebe resposta
  - número não allowlisted não recebe execução normal
- WhatsApp grupos:
  - grupo não allowlisted é ignorado
  - grupo allowlisted dispara em `always`
  - remetente fora de `groupAllowFrom` não aciona
  - remetente allowlisted aciona
- Web:
  - `web_search` via Gemini retorna resposta com grounding/citações
  - `web_fetch` continua funcional
- Background:
  - job isolado executa
  - entrega padrão não publica em grupo
  - entrega ao owner DM funciona quando explicitamente configurada

## Assumptions e defaults
- O número dedicado será separado do seu WhatsApp pessoal.
- O browser será local ao runtime dedicado e usará perfil `openclaw`, não `user`.
- A conta Google do agente será separada e receberá acesso mínimo aos recursos online.
- O baseline inicial continua sem `exec` e sem `elevated`.
- O baseline inicial não libera grupos de forma aberta e não usa `*` em allowlists.
- A primeira versão com jobs terá poucos fluxos recorrentes e nenhum post automático em grupos.
