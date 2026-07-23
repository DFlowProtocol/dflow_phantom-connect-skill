# DFlow Market Data (WebSocket streaming)

Real-time spot market data for Solana pairs over WebSocket: live top-of-book quotes, order-book depth, and priority-fee estimates. Read-only: this streams prices and depth for display. To execute a swap, see `dflow-crypto-trading.md`.

> Doc-path convention: bare paths (e.g. `/resources/trading-api/websockets/book-stream`) are DFlow docs MCP paths. Read them with `query_docs_filesystem_d_flow` / `search_d_flow`, not a browser fetch. Load a stream's message-schema page before wiring it; don't guess field names.

## The three streams

All are paths on the DFlow Trade API WebSocket host (prod `wss://quote-api.dflow.net`, dev `wss://dev-quote-api.dflow.net`). One connection; subscribe per pair.

| Stream | Path | Gives you |
|---|---|---|
| Quotes | `/quote-stream` | live top-of-book bid/ask for a pair |
| Order book | `/book-stream` | ten levels of depth per side |
| Priority fees | `/priority-fees/stream` | live priority-fee estimates (no polling) |

## Keep the key on the backend (proxy the stream)

As a security best practice, keep your DFlow API key on the backend, not in browser code where anyone can read it. Stream through a backend proxy that holds the key, connects to DFlow, and relays messages to the browser.

A server-side app (Node/CLI, no browser) is already the trusted backend, so it connects directly with the key as an `x-api-key` header.

```js
// Backend relay (Node, `ws`). The browser connects to THIS; the backend holds the key.
import { WebSocketServer, WebSocket } from "ws";
const wss = new WebSocketServer({ server });
wss.on("connection", (client) => {
  const up = new WebSocket(`${process.env.DFLOW_TRADE_API_WS_URL}/book-stream`,
    { headers: { "x-api-key": process.env.DFLOW_API_KEY } });
  const q = [];
  up.on("open", () => { q.forEach((m) => up.send(m)); q.length = 0; });
  up.on("message", (d) => client.readyState === 1 && client.send(d.toString()));
  client.on("message", (m) => up.readyState === 1 ? up.send(m.toString()) : q.push(m.toString()));
  client.on("close", () => up.close()); up.on("close", () => client.close());
});
```

> In production, access to the quote and book streams is granted per key: a key that works for `/order` may need stream access enabled on it, so a valid key can still be refused on the stream until the team turns it on. The priority-fees stream is not gated.

## Subscribe and handle frames (quote and book)

- **Subscribe:** `{ "op": "subscribe", "base_mint": "<mint>", "quote_mint": "<mint>" }` with base58 mints, not symbols. `unsubscribe` mirrors it. One connection multiplexes many pairs.
- **Frames batch per slot:** `{ u: <slot>, ts, updates: [ { sb, sq, ... } ] }`. Each entry in `updates[]` is keyed by its subject mints (`sb`/`sq`); a per-pair error arrives inline as `{ e: <code>, sb, sq }`, which you handle without tearing down the whole feed. Exact per-level fields (`b`/`a`, `mid`, `tick`, and so on): load the stream's page under `/resources/trading-api/websockets/` via the docs MCP.
- **Reconnect and re-subscribe.** WebSockets drop; on reopen, resend every subscription with a backoff. Track the slot `u` (and `skipped`, which is 0 when the stream kept up) to detect gaps.

## Priority-fees stream

The priority-fees stream works differently from quote and book: no subscribe message, just connect and read. Each message is a flat `{ mediumMicroLamports, highMicroLamports, veryHighMicroLamports }` object (the same shape as `GET /priority-fees`), and this stream is not gated. Details: load `/resources/trading-api/websockets/priority-fees-stream` via the docs MCP.

## Caveats: set expectations

Book and quote levels are approximations: the book is direct-routes-only (10 levels); quotes are direct plus one-hop from a roughly $10 USDC round-trip. They can differ from the real `/order` quote at trade time, so don't present them as an executable price. For the price a user will actually get, quote `/order` (see `dflow-crypto-trading.md`).

## When something doesn't fit

Per-stream message schema, ping/keepalive, priority-fee fields: docs MCP (`/resources/trading-api/websockets/*`). Runnable references: docs recipes [`/spot/recipes/stream-order-book`](https://pond.dflow.net/spot/recipes/stream-order-book) and [`/spot/recipes/stream-quotes`](https://pond.dflow.net/spot/recipes/stream-quotes).
