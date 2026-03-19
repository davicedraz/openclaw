# State

**Last Updated:** 2026-03-19T03:31:17Z
**Current Work:** Feature specification - `runtime-validation`

---

## Recent Decisions (Last 60 days)

### AD-001: `tlc-spec-driven` virou a fonte oficial de planejamento (2026-03-19)

**Decision:** O projeto passa a usar `.specs/` como casa oficial de visao, roadmap, memoria e futuros trabalhos.
**Reason:** O contexto do projeto precisava ficar concentrado em uma unica casa, com melhor continuidade entre planejamento, execucao e memoria viva.
**Trade-off:** A consolidacao exigiu reancorar docs e referencias internas na estrutura nova de `.specs/`.
**Impact:** Novas features e quick tasks devem nascer em `.specs/features/` ou `.specs/quick/`.

### AD-002: A migracao de processo nao muda a arquitetura operacional (2026-03-19)

**Decision:** O projeto continua local-first, com segredos em runtime, wrappers shell e Telegram tratado como etapa posterior.
**Reason:** Misturar mudanca de governanca com refatoracao tecnica aumentaria risco e perderia rastreabilidade.
**Trade-off:** Continuamos dependentes de Docker local, estado persistido em volume e validacao manual para boa parte dos fluxos.
**Impact:** `.specs/` precisa refletir o desenho atual em vez de reimaginar o projeto.

### AD-003: `vendor/openclaw` continua como boundary de customizacao minima (2026-03-19)

**Decision:** A customizacao deve seguir concentrada em `compose*.yaml`, `scripts/`, docs e artefatos em `.specs/`.
**Reason:** O vendor foi trazido para manter proximidade com o fluxo oficial do OpenClaw e reduzir manutencao de fork.
**Trade-off:** Algumas limitacoes do upstream continuam sendo contornadas por wrappers e documentacao local.
**Impact:** Qualquer proposta que toque `vendor/openclaw` deve ser tratada como excecao, nao como caminho padrao.

### AD-004: A primeira feature formal prioriza a validacao local-first do runtime (2026-03-19)

**Decision:** A primeira spec em `.specs/features/` passa a ser `runtime-validation`, focada em onboarding real, conversa local ponta a ponta e verificacao segura.
**Reason:** O blocker mais importante do projeto continua sendo a ausencia de validacao real com provider configurado.
**Trade-off:** Smoke tests automatizados e validacao dos canais ficam explicitamente para iteracoes posteriores.
**Impact:** A proxima execucao relevante deve partir de `.specs/features/runtime-validation/` antes de abrir novas frentes amplas.

---

## Active Blockers

### B-001: Falta validacao ponta a ponta com provider real

**Discovered:** 2026-03-19
**Impact:** O scaffold esta funcional, mas ainda nao ha confirmacao de conversa real com modelo/canal neste repo.
**Workaround:** Validar `build`, `up`, `health`, `status`, `logs`, TUI e dashboard sem expor secrets.
**Resolution:** Preencher a key real, rodar onboarding do runtime e executar uma conversa de teste controlada.

### B-002: Wrappers shell criticos ainda nao tem smoke tests automatizados

**Discovered:** 2026-03-19
**Impact:** Mudancas em `scripts/compose.sh`, overlays de Compose ou JSONs em shell podem quebrar fluxo operacional sem feedback rapido.
**Workaround:** Fazer validacao manual dirigida sempre que mexer em compose/scripts.
**Resolution:** Criar uma camada minima de smoke tests ou scripts de verificacao automatica para o root do projeto.

---

## Lessons Learned

### L-001: Trocar o secret da OpenAI nao exige rebuild

**Context:** O projeto usa Docker secrets montados em runtime.
**Problem:** Havia risco de assumir rebuild como necessario a cada troca de chave.
**Solution:** Reiniciar os containers faz o runtime reler o arquivo montado.
**Prevents:** rebuilds desnecessarios e passos operacionais mais caros que o preciso.

### L-002: `scripts/compose.sh` e o choke point do scaffold

**Context:** Quase todos os wrappers delegam para `scripts/compose.sh`.
**Problem:** Mudancas pequenas nesse arquivo repercutem em todos os fluxos operacionais.
**Solution:** Tratar `scripts/compose.sh` como area fragil e sempre verificar overlays, socket Docker e secrets opcionais quando ele mudar.
**Prevents:** regressao silenciosa em `build`, `up`, `health`, `status`, `logs`, onboarding e wrappers de canal.

---

## Quick Tasks Completed

| #   | Description                                              | Date       | Commit | Status  |
| --- | -------------------------------------------------------- | ---------- | ------ | ------- |
| 001 | Inicializar `.specs/` e migrar a memoria do repo para TLC | 2026-03-19 | -      | Done    |
| 002 | Remover referencias legadas de planejamento do repo       | 2026-03-19 | -      | Done    |

---

## Deferred Ideas

- [ ] Criar um smoke test para `scripts/compose.sh` com combinacoes de overlay (`sandbox` e `gemini`) — Captured during: migracao para `tlc-spec-driven`

---

## Todos

- [ ] Aprovar e executar `.specs/features/runtime-validation/tasks.md`
- [ ] Padronizar uma sequencia minima de verificacao manual para mudancas em `compose*.yaml` e `scripts/`

---

## Preferences

**Model Guidance Shown:** never
