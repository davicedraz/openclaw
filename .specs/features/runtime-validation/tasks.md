# Runtime Validation Tasks

**Design**: skipped - fluxo operacional direto, sem nova arquitetura
**Status**: Draft

---

## Execution Plan

### Phase 1: Foundation (Sequential)

T1 -> T2 -> T3

### Phase 2: Runtime Proof (Sequential)

T4 -> T5 -> T6

### Phase 3: Closure (Sequential)

T7

---

## Task Breakdown

### T1: Confirmar precondicao segura do secret

**What**: Validar e documentar o comportamento esperado para `secrets/openai_api_key.txt` ausente, vazio ou com whitespace.
**Where**: `scripts/onboard-runtime.sh`, `secrets/README.md`, `README.md`
**Depends on**: None
**Reuses**: Padrao fail-fast dos wrappers shell
**Requirement**: RTVAL-01

**Tools**:

- MCP: NONE
- Skill: `tlc-spec-driven`

**Done when**:

- [ ] O fluxo de precondicao usa checks indiretos e nao pede secret inline
- [ ] O comportamento esperado para secret ausente/vazio esta documentado
- [ ] O comando `./scripts/onboard-runtime.sh` falha cedo e de forma segura nesse cenario

---

### T2: Validar baseline de subida e saude do gateway

**What**: Executar e registrar o checklist minimo de `up`, `ps`, `health` e `status`.
**Where**: `scripts/up.sh`, `scripts/ps.sh`, `scripts/health.sh`, `scripts/status.sh`, `README.md`
**Depends on**: T1
**Reuses**: Wrappers operacionais existentes
**Requirement**: RTVAL-05

**Tools**:

- MCP: NONE
- Skill: `tlc-spec-driven`

**Done when**:

- [ ] Existe uma ordem clara para rodar os wrappers basicos
- [ ] Cada comando tem um sinal de sucesso/falha esperado
- [ ] A validacao consegue dizer se a infra esta de pe antes do onboarding real

---

### T3: Definir o roteiro de diagnostico seguro

**What**: Padronizar como distinguir falha de infra, onboarding ou provider usando apenas wrappers e logs redigidos.
**Where**: `scripts/docker-logs.sh`, `scripts/logs.sh`, `README.md`, `.specs/project/STATE.md`
**Depends on**: T2
**Reuses**: Superficie atual de logs e status
**Requirement**: RTVAL-06

**Tools**:

- MCP: NONE
- Skill: `tlc-spec-driven`

**Done when**:

- [ ] O roteiro nao exige leitura direta de `runtime/config` nem de secrets
- [ ] Existe pelo menos um caminho claro para falha de onboarding e um para falha de provider
- [ ] O operador sabe qual comando usar primeiro, segundo e terceiro para triagem

---

### T4: Executar onboarding base do runtime

**What**: Validar o happy path do onboarding oficial com provider, modelo e auth configurados pelo wrapper dedicado.
**Where**: `scripts/onboard-runtime.sh`, runtime local
**Depends on**: T3
**Reuses**: CLI do OpenClaw via `openclaw-cli onboard`
**Requirement**: RTVAL-02

**Tools**:

- MCP: NONE
- Skill: `tlc-spec-driven`

**Done when**:

- [ ] O onboarding e concluido sem editar arquivos versionados
- [ ] Provider, modelo e auth ficam persistidos no runtime
- [ ] O passo a passo real fica claro para repeticao posterior

---

### T5: Validar conversa real por superficie local

**What**: Provar uma interacao local real via `tui` ou dashboard apos o onboarding.
**Where**: `scripts/tui.sh`, `scripts/dashboard.sh`, runtime local
**Depends on**: T4
**Reuses**: Superficies locais ja expostas pelo scaffold
**Requirement**: RTVAL-03

**Tools**:

- MCP: NONE
- Skill: `tlc-spec-driven`

**Done when**:

- [ ] Um prompt real recebe resposta do modelo
- [ ] A superficie usada para a prova fica registrada
- [ ] O fluxo nao depende de Telegram nem WhatsApp

---

### T6: Verificar persistencia apos restart

**What**: Reiniciar o runtime e confirmar que a configuracao validada continua funcionando sem rebuild.
**Where**: `scripts/down.sh`, `scripts/up.sh`, `scripts/health.sh`, `scripts/status.sh`, runtime local
**Depends on**: T5
**Reuses**: Persistencia existente em `runtime/config`
**Requirement**: RTVAL-04

**Tools**:

- MCP: NONE
- Skill: `tlc-spec-driven`

**Done when**:

- [ ] O restart ocorre sem rebuild da imagem
- [ ] O runtime volta a responder apos subir novamente
- [ ] O mesmo fluxo de conversa local continua funcionando

---

### T7: Registrar resultado e proximos passos na memoria viva

**What**: Atualizar `.specs/` com o resultado da validacao e o proximo trabalho desbloqueado.
**Where**: `.specs/project/STATE.md`, `.specs/project/ROADMAP.md`
**Depends on**: T6
**Reuses**: Estrutura de memoria viva do projeto
**Requirement**: RTVAL-07

**Tools**:

- MCP: NONE
- Skill: `tlc-spec-driven`

**Done when**:

- [ ] O resultado da validacao fica registrado de forma objetiva
- [ ] Os blockers remanescentes ficam explicitos
- [ ] A proxima feature ou quick task fica claramente identificada
