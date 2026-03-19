# Codebase Concerns

**Analysis Date:** 2026-03-19

## Tech Debt

**Portas "configuraveis" mas parcialmente hardcoded:**

- Issue: `.env.example` expone `OPENCLAW_GATEWAY_PORT` e `OPENCLAW_BRIDGE_PORT`, mas o root ainda fixa `--port "18789"` no entrypoint e fixa as portas internas `18789`/`18790` no Compose
- Files: `.env.example`, `compose.yaml`, `scripts/gateway-entrypoint.sh`
- Why: o scaffold foi simplificado para um baseline estavel sem concluir a parametrizacao ponta a ponta
- Impact: mudar essas vars pode gerar falsa expectativa de configurabilidade e troubleshooting desnecessario
- Fix approach: ou remover as vars nao usadas do surface area, ou consumir esses valores de forma consistente no entrypoint e no Compose

## Security Considerations

**Estado vivo sensivel dentro da arvore do repo:**

- Risk: `runtime/config` e `runtime/workspace` podem conter auth, pairing, session state e artefatos do browser
- Files: `runtime/config/`, `runtime/workspace/`, `AGENTS.md`, `docs/telegram-onboarding.md`
- Current mitigation: documentacao reforca que esses caminhos sao sensiveis e o projeto evita exibir seus conteudos
- Recommendations: continuar evitando `cat`/dump desses diretorios, revisar `.gitignore`/diffs antes de commits e preferir checks indiretos ao depurar

**Validacao de secret le o valor completo em shell:**

- Risk: `scripts/onboard-telegram.sh` le o arquivo inteiro para verificar se a key nao esta vazia
- Files: `scripts/onboard-telegram.sh`
- Current mitigation: o valor nao e impresso nem propagado ao output
- Recommendations: considerar `test -s` ou uma checagem de tamanho/metadado quando o requisito nao depender de remover whitespace

## Fragile Areas

**`scripts/compose.sh` como choke point operacional:**

- Files: `scripts/compose.sh`, `compose.yaml`, `compose.sandbox.yaml`, `compose.whatsapp-browser.yaml`
- Why fragile: quase todos os wrappers passam por ele e seu comportamento muda com `.env.local`, existencia do secret Gemini e Docker socket
- Common failures: overlay errado, sandbox habilitado sem socket, GID do Docker nao detectado, diferenca de comportamento entre maquinas
- Safe modification: mudar uma coisa por vez e sempre verificar `build`, `up`, `health`, `status` e pelo menos um `run --rm openclaw-cli ...`
- Test coverage: nao ha smoke tests automatizados no root cobrindo esse choke point

**Wrappers que montam JSON manualmente em shell:**

- Files: `scripts/sandbox-enable.sh`, `scripts/whatsapp-browser-enable.sh`, `scripts/whatsapp-configure.sh`
- Why fragile: concatenacao manual de JSON em shell e facil de quebrar quando surgem novos campos, escapes ou politicas
- Common failures: JSON malformado, overwrite acidental de config persistida, regressao de policy
- Safe modification: testar com um runtime descartavel ou revisar o JSON efetivo antes de aplicar em ambiente com estado importante
- Test coverage: nenhuma suite automatizada dedicada no root

## Missing Critical Features

**Smoke tests do scaffold raiz:**

- Problem: wrappers e overlays de Compose sao parte critica do produto, mas nao possuem verificacao automatizada propria
- Current workaround: validacao manual documentada no README e nos runbooks
- Blocks: refactors seguros em `scripts/` e `compose*.yaml`
- Implementation complexity: Media; um smoke suite com Docker local controlado ja reduziria bastante risco

## Test Coverage Gaps

**Fluxos de endurecimento e canais:**

- What's not tested: `sandbox-enable`, `whatsapp-browser-enable`, `whatsapp-configure`, login de canal e mutacoes de config
- Risk: politicas conservadoras podem parecer aplicadas sem realmente estarem consistentes no runtime
- Priority: High
- Difficulty to test: Media/Alta, porque depende de Docker, estado persistido e integracoes reais

## Known Bugs

**`sandbox-enable.sh` sobrescreve `tools.deny` em vez de fazer merge:**

- Symptoms: aplicar o baseline de sandbox pode apagar denies preexistentes e deixar apenas `["exec"]`
- Trigger: rodar `./scripts/sandbox-enable.sh` em um runtime que ja tinha outras entradas em `tools.deny`
- Files: `scripts/sandbox-enable.sh`, `README.md`
- Workaround: revisar `tools.deny` manualmente depois de aplicar o baseline
- Root cause: o batch JSON do script escreve `tools.deny` como array fixo, diferente da estrategia de merge usada em `whatsapp-browser-enable.sh`
- Blocked by: nenhuma dependencia externa; e um ajuste local possivel
