# DFlow Spot Trading

Swap any pair of Solana tokens via DFlow. Trades settle **synchronously** in one transaction via `/order`. Applies to web, mobile, backend, or CLI.

> **Doc-path convention:** a bare path below (e.g. `/resources/trading-api/order/order`) is a **DFlow docs MCP** path — read it with `query_docs_filesystem_d_flow` (`cat`/`head` the `.mdx`) or `search_d_flow`, *not* a browser fetch. Full `https://` links are human destinations (recipes → Cookbook, key signup). This file is the recipe; the MCP is the reference — look up field-level params/errors there, don't guess.

## First questions

- **API key?** Ask neutrally — *"Do you have a DFlow API key?"* — don't presuppose env vars. It's **one key for everything DFlow** (same `x-api-key`, Trade + Metadata, REST + WebSocket). Yes → prod host `https://quote-api.dflow.net` with `x-api-key` on every request. No → dev host `https://dev-quote-api.dflow.net` (same features, rate-limited). Prod key: `https://pond.dflow.net/get-started/api-key`.
- **Surface?** CLI/script (`dflow` CLI manages keys, signs, broadcasts) vs. API (web/mobile/backend with its own signer). A browser app must **proxy** HTTP through its backend — the Trading API serves no CORS.

## Quote (read-only)

`GET /order` **without** a `userPublicKey` returns all price fields (`inAmount`, `outAmount`, `priceImpactPct`, …) and **no** transaction — use it for a live-quote UI before the user connects. Don't invent a separate `/quote` endpoint; the older surface redirects back to `/order`. (Field list: load `/resources/trading-api/order/order` via the docs MCP.)

## Trade — `/order`

Single round-trip: get a quote and a signed-ready `VersionedTransaction` together; sign, submit, confirm. Fully synchronous — there is no async/`executionMode`/`/order-status` flow. Works with **all** SPL + Token-2022 mints.

```ts
const { transaction, lastValidBlockHeight } = await fetch("/api/order?...").then(r => r.json());
const tx = VersionedTransaction.deserialize(Buffer.from(transaction, "base64"));
const sig = await sendTransaction(tx, connection);          // wallet's RPC (browser)
await connection.confirmTransaction(                         // app's RPC (reads only)
  { signature: sig, blockhash: tx.message.recentBlockhash, lastValidBlockHeight },
  "confirmed",
);
```

**Two broadcast paths — pick by surface:**

- **Browser wallet-adapter app (default for UIs).** `wallet.sendTransaction(tx, connection)` — the wallet signs *and* broadcasts through its own RPC; your `connection` only needs to serve reads (`confirmTransaction`). A public `mainnet-beta` endpoint is fine for reads.
- **Node / server-side with a `Keypair`.** Two-step: `tx.sign([keypair])` → `connection.sendRawTransaction(tx.serialize())`. Your RPC broadcasts; a public endpoint reliably 403s `sendTransaction`.

## Gotchas (the docs MCP won't volunteer these)

- **Atomic units always.** `500_000` = $0.50 USDC, `1_000_000_000` = 1 SOL. The API rejects human-readable amounts; confirm decimals each time.
- **No symbol resolver on the API.** The Trading API takes **base58 mint addresses only**; `"USDC"` won't work on `/order`. (The `dflow` CLI resolves a small symbol set; the API does not.)
- **Browser apps must proxy `/order`.** No CORS — call it from a backend (edge function/API route), never directly from the browser.
- **Confirm against the blockhash DFlow signed with — never a fresh one.** Use `tx.message.recentBlockhash` (from the deserialized tx) + `lastValidBlockHeight` (from the `/order` response). **Never** `connection.getLatestBlockhash()` for confirmation: a fresh blockhash can already be past that `lastValidBlockHeight` (confirmation times out on a trade that landed), and public `mainnet-beta` RPCs now 403 `getLatestBlockhash` (surfaces as `"failed to get recent blockhash"`).
- **Wire wallets via Wallet-Standard auto-discovery, not per-wallet adapters.** Pass `wallets={[]}` to `<WalletProvider>`; modern Phantom/Solflare/Backpack are auto-detected. Do **not** `new PhantomWalletAdapter()` — legacy adapters silently downgrade `sendTransaction` to `signTransaction` + `sendRawTransaction` through *your* RPC, re-introducing the public-RPC 403.
- **`route_not_found` is usually units or mints, not liquidity.** Check atomic units and both mint addresses before assuming no route.

## Priority fees

Pass `prioritizationFeeLamports` on `/order`: `auto` | `medium` | `high` | `veryHigh` | `disabled` | integer lamports. Default = DFlow-auto, capped at 0.005 SOL. Live estimates for tuning: `GET /priority-fees` (snapshot), `/priority-fees/stream` (WebSocket). Fee modes + the auto-cap: load `/spot/trading/priority-fees` via the docs MCP.

## Sponsored / gasless

To let a user swap without holding SOL, pass `sponsor=<sponsor-wallet-base58>` on `/order` and **co-sign** the returned transaction with the sponsor keypair (both user and sponsor sign). `sponsorExec=true|false` picks sponsor-executes (default) vs. user-executes. Full semantics: load `/resources/trading-api/order/order` via the docs MCP. (CLI has no sponsorship.)

## Platform fees (builder cut)

Collect a fee on swaps your app routes, paid to a **builder-controlled token account**. API only.

- `platformFeeBps` — fee in basis points (`50` = 0.5%).
- `platformFeeMode` — which side pays: `outputMint` (default) or `inputMint`.
- `feeAccount` — the SPL token account that receives the fee. **Must already exist** (DFlow does **not** create it; one ATA per token you collect in, owned by the builder wallet). There is no auto-create/referral shortcut.
- **Don't set `platformFeeBps` unless you're actually collecting** — a declared fee is factored into the slippage budget and worsens the user's price if no real `feeAccount` backs it. Fees apply only on successful trades.

Full mode matrix: load `/spot/trading/platform-fees` via the docs MCP; runnable example: [`/spot/recipes/platform-fees`](https://pond.dflow.net/spot/recipes/platform-fees).

## Errors

Handle non-200 / `route_not_found` / `price_impact_too_high` without crashing. Don't silently bump `slippageBps` on retry — surface to the user. Dev endpoints are rate-limited (429 → back off or use a prod key).

## Cookbook

Full runnable examples: [`/spot/recipes/quickstart`](https://pond.dflow.net/spot/recipes/quickstart) → DFlow Cookbook Repo (`https://github.com/DFlowProtocol/cookbook`).
