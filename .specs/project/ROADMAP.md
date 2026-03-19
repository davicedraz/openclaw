# Roadmap

**Current Milestone:** Runtime validation e consolidacao de governanca
**Status:** In Progress

---

## Milestone 1 - Scaffold local seguro

**Goal:** ter o runtime local buildavel e operavel com segredos em runtime e wrappers curtos
**Target:** `openclaw-gateway` sobe localmente e responde aos checks basicos sem depender de Telegram

### Features

**Imagem local e compose base** - COMPLETE

- Buildar `openclaw:local` a partir de `vendor/openclaw`
- Subir `openclaw-gateway` com `--allow-unconfigured`
- Persistir `runtime/config` e `runtime/workspace`

**Segredos em runtime** - COMPLETE

- Montar `openai_api_key` via Docker secrets
- Montar `gemini_api_key` apenas quando o arquivo local existir
- Evitar `OPENAI_API_KEY` inline em `compose.yaml`

**Ergonomia operacional local** - COMPLETE

- Fornecer wrappers curtos para `build`, `up`, `down`, `ps`, `logs`, `health`, `status`, `tui` e `dashboard`
- Reusar `scripts/compose.sh` como ponto central de orquestracao

---

## Milestone 2 - Runtime validation e memoria viva do projeto

**Goal:** validar o runtime de ponta a ponta e tornar `.specs/` a fonte oficial de contexto operacional
**Target:** provider/canal configurados, conversa real validada e proximo trabalho planejado integralmente em `.specs/`

### Features

**Onboarding base do runtime** - IN PROGRESS

- Preencher `secrets/openai_api_key.txt` com uma key valida
- Rodar o onboarding do runtime pelo CLI
- Validar uma conversa real ponta a ponta

**Migracao para `tlc-spec-driven`** - COMPLETE

- Criar `.specs/project/*` e `.specs/codebase/*`
- Consolidar o contexto e a memoria oficiais em `.specs/`
- Remover referencias documentais legadas do fluxo anterior
- Passar a planejar proximas features em `.specs/features/` ou `.specs/quick/`

**Hardening operacional minimo** - PLANNED

- Consolidar concerns do codebase e hotspots de manutencao
- Definir um check manual minimo por wrapper critico
- Reduzir pontos onde configuracao "parece" variavel mas ainda esta hardcoded

---

## Milestone 3 - WhatsApp dedicado + browser

**Goal:** sustentar um perfil oficial mais autonomo, mas ainda conservador
**Target:** login dedicado, allowlists explicitas, browser gerenciado e `web_search` funcional com Gemini

### Features

**Baseline WhatsApp dedicado + browser** - IN PROGRESS

- Aplicar `browser.enabled`, `browser.defaultProfile` e `browser.evaluateEnabled=false`
- Ligar `web_search` com Gemini e `web_fetch`
- Manter `exec` negado e `elevated` desligado

**Allowlists e grupos guiados** - IN PROGRESS

- Configurar owners em E.164
- Configurar grupos por JID com `requireMention=false`
- Manter placeholders fail-closed enquanto IDs reais nao existirem

**Login e validacao do canal** - PLANNED

- Rodar `./scripts/onboard-whatsapp.sh`
- Validar o browser e o canal com dados reais
- Confirmar comportamento conservador antes de jobs de background

---

## Milestone 4 - Telegram opcional e operacao estavel

**Goal:** manter Telegram como integracao posterior, sem acoplamento ao bootstrap local
**Target:** onboarding documentado e repetivel para quando o canal fizer sentido

### Features

**Telegram onboarding opcional** - PLANNED

- Rodar o onboarding pelo wrapper dedicado
- Manter allowlists conservadoras
- Validar o canal sem abrir grupos no primeiro momento

**Operacao diaria e runbooks** - PLANNED

- Consolidar runbooks para logs, status, dashboard e TUI
- Documentar verificacoes minimas antes de abrir novos canais

---

## Future Considerations

- Adicionar smoke tests automatizados para os wrappers shell e overlays de Compose
- Evoluir para um fluxo repetivel de provisionamento de host/VM sem embutir secrets
- Criar specs de feature em `.specs/features/` para validacao ponta a ponta, hardening e operacao dedicada
