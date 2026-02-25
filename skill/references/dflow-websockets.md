# DFlow WebSockets

Real-time streaming of prediction market data via WebSocket. Use for live price tickers, trade feeds, orderbook depth, and market monitoring.

WebSockets show all Kalshi trades (both onchain and offchain).

For message schemas, field definitions, and code examples, use the DFlow MCP server (`SearchDFlow`) or see pond.dflow.net/build.

## Environment (Always Ask)

Ask the user: **Are you building against dev or production?**

- **Dev**: `wss://dev-prediction-markets-api.dflow.net/api/v1/ws` — no API key required, rate-limited, not for production use.
- **Production**: `wss://<your-production-host>/api/v1/ws` — requires an API key. Apply at pond.dflow.net/build/api-key.

## Connection

### Dev (No API Key)

Connect directly — no authentication needed:

```ts
const ws = new WebSocket("wss://dev-prediction-markets-api.dflow.net/api/v1/ws");
```

### Production (API Key Required)

Pass the API key via the `x-api-key` header:

```ts
const ws = new WebSocket("wss://<your-production-host>/api/v1/ws", {
  headers: { "x-api-key": process.env.DFLOW_API_KEY },
});
```

## Channels

Three channels are available:

- **prices** — Real-time bid/ask price updates for markets
- **trades** — Real-time trade execution updates
- **orderbook** — Real-time orderbook depth updates for markets

## Subscription Rules

These rules are critical — getting them wrong leads to silent subscription failures:

- Subscribing to `"all": true` **clears** any specific ticker subscriptions for that channel.
- Subscribing to specific tickers **disables** "all" mode for that channel.
- Each channel maintains **independent** subscription state.
- Unsubscribing from specific tickers has **no effect** if you are subscribed to "all" for that channel. Unsubscribe from "all" first.

Subscribe and unsubscribe by sending JSON messages with `type`, `channel`, and either `"all": true` or `"tickers": [...]`.

## Best Practices

- Implement reconnection logic with exponential backoff.
- Subscribe only to the markets you need. Use specific tickers rather than "all" when possible to reduce bandwidth.
- Process messages asynchronously to avoid blocking during high-volume periods.
- Always implement `onerror` and `onclose` handlers.

## Price Fields

Price fields (`yes_bid`, `yes_ask`, `no_bid`, `no_ask`) may be `null` if there is no current bid or ask at that level.
