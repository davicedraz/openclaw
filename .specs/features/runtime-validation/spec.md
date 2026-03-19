# Runtime Validation Specification

## Problem Statement

O scaffold local ja builda e sobe o gateway, mas o projeto ainda nao provou o fluxo mais importante: onboarding real do provider e uma conversa local ponta a ponta com resposta do modelo. Enquanto isso continuar sem validacao rastreavel, mudancas em `compose*.yaml`, `scripts/` e docs continuam com confianca parcial e troubleshooting mais caro do que deveria.

## Goals

- [ ] Validar o caminho `local-first conservador` do inicio ao fim, usando `OPENAI_API_KEY` em runtime e sem depender de Telegram ou WhatsApp.
- [ ] Tornar repetivel a verificacao minima de `up`, `health`, `status`, logs, onboarding e interacao local via TUI/dashboard.
- [ ] Confirmar que restart de container preserva a configuracao essencial em `runtime/config` sem rebuild.

## Out of Scope

Explicitamente fora de escopo para evitar diluicao da primeira spec.

| Feature | Reason |
| --- | --- |
| Smoke tests automatizados do scaffold raiz | E uma frente separada de hardening, ja registrada em `.specs/project/STATE.md` |
| Validacao do perfil `WhatsApp dedicado + browser` | Depende de Gemini, login real e baseline proprio do milestone 3 |
| Telegram onboarding | Continua opcional e posterior ao bootstrap local |
| Refactors em `vendor/openclaw` | Fogem do boundary operacional deste repo |

---

## User Stories

### P1: Onboarding local-first com resposta real ⭐ MVP

**User Story**: As a operador tecnico, I want configurar provider, modelo e auth pelo onboarding oficial e obter uma resposta real via TUI ou dashboard so that eu prove que o gateway funciona de verdade sem "magica".

**Why P1**: Isso desbloqueia o blocker mais importante do projeto e valida o objetivo central da milestone 2.

**Acceptance Criteria**:

1. WHEN `secrets/openai_api_key.txt` estiver ausente ou vazio THEN o fluxo SHALL falhar cedo com mensagem segura, sem imprimir credenciais.
2. WHEN o operador executar `./scripts/onboard-runtime.sh` com secret valido THEN o runtime SHALL permitir configurar provider, modelo e auth sem editar arquivos versionados.
3. WHEN o gateway estiver ativo e o onboarding concluido THEN o operador SHALL conseguir enviar uma mensagem via `./scripts/tui.sh` ou dashboard e receber uma resposta real do modelo.
4. WHEN o gateway for reiniciado apos o onboarding THEN o runtime SHALL manter a configuracao necessaria para voltar a responder sem rebuild.

**Independent Test**: Subir o gateway, fazer onboarding, enviar um prompt real, reiniciar os containers e repetir o prompt com sucesso.

---

### P2: Observabilidade minima e diagnostico seguro

**User Story**: As a operador tecnico, I want um roteiro curto de verificacao e diagnostico para diferenciar falha de infra, onboarding ou provider sem despejar dados sensiveis.

**Why P2**: Isso reduz falso positivo e evita debug "cego" em wrappers e overlays que hoje concentram boa parte do risco operacional.

**Acceptance Criteria**:

1. WHEN o operador rodar `./scripts/up.sh`, `./scripts/health.sh` e `./scripts/status.sh --all` THEN o sistema SHALL oferecer sinais suficientes para dizer se o gateway esta de pe antes da conversa real.
2. WHEN o operador rodar `./scripts/docker-logs.sh` ou `./scripts/logs.sh --json` THEN o processo SHALL permitir diagnostico basico sem exigir leitura direta de `runtime/config` nem de secrets.
3. WHEN a validacao falhar por onboarding incompleto, provider invalido ou restart loop THEN o roteiro SHALL indicar qual comando usar para localizar a categoria da falha.

**Independent Test**: Simular pelo menos um caso de falha segura e um caso de sucesso usando apenas wrappers, logs redigidos e checks indiretos.

---

### P3: Resultado registrado na memoria viva do projeto

**User Story**: As a mantenedor do projeto, I want registrar o resultado da validacao e os gaps remanescentes em `.specs/` so that a proxima iteracao parta de memoria viva, nao de lembranca.

**Why P3**: Sem esse fechamento, o projeto volta a depender de contexto oral e o TLC perde parte do valor.

**Acceptance Criteria**:

1. WHEN a validacao local-first for concluida THEN `.specs/project/STATE.md` SHALL registrar o que foi realmente provado e o que continua pendente.
2. WHEN parte do fluxo continuar pendente THEN a spec SHALL explicitar o gap remanescente e o motivo.

**Independent Test**: Um novo agente consegue abrir `.specs/project/STATE.md` e entender o status real da validacao sem reexplorar o repo inteiro.

---

## Edge Cases

- WHEN `secrets/openai_api_key.txt` contiver apenas whitespace THEN o wrapper SHALL tratar o arquivo como vazio e falhar cedo.
- WHEN o gateway subir com `--allow-unconfigured` antes do onboarding THEN o diagnostico SHALL apontar runtime nao configurado em vez de sugerir rebuild.
- WHEN `health` responder mas o prompt real falhar THEN o roteiro SHALL separar "infra viva" de "provider/model/auth incorretos".
- WHEN o operador trocar o secret da OpenAI THEN o fluxo SHALL exigir restart, nao rebuild.
- WHEN logs ou evidencias contiverem dados sensiveis THEN o processo SHALL compartilhar apenas trechos minimos e redigidos.

---

## Requirement Traceability

Cada requisito recebe um ID para rastreabilidade entre spec, tasks e validacao.

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| RTVAL-01 | P1: precondicao segura do secret | Tasks | Pending |
| RTVAL-02 | P1: onboarding pelo wrapper oficial | Tasks | Pending |
| RTVAL-03 | P1: resposta real via superficie local | Tasks | Pending |
| RTVAL-04 | P1: persistencia apos restart | Tasks | Pending |
| RTVAL-05 | P2: checklist de pre-flight operacional | Tasks | Pending |
| RTVAL-06 | P2: diagnostico seguro e categorizado | Tasks | Pending |
| RTVAL-07 | P3: registro do resultado em `.specs/` | Tasks | Pending |

**Coverage:** 7 total, 7 mapeados para `tasks.md`, 0 sem mapeamento.

---

## Success Criteria

Como saberemos que essa feature cumpriu seu papel:

- [ ] Um operador consegue provar o caminho `local-first conservador` sem editar arquivos versionados alem do secret local.
- [ ] Um restart do gateway nao exige rebuild para manter a configuracao validada.
- [ ] Existe um roteiro curto capaz de separar falha de infra, onboarding e provider com baixo risco de leak.
- [ ] O estado do projeto aponta claramente o que ficou validado e o que ainda pertence a milestones posteriores.
