---
allowed-tools: Bash(curl:*), Bash(cat:*), Bash(source:*)
description: Add a new proxy host to Nginx Proxy Manager via API
---

## Your task

The user invoked `/npm-add` with the following arguments: $ARGUMENTS

Add a new proxy host to Nginx Proxy Manager using its REST API.

## Argument parsing

Parse `$ARGUMENTS` in the form:
```
<domain> <forward_host> <forward_port> [options]
```

Supported options:
- `--websockets` — enable WebSocket support
- `--no-ssl` — disable Force SSL (default: SSL forced on)
- `--scheme https` — upstream uses HTTPS (default: http)
- `--no-cert` — do not attach SSL certificate (implies `--no-ssl`)

Examples:
```
homelab.castamerego.com 192.168.50.71 4869
grafana.castamerego.com 192.168.50.71 7453 --websockets
internal.castamerego.com 192.168.50.71 9000 --no-ssl --no-cert
```

## Credential loading

1. Try to load from `/Users/wangxugang/Dev/Skills/npm-add.env`:
   ```bash
   source /Users/wangxugang/Dev/Skills/npm-add.env 2>/dev/null
   ```
2. If any of `NPM_URL`, `NPM_IDENTITY`, `NPM_SECRET` are still unset, ask the user for them before proceeding. Do NOT proceed with empty credentials.
3. Default `NPM_CERT_ID=4` if not set in env.

## Steps

### 1. Get API token

```bash
curl -s -X POST "$NPM_URL/api/tokens" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$NPM_IDENTITY\",\"secret\":\"$NPM_SECRET\"}"
```

Extract `.token` from the JSON response. If missing or error, report and stop.

### 2. Create proxy host

```bash
curl -s -X POST "$NPM_URL/api/nginx/proxy-hosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '<json body>'
```

Build the JSON body from parsed arguments:
```json
{
  "domain_names": ["<domain>"],
  "forward_scheme": "http",
  "forward_host": "<forward_host>",
  "forward_port": <forward_port>,
  "ssl_forced": true,
  "certificate_id": <NPM_CERT_ID>,
  "allow_websocket_upgrade": false,
  "block_exploits": true,
  "http2_support": true,
  "caching_enabled": false,
  "access_list_id": 0,
  "advanced_config": "",
  "locations": [],
  "meta": {}
}
```

Apply option overrides:
- `--websockets` → `allow_websocket_upgrade: true`
- `--no-ssl` → `ssl_forced: false`, `certificate_id: 0`
- `--scheme https` → `forward_scheme: "https"`
- `--no-cert` → `certificate_id: 0`, `ssl_forced: false`

### 3. Report result

On success (HTTP 201), print:
```
Added: https://<domain>  →  <forward_scheme>://<forward_host>:<forward_port>
SSL: <yes/no>   WebSockets: <yes/no>
```

On failure, print the full API error response.

## Notes

- Credentials file: `/Users/wangxugang/Dev/Skills/npm-add.env` (copy from `npm-add.env.example`)
- NPM admin UI: http://192.168.50.71:8181
- Wildcard cert ID 4 covers `*.castamerego.com` — use `--no-cert` for non-castamerego domains
