# DFlow Prediction Markets

General-purpose guidance for prediction market discovery, trading, and redemption on Solana. Applies to web, mobile, backend, or CLI experiences.

Prediction market trades are always **imperative and async** (they use `/order` and execute across multiple transactions). Do not offer declarative trades for prediction markets.

For detailed API parameters, response schemas, endpoint lists, and code examples, use the DFlow MCP server (`SearchDFlow`) or see pond.dflow.net/build.

## Required Prompts (Always Ask)

Always ask these before giving implementation steps. Do not assume defaults.

1. **Settlement mint**: Are you using **USDC** or **CASH**? These are the only two supported settlement mints.
2. **Environment**: Are you building against **dev** or **production** endpoints? Dev endpoints work without an API key but are rate-limited and not suitable for production. Production requires an API key — apply at `pond.dflow.net/build/api-key`.
3. **Platform fees**: Do you want to charge platform fees? If yes, use `platformFeeScale` for dynamic fees (see Fees section).
4. **Client environment**: Are you building web, mobile, backend, or CLI?

Infer intent from the user's request. Do not ask them to choose a "trade type."
Map intent to flow:

- **Open a position** -> buy YES/NO outcome tokens (increase)
- **Sell/close a position** -> sell YES/NO outcome tokens (decrease)
- **Redeem** -> swap outcome tokens back into settlement mint after determination

## Core Concepts

- **Outcome tokens**: YES/NO tokens are **Token-2022** mints.
- **Market status** gates trading: only `active` markets accept trades. Always check `status` before submitting orders.
- **Redemption** requires `status` = `determined` or `finalized` **and** `redemptionStatus` = `open`.
- **Events vs Markets**: an Event is the real-world question (can contain multiple markets). A Market is a specific tradable YES/NO pair. Use event endpoints for event data, market endpoints for market data.
- **Settlement mints**: USDC and CASH. A market settles in whichever mint its outcome tokens belong to.
- **No fractional contracts**: users cannot buy a fractional contract.
- **Minimum order**: 0.01 USDC, but some markets require more because the smallest purchasable unit is one contract and the price determines the minimum.

## Market Lifecycle

Markets move through: `initialized` -> `active` -> `inactive` -> `closed` -> `determined` -> `finalized`.

Key rules:

- Only `active` markets accept trades.
- `inactive` is a pause state — markets can return to `active`.
- Always check `redemptionStatus` before submitting redemption requests — `determined` or `finalized` alone is not sufficient.
- Filter markets by status using the Metadata API (e.g., `?status=active`).

Use the MCP server to look up the full lifecycle table and allowed actions per status.

## Maintenance Window

Kalshi's clearinghouse has a weekly maintenance window on **Thursdays from 3:00 AM to 5:00 AM ET**. Orders submitted during this window will not be cleared and will be reverted. Applications should prevent users from submitting orders during this window.

## Compliance (Geoblocking)

Prediction market access has jurisdictional restrictions. Builders are responsible for enforcing required geoblocking before enabling trading, even if KYC (Proof) is used. See: https://pond.dflow.net/legal/prediction-market-compliance

## Proof KYC (Identity Verification)

**Proof KYC is required only for buying and selling outcome tokens.** It is not needed for browsing markets, fetching data, or viewing details.

Gate Proof verification only when the user attempts to **open a position** or **close/decrease a position**. Check verification status before allowing the trade.

See [dflow-proof.md](dflow-proof.md) for the verify API, deep link flow, and integration guidance.

## Discovery and Metadata

Use the Metadata API for market discovery, lifecycle status, and outcome mint mapping. Key capabilities:

- **Browse**: List events, markets, series with nested data and status filters
- **Search**: Full-text search across events and markets (query is split on whitespace; all tokens must match)
- **Categories**: Fetch categories via tags, then filter series and events
- **Sports**: Dedicated sports filter endpoint for sports-specific UIs
- **Live data**: REST snapshots of live market data (by mint or by event)
- **Orderbook**: Per-market orderbook depth
- **Candlesticks**: Price history for charting (use candlesticks, not forecast history, for user-facing charts)
- **Batch**: Batch market lookups and outcome mint filtering

Use the MCP server to look up specific endpoint paths and parameters.

### Categories and Tags (UI Filters)

To build category filters:

1. Fetch categories from the tags endpoint.
2. Use the category name to filter series.
3. Fetch events with nested markets.

Gotchas:

- **Too many series tickers** can cause long URLs. Chunk tickers into smaller batches and merge results.
- **Stale responses** can overwrite state when users switch categories quickly. Use an abort controller to ignore older responses.
- **Empty categories** should show a clear empty state.
- **Defensive filtering**: post-filter events by series ticker if the response contains mixed categories.

## Real-Time Data (WebSockets)

For live price tickers, trade feeds, and orderbook depth, see [dflow-websockets.md](dflow-websockets.md). A free dev WebSocket endpoint is available at `wss://dev-prediction-markets-api.dflow.net/api/v1/ws` (no API key required). Production WebSockets require an API key.

## Prediction Market Slippage

The `/order` endpoint supports two separate slippage parameters:

- `slippageBps` — controls the spot swap leg (e.g., SOL to USDC)
- `predictionMarketSlippageBps` — controls the outcome token leg (USDC to YES/NO)

When trading directly from a settlement mint to an outcome token, only `predictionMarketSlippageBps` matters (there is no spot swap leg).

Both accept an integer (basis points) or `"auto"`.

## Trading Flows

### Open / Increase Position (Buy YES/NO)

1. Discover a market and choose outcome mint (YES/NO).
2. Request `/order` from settlement mint to outcome mint.
3. Sign and submit transaction.
4. Poll `/order-status` for fills (prediction market trades are async).

### Decrease / Close Position

1. Choose outcome mint to sell.
2. Request `/order` from outcome mint to settlement mint.
3. Sign and submit transaction.
4. Poll `/order-status`.

### Redemption

1. Confirm market `status` is `determined` or `finalized` **and** `redemptionStatus` is `open`.
2. Request `/order` from outcome mint to settlement mint.
3. Sign and submit transaction.

### Track User Positions

1. Fetch wallet token accounts using **Token-2022 program**.
2. Filter mints with the outcome mints endpoint.
3. Batch market lookups.
4. Label YES/NO by comparing mints to `market.accounts`.

## Order Status Polling

Prediction market trades are async. After submitting, poll `/order-status` with the transaction signature.

- Poll while status is `open` or `pendingClose`. Use a 2-second interval.
- `closed` means complete — check `fills` for execution details.
- `expired` means the transaction expired (block height exceeded).
- `failed` means the order failed to execute.

Use the MCP server to look up the full response schema.

## Market Initialization

- The `/order` endpoint automatically includes market tokenization when a market has not been initialized yet.
- Initialization costs ~0.02 SOL, paid in SOL (not USDC).
- Builders can pre-initialize markets before users trade to avoid this cost hitting the first user.
- DFlow pre-initializes some popular markets.

## Fees and Sponsorship

### DFlow Base Trading Fees

Fee tiers are based on rolling 30-day outcome token volume (tracked by API key). Higher volume means lower fees. Use the MCP server to look up current fee tier thresholds.

### Platform Fees (Dynamic)

For prediction market trades, use `platformFeeScale` (not `platformFeeBps`). The fee scales dynamically with outcome probability — users pay no platform fee when redeeming a winning outcome (p = 1). The fee is always collected in the settlement mint.

The `feeAccount` must be a settlement mint token account. Use `referralAccount` to auto-create it if needed.

### Sponsorship

Three distinct costs in prediction market trades can be sponsored:

1. **Transaction fees** — Solana transaction fees
2. **ATA creation** — Creating Associated Token Accounts for outcome tokens
3. **Market initialization** — One-time onchain cost (~0.02 SOL)

Options:

- `sponsor` — Covers all three. Simplest for fully sponsored trades.
- `predictionMarketInitPayer` — Covers only market initialization. Users still pay transaction fees.

### Account Rent and Reclamation

Most visible cost to users comes from **Solana account rent**, not platform fees.

- **Winning positions**: Redeeming closes the outcome token account and returns rent (via `outcomeAccountRentRecipient`).
- **Losing positions**: Users can burn tokens and close the account to reclaim rent. This is a standard SPL Token operation (burn + close account instructions).

## Error Handling

### `route_not_found`

Common causes:

1. **Wrong `outputMint`**: when selling, `outputMint` must match the market's settlement mint.
2. **Wrong `amount` units**: the `amount` is in atomic units (e.g., `8_000_000` for 8 USDC, not `8`).
3. **No liquidity**: check the orderbook. A `null` bid/ask means no counterparty.

### Onchain Program Errors

Prediction market transactions can fail with IDL error codes (e.g., `MarketNotOpen`, `InvalidQuantity`, `OrderAlreadyFilled`). Use the MCP server to look up the full error code table.

### Market Images

Event-level images are available. Market-level images are not — fetch from Kalshi directly.

## CLI Guidance

If the user is building a CLI, use a local keypair to sign and submit transactions. Do not embed private keys in code or logs.

## Cookbook

Full runnable examples are in the DFlow Cookbook Repo: `https://github.com/DFlowProtocol/cookbook`
