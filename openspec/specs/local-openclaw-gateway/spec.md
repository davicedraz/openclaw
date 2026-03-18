## Purpose

Mapear o estado atual do projeto `openclaw-personal-gateway` como um runtime local operável, com build Docker local, segredo de provider em runtime, operação pelo PC via TUI/dashboard/CLI e Telegram tratado como etapa posterior.

## Requirements

### Requirement: Build and run a local OpenClaw gateway from the vendored source tree
The project SHALL build a local Docker image for OpenClaw using the vendored upstream repository and run it with Docker Compose.

#### Scenario: Build the local image
- **WHEN** the operator runs `./scripts/build.sh`
- **THEN** Docker Compose SHALL build `openclaw:local` from `vendor/openclaw`

#### Scenario: Start the gateway locally
- **WHEN** the operator runs `./scripts/up.sh`
- **THEN** Docker Compose SHALL start the `openclaw-gateway` service
- **AND** the service SHALL run from the locally built `openclaw:local` image

#### Scenario: Allow local startup before onboarding completes
- **WHEN** the gateway starts without full OpenClaw runtime configuration
- **THEN** it SHALL start with `--allow-unconfigured`
- **AND** it SHALL avoid crash-looping only because configuration is still incomplete

#### Scenario: Persist operator state across restarts
- **WHEN** the gateway or CLI containers start
- **THEN** OpenClaw config SHALL persist under `runtime/config`
- **AND** OpenClaw workspace data SHALL persist under `runtime/workspace`

#### Scenario: Expose local-only ports
- **WHEN** the gateway is started through the project Compose file
- **THEN** ports `18789` and `18790` SHALL be published only on `127.0.0.1`

### Requirement: Load provider secrets at runtime from a local secret file
The project SHALL inject the OpenAI provider key at container runtime instead of baking it into the image or hardcoding it in Compose environment values.

#### Scenario: Mount the OpenAI secret at runtime
- **WHEN** `openclaw-gateway` or `openclaw-cli` starts
- **THEN** Docker Compose SHALL mount `secrets/openai_api_key.txt` as the `openai_api_key` secret
- **AND** the secret SHALL be available inside the container at `/run/secrets/openai_api_key`

#### Scenario: Export OPENAI_API_KEY from the mounted secret
- **WHEN** the entrypoint helper runs inside the container
- **THEN** it SHALL read `/run/secrets/openai_api_key`
- **AND** it SHALL export `OPENAI_API_KEY` when the file contains a non-empty key

#### Scenario: Change the provider key without rebuilding the image
- **WHEN** the operator updates `secrets/openai_api_key.txt`
- **THEN** the project SHALL not require a Docker image rebuild
- **AND** the updated key SHALL be picked up on container restart

### Requirement: Provide local operator workflows independent of Telegram
The project SHALL support operating and testing the gateway locally from the PC before Telegram onboarding is completed.

#### Scenario: Run local health and status checks
- **WHEN** the operator runs `./scripts/health.sh` or `./scripts/status.sh`
- **THEN** the project SHALL run the OpenClaw CLI against the running gateway

#### Scenario: Tail gateway logs through Docker
- **WHEN** the operator runs `./scripts/docker-logs.sh`
- **THEN** the project SHALL tail logs from the `openclaw-gateway` container

#### Scenario: Tail gateway logs through OpenClaw RPC
- **WHEN** the operator runs `./scripts/logs.sh`
- **THEN** the project SHALL tail gateway logs via the OpenClaw CLI

#### Scenario: Open a terminal UI connected to the gateway
- **WHEN** the operator runs `./scripts/tui.sh`
- **THEN** the project SHALL launch `openclaw tui` connected to the running gateway

#### Scenario: Open the local Control UI in a browser
- **WHEN** the gateway is running locally
- **THEN** the operator SHALL be able to access the Control UI at `http://127.0.0.1:18789/`
- **AND** `./scripts/dashboard.sh` SHALL expose the dashboard entry path through the CLI

#### Scenario: Provide short operator commands suitable for shell aliases
- **WHEN** the operator wants to drive the system from any terminal
- **THEN** the project SHALL provide short wrapper scripts for build, up, down, ps, health, status, logs, tui, dashboard, and Telegram onboarding

### Requirement: Keep Telegram onboarding as an optional next step
The project SHALL document Telegram as a later channel integration rather than a prerequisite for local operation.

#### Scenario: Document Telegram onboarding separately
- **WHEN** the operator is ready to add Telegram
- **THEN** the project SHALL provide a dedicated onboarding guide in `docs/telegram-onboarding.md`

#### Scenario: Allow local operation before Telegram exists
- **WHEN** Telegram has not yet been configured
- **THEN** the operator SHALL still be able to build the image, start the gateway, inspect status, inspect logs, and use the TUI or dashboard locally
