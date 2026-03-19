# Secrets locais

Coloque aqui apenas arquivos sensiveis que **nao** devem ir para git.

## Arquivos esperados

- `openai_api_key.txt`
- `gemini_api_key.txt`

## Formato

Cada arquivo deve conter somente a key, em uma unica linha.

Uso tipico:

- `openai_api_key.txt`: provider principal do runtime;
- `gemini_api_key.txt`: `web_search` com Gemini no perfil WhatsApp dedicado + browser.

Exemplo:

```text
sk-proj-...
```

Observacao:

- quando `secrets/gemini_api_key.txt` existe, o wrapper `./scripts/compose.sh` passa a montar esse secret no gateway/CLI automaticamente.
