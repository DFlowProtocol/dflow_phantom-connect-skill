# DFlow Spot Trading

Swap any pair of Solana tokens via DFlow. Trades are synchronous: one `/order` call returns a signed-ready transaction that you sign, submit, and confirm.

> Doc-path convention: a bare path (e.g. `/resources/trading-api/order/order`) is a DFlow docs MCP path. Read it with `query_docs_filesystem_d_flow` (`cat`/`head` the `.mdx`) or `search_d_flow`, not a browser fetch. This file is the recipe; the MCP is the reference for field-level params and errors.

## First questions

- **API key?** Ask neutrally: *"Do you have a DFlow API key?"* It's one key for everything DFlow (the same `x-api-key` across the REST APIs and the WebSocket streams). Yes: prod host `https://quote-api.dflow.net` with `x-api-key` on every request. No: dev host `https://dev-quote-api.dflow.net` (same features, rate-limited, for testing). Prod key: `https://pond.dflow.net/get-started/api-key`.
- **Surface?** Browser app (signs via the Phantom SDK; see `transactions.md` and the SDK references) or server-side (its own signer). A browser app must proxy DFlow HTTP through its backend, since the Trading API serves no CORS.

## Quote (read-only)

`GET /order` without a `userPublicKey` returns the price fields (`inAmount`, `outAmount`, `priceImpactPct`, and so on) and no transaction, which is what you want for a quote before the user connects. `/quote` still works, but `/order` is preferred for new integrations. (Field list: load `/resources/trading-api/order/order` via the docs MCP.)

## Trade (`/order`)

Get a quote and a signed-ready `VersionedTransaction` in one call, then sign, submit, and confirm. Works with all SPL and Token-2022 mints. Server-side pattern:

```ts
const { transaction } = await fetch("/api/order?...").then(r => r.json());
const tx = VersionedTransaction.deserialize(Buffer.from(transaction, "base64"));
tx.sign([keypair]);
const sig = await connection.sendTransaction(tx);
const { value } = await connection.confirmTransaction(sig, "confirmed");
if (value.err) throw new Error(`swap failed: ${JSON.stringify(value.err)}`);
```

In a browser Phantom app, deserialize the same `transaction` and sign/send it with the Phantom SDK instead of a local keypair (see `transactions.md`). Proxy the `/order` call through your backend either way.

## Gotchas

- **Atomic units always.** `500000` = $0.50 USDC, `1000000000` = 1 SOL. The API rejects human-readable amounts; confirm decimals each time.
- **No symbol resolver on the API.** The Trading API takes base58 mint addresses only; `"USDC"` won't work on `/order`. (The `dflow` CLI resolves a small symbol set; the API does not.)
- **Browser apps must proxy `/order`.** The Trading API serves no CORS, so call it from a backend (an edge function or API route), never directly from the browser.
- **`route_not_found`.** A likely cause is insufficient liquidity for the pair at your trade size. It's also worth confirming the mint addresses are correct and that `amount` is in atomic units.

## Priority fees

Pass `prioritizationFeeLamports` on `/order` as `auto`, `medium`, `high`, `veryHigh`, `disabled`, or integer lamports. Default is DFlow-auto, capped at 0.005 SOL. Live estimates for tuning: `GET /priority-fees` (snapshot), `/priority-fees/stream` (WebSocket). Fee modes and the auto-cap: load `/spot/trading/priority-fees` via the docs MCP.

## Sponsored / gasless

To let a user swap without holding SOL, pass `sponsor=<sponsor-wallet-base58>` on `/order` and co-sign the returned transaction with the sponsor keypair (both user and sponsor sign). `sponsorExec=true|false` picks sponsor-executes (default) vs. user-executes. Full semantics: load `/resources/trading-api/order/order` via the docs MCP.

## Platform fees (builder cut)

Collect a fee on swaps your app routes, paid to a builder-controlled token account. API only.

- `platformFeeBps`: fee in basis points (`50` = 0.5%).
- `platformFeeMode`: which side pays, `outputMint` (default) or `inputMint`.
- `feeAccount`: the SPL token account that receives the fee. It must already exist (DFlow does not create it; one ATA per token you collect in, owned by the builder wallet).
- **Don't set `platformFeeBps` unless you're actually collecting.** A declared fee is factored into the slippage budget and worsens the user's price if no real `feeAccount` backs it. Fees apply only on successful trades.

Full mode matrix: load `/spot/trading/platform-fees` via the docs MCP; runnable example: [`/spot/recipes/platform-fees`](https://pond.dflow.net/spot/recipes/platform-fees).

## Errors

Handle non-200, `route_not_found`, and `price_impact_too_high` without crashing. Don't silently bump `slippageBps` on retry; surface it to the user. Dev endpoints are rate-limited (429: back off or use a prod key). Full error catalog: load `/resources/error-codes` and the `/order` 400 response enum via the docs MCP.

## Runnable examples

Full runnable examples: [`/spot/recipes/quickstart`](https://pond.dflow.net/spot/recipes/quickstart).
