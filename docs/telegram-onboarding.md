# Telegram Onboarding

Objetivo: ligar Telegram como canal opcional, sem virar prerequisito do runtime local.

## Antes de rodar

- preencha `secrets/openai_api_key.txt` com a sua Project API key;
- revise `.env.local`;
- confirme que o gateway vai publicar portas apenas em `127.0.0.1`.

## 1. Build da imagem

```bash
./scripts/compose.sh build
```

## 2. Onboarding inicial

```bash
./scripts/onboard-telegram.sh
```

Durante o onboarding:

- escolha OpenAI como provider;
- escolha um modelo inicial barato o suficiente para experimentacao;
- configure autenticacao do gateway;
- habilite Telegram se este for o canal escolhido agora;
- prefira `dmPolicy = allowlist` ou `pairing`;
- evite grupos no primeiro momento.

## 3. Criar o bot do Telegram

- abra `@BotFather`;
- crie o bot;
- copie o bot token;
- forneca o token ao OpenClaw no onboarding/config.

## 4. Subir o gateway

```bash
./scripts/compose.sh up -d openclaw-gateway
```

## 5. Validar

```bash
./scripts/compose.sh logs -f openclaw-gateway
```

Depois, na sessao/conversa:

```text
/status
/usage full
```

## 6. Endurecimento minimo

- mantenha apenas seu user id/chat id na allowlist;
- deixe grupos desabilitados ate a operacao ficar estavel;
- trate `runtime/config` como sensivel;
- se for mandar dado sensivel, minimize/redija antes quando possivel.
