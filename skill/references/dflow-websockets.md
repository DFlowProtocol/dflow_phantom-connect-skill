# DFlow Market Data (WebSocket streaming)

Real-time **spot** market data for Solana pairs over WebSocket — live top-of-book quotes, order-book depth, and priority-fee estimates. **Read-only**: streams prices/depth for display; to execute a swap, see `dflow-crypto-trading.md`.

> **Doc-path convention:** bare paths (e.g. `/resources/trading-api/websockets/book-stream`) are **DFlow docs MCP** paths — read them with `query_docs_filesystem_d_flow` / `search_d_flow`, not a browser fetch. Load a stream's message-schema page before wiring it; don't guess field names.

## The three streams

All are paths on the DFlow Trade API **WebSocket** host — prod `wss://quote-api.dflow.net`, dev `wss://dev-quote-api.dflow.net`. One connection; subscribe per pair.

| Stream | Path | Gives you |
|---|---|---|
| Quotes | `/quote-stream` | live top-of-book bid/ask for a pair |
| Order book | `/book-stream` | ten levels of depth per side |
| Priority fees | `/priority-fees/stream` | live priority-fee estimates (no polling) |

> **Stream access is GATED per API key.** A key that works fine for `/order` is **not** automatically allowed on the streams — the DFlow team enables stream access on the specific key. A valid, working key can still be refused on the WebSocket upgrade until then; that's a key permission, not a bug in your integration.

## THE gotcha: browsers can't set WebSocket headers → you MUST proxy

DFlow authenticates the stream with an **`x-api-key` header on the WebSocket upgrade**. The browser `WebSocket` API **cannot set request headers** — its constructor is `new WebSocket(url, protocols)`, with no headers option (verified in a real browser engine). So **a browser cannot connect to the stream directly.**

Run a small **backend relay**: open the upstream WS with the header server-side, pipe frames down to the browser over a header-less local WS. This is the WebSocket twin of the "browser must proxy `/order` (no CORS)" rule.

- **Node / server-side** → connect directly with the header (the `ws` library accepts `{ headers: { "x-api-key": KEY } }`).
- **Browser** → proxy through your backend; **never** put the key in client code.

```js
// Backend relay (Node, `ws`). Browser connects to THIS; it injects the key upstream.
import { WebSocketServer, WebSocket } from "ws";
const wss = new WebSocketServer({ server });
wss.on("connection", (client) => {
  const up = new WebSocket(`${process.env.DFLOW_TRADE_API_WS_URL}/book-stream`,
    { headers: { "x-api-key": process.env.DFLOW_API_KEY } });   // header only works server-side
  const q = [];
  up.on("open", () => { q.forEach((m) => up.send(m)); q.length = 0; });
  up.on("message", (d) => client.readyState === 1 && client.send(d.toString()));
  client.on("message", (m) => up.readyState === 1 ? up.send(m.toString()) : q.push(m.toString()));
  client.on("close", () => up.close()); up.on("close", () => client.close());
});
```

## Subscribe + handle frames (quote & book)

- **Subscribe:** `{ "op": "subscribe", "base_mint": "<mint>", "quote_mint": "<mint>" }` — **base58 mints, not symbols**. `unsubscribe` mirrors it. One connection multiplexes many pairs.
- **Frames batch per slot:** `{ u: <slot>, ts, updates: [ { sb, sq, ... } ] }`. Each entry in `updates[]` is keyed by its subject mints (`sb`/`sq`); a per-pair error arrives inline as `{ e: <code>, sb, sq }` — handle it **without tearing down the whole feed**. Exact per-level fields (`b`/`a`, `mid`, `tick`, …): load the stream's page under `/resources/trading-api/websockets/` via the docs MCP.
- **Reconnect + re-subscribe.** WebSockets drop. On reopen, resend every subscription; back off (500ms → 8s). Track the slot `u` (and `skipped`, default 0) to detect gaps.

## Caveats — set expectations

Book/quote levels are **approximations**: the book is direct-routes-only (10 levels); quotes are direct + one-hop from a ~$10 USDC round-trip. They can differ from the real `/order` quote at trade time — don't present them as an executable price. For the price a user will actually get, quote `/order` (see `dflow-crypto-trading.md`).

## When something doesn't fit

Per-stream message schema, ping/keepalive, priority-fee fields → docs MCP (`/resources/trading-api/websockets/*`). Runnable references: docs recipes [`/spot/recipes/stream-order-book`](https://pond.dflow.net/spot/recipes/stream-order-book) and [`/spot/recipes/stream-quotes`](https://pond.dflow.net/spot/recipes/stream-quotes).
