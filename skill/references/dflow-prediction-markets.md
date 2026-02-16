# DFlow Prediction Markets

General-purpose guidance for prediction market discovery, trading, and redemption on Solana. Applies to web, mobile, backend, or CLI experiences.

Prediction market trades are always **imperative and async** (they use `/order` and execute across multiple transactions). Do not offer declarative trades for prediction markets.

## Required Prompts (Always Ask)

Always ask these before giving implementation steps. Do not assume defaults.

1. **Settlement mint**: Are you using **USDC** or **CASH**? These are the only two supported settlement mints.
2. **Platform fees**: Do you want to charge platform fees? If yes, use `platformFeeScale` for dynamic fees (see Fees section).
3. **Client environment**: Are you building web, mobile, backend, or CLI?

Infer intent from the user's request. Do not ask them to choose a "trade type."
Map intent to flow:
- **Open a position** -> buy YES/NO outcome tokens (increase)
- **Sell/close a position** -> sell YES/NO outcome tokens (decrease)
- **Redeem** -> swap outcome tokens back into settlement mint after determination

## Core Concepts

- **Outcome tokens**: YES/NO tokens are **Token-2022** mints.
- **Market status** gates trading: only `active` markets accept trades. Always check `status` before submitting orders.
- **Redemption** is available only when `status` is `determined` or `finalized` **and** `redemptionStatus` is `open`.
- **Events vs Markets**:
  - **Event** = the real-world question (can contain one or more markets).
  - **Market** = a specific tradable YES/NO market under an event.
  - **Event ticker** identifies the event; **market ticker** identifies the market.
  - Use event endpoints for event data, and market endpoints for market data.
- **Settlement mints**: USDC (`EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`) and CASH (`CASHx9KJUStyftLFWGvEVf59SGeG9sh5FfcnZMVPCASH`). A market settles in whichever mint its outcome tokens belong to.
- **No fractional contracts**: users cannot buy a fractional contract.
- **Minimum order**: 0.01 USDC, but some markets require more because the smallest purchasable unit is one contract and the price determines the minimum.

## Market Lifecycle

Markets move through a fixed lifecycle. A market's `status` defines what actions are allowed.

**`initialized` -> `active` -> `inactive` -> `closed` -> `determined` -> `finalized`**

| Status        | Trading | Redemption           | Notes                                                  |
| ------------- | ------- | -------------------- | ------------------------------------------------------ |
| `initialized` | No      | No                   | Market exists but trading hasn't started               |
| `active`      | **Yes** | No                   | Only status that allows trades                         |
| `inactive`    | No      | No                   | Paused; can return to `active` or proceed to `closed`  |
| `closed`      | No      | No                   | Trading ended; outcome not yet known                   |
| `determined`  | No      | Check `redemptionStatus` | Outcome decided; redemption may be available       |
| `finalized`   | No      | Check `redemptionStatus` | Final state; redemption available for winners       |

Key rules:
- `inactive` is a pause state. Markets can go back to `active` from `inactive`.
- Always check `redemptionStatus` before submitting redemption requests — `determined` or `finalized` alone is not sufficient.
- Filter markets by status using `GET /api/v1/markets?status=active`, `GET /api/v1/events?status=active`, or `GET /api/v1/series?status=active`.

## CORS: Browser Requests Are Blocked

The Trading API does not set CORS headers. Browser requests to `/order` will fail. Builders MUST proxy Trade API calls through their own backend (e.g., Cloudflare Workers, Vercel Edge Functions).

## Maintenance Window

Kalshi's clearinghouse has a weekly maintenance window on **Thursdays from 3:00 AM to 5:00 AM ET**. Orders submitted during this window will not be cleared and will be reverted. Applications should prevent users from submitting orders during this window.

## Compliance (Geoblocking)

Prediction market access has jurisdictional restrictions. Builders are responsible
for enforcing required geoblocking before enabling trading, even if KYC (Proof) is used. See:
https://pond.dflow.net/legal/prediction-market-compliance

## Proof KYC (Identity Verification)

**Proof KYC is required only for buying and selling outcome tokens.** It is not needed for:

- Browsing markets
- Fetching events, orderbooks, metadata, or any API data
- Viewing market details or charts

Gate Proof verification only when the user attempts to **open a position** (buy YES/NO) or **close/decrease a position** (sell outcome tokens). Check verification status before allowing the trade.

See [dflow-proof.md](dflow-proof.md) for verify API, deep link flow, and minimal integration code. Full docs: https://pond.dflow.net/learn/proof

## Endpoints and API Access

- Trade API (dev): `https://dev-quote-api.dflow.net`
- Metadata API (dev): `https://dev-prediction-markets-api.dflow.net`

Keep in mind:
- These endpoints are intended for end-to-end testing during development.
- Do not ship to production without coordinating with the DFlow team.
- Be prepared to lose test capital.
- Endpoints are rate-limited and not suitable for production workloads.

Developer endpoints work without an API key, however they are rate limited and not suitable
for production use. For production use, request an API key at:
`https://pond.dflow.net/build/api-key`

## Metadata API (Discovery + Lifecycle)

Use the Metadata API to discover markets, read lifecycle status, and map outcome mints.

Common endpoints:
- `GET /api/v1/events?withNestedMarkets=true`
- `GET /api/v1/markets?status=active`
- `GET /api/v1/market/by-mint/{mint}`
- `POST /api/v1/filter_outcome_mints`
- `POST /api/v1/markets/batch`
- `GET /api/v1/orderbook/{market_ticker}`
- `GET /api/v1/orderbook/by-mint/{mint}`
- `GET /api/v1/tags_by_categories`
- `GET /api/v1/search?query={query}` — full-text search (see Search section)
- `GET /api/v1/filters_by_sports` — sports-specific filters (see Sports Filters section)
- `GET /api/v1/live_data` — REST-based live snapshots (see Live Data section)

## Categories and Tags (UI Filters)

To build category filters:

1. Fetch categories from `GET /api/v1/tags_by_categories`.
2. Use the category name with `GET /api/v1/series?category={category}`.
3. Fetch events with `GET /api/v1/events?seriesTickers={comma-separated}` and `withNestedMarkets=true`.

Corner cases and best practices:

- **Too many series tickers** can cause request errors or long URLs. Chunk
  tickers into smaller batches (e.g., 5-10) and merge results.
- **Stale responses** can overwrite state when users switch categories quickly.
  Use a request ID or abort controller to ignore older responses.
- **Empty categories** should show a clear empty state instead of reusing prior results.
- **Defensive filtering**: if the events response contains mixed categories,
  post-filter by `event.seriesTicker` against the series tickers you requested.

## Search API

Use `GET /api/v1/search?query={query}` for full-text search across events and markets. This is essential for building search bars.

Fields searched on **events**: `id` (event ticker), `series_ticker`, `title`, `sub_title`.
Fields searched on **markets**: `id` (market ticker), `event_ticker`, `title`, `yes_sub_title`, `no_sub_title`.

**Not searched**: tags, categories, rules, competition fields, images, settlement sources.

Matching rules:
- Query is split on whitespace; **all tokens** must match.
- Ticker fields match upper and lower case.
- Text fields use full-text matching.
- Special characters are escaped before search.

## Sports Filters

Use `GET /api/v1/filters_by_sports` to get filter options specific to sports prediction markets. Use this for building sports-specific category UIs.

## Live Data (REST)

For one-time snapshots of live market data (as opposed to streaming via WebSockets), use:

- `GET /api/v1/live_data` — all live data
- `GET /api/v1/live_data/by-mint/{mint_address}` — live data for a specific outcome mint
- `GET /api/v1/live_data/by-event/{event_ticker}` — live data for a specific event

Use these endpoints when you need a single snapshot rather than a continuous stream. For real-time streaming, use WebSockets instead.

## Real-Time Data (WebSockets)

For live price tickers, trade feeds, and orderbook depth, see [dflow-websockets.md](dflow-websockets.md). WebSockets require a production API key and connect via `wss://` (same host as the production Metadata API, with `https` swapped for `wss`).

## Candlesticks (Charts)

Use the candlesticks endpoint that matches the ticker you have:
- **Market detail chart** -> `GET /api/v1/market/{ticker}/candlesticks`
- **Event-level chart** -> `GET /api/v1/event/{ticker}/candlesticks`

If you're unsure which ticker you have, confirm whether it's a **market ticker** or
an **event ticker**, then choose the corresponding endpoint.

Use candlesticks (not forecast history) for charting and user-facing price history. Forecast history is only for numerical events separated by percentiles and is better suited for research.

## Prediction Market Slippage

The `/order` endpoint supports a separate `predictionMarketSlippageBps` parameter specifically for the prediction market leg of a trade. This is distinct from the overall `slippageBps` parameter.

- `slippageBps` controls slippage for the spot swap leg (e.g., SOL to USDC).
- `predictionMarketSlippageBps` controls slippage for the outcome token leg (USDC to YES/NO token).

Both accept an integer (basis points) or `"auto"`. If `predictionMarketSlippageBps` is not set, only `slippageBps` applies.

When trading directly from a settlement mint (USDC/CASH) to an outcome token, there is no spot swap leg, so only `predictionMarketSlippageBps` matters.

## Input Mint and Latency

Using the settlement mint (USDC or CASH) as the input is the fastest path. If you input a different token (e.g., SOL), the system adds a swap leg to convert to the settlement mint first, which adds roughly **50ms** of latency. For the lowest latency trades, use the settlement mint directly.

## Trading Flow (Spot -> Outcome Token)

Use `/order` to trade any spot token into an outcome token. The Trade API:

1. Detects market initialization
2. Routes **Input -> Settlement Mint -> Outcome Token**
3. Adds tokenization automatically if the market is uninitialized

## Open / Increase Position (Buy YES/NO)

1. Discover a market and choose outcome mint (YES/NO).
2. Request `/order` from settlement mint (USDC/CASH) to outcome mint.
3. Sign and submit transaction.
4. Poll `/order-status` for fills (prediction market trades are async).

## Decrease / Close Position

1. Choose outcome mint to sell.
2. Request `/order` from outcome mint to settlement mint.
3. Sign and submit transaction.
4. Poll `/order-status`.

## Order Status Polling

After submitting a prediction market trade, poll `GET /order-status?signature={signature}` to track execution.

Query parameters:
- `signature` (required): Base58 transaction signature from the `/order` response
- `lastValidBlockHeight` (optional): Last valid block height for the transaction

Response fields:

| Field      | Type   | Description                                                      |
| ---------- | ------ | ---------------------------------------------------------------- |
| `status`   | string | `pending`, `open`, `pendingClose`, `closed`, `expired`, `failed` |
| `fills`    | array  | Fill details (present if order has fills)                        |
| `inAmount` | string | Total input amount filled (scaled integer)                       |
| `outAmount`| string | Total output amount filled (scaled integer)                      |
| `reverts`  | array  | Revert details (present if order has reverts)                    |

Status meanings:
- `pending` — Transaction submitted, not yet confirmed
- `open` — Order is live on the book, waiting for fills
- `pendingClose` — Order is closing, may have partial fills
- `closed` — Order complete (check `fills` for execution details)
- `expired` — Transaction expired (block height exceeded)
- `failed` — Order failed to execute

Poll while status is `open` or `pendingClose`. Use a 2-second interval between polls.

```ts
let status;
do {
  const res = await fetch(
    `${API_BASE_URL}/order-status?signature=${signature}`,
    { headers }
  ).then((x) => x.json());
  status = res.status;
  if (status === "open" || status === "pendingClose") {
    await new Promise((r) => setTimeout(r, 2000));
  }
} while (status === "open" || status === "pendingClose");
```

## Redemption Flow

1. Fetch market by mint and confirm:
   - `status` is `determined` or `finalized`
   - `redemptionStatus` is `open`
2. Request `/order` from outcome mint to settlement mint (redemption).
3. Sign and submit transaction.

## Track User Positions

1. Fetch wallet token accounts using **Token-2022 program**.
2. Filter mints with `POST /api/v1/filter_outcome_mints`.
3. Batch markets via `POST /api/v1/markets/batch`.
4. Label YES/NO by comparing mints to `market.accounts`.

## Market Initialization

- When a market has not been tokenized yet, the `/order` endpoint automatically includes market tokenization in the transaction before executing the swap.
- Initialization costs approximately **0.02 SOL**, paid in SOL (not USDC).
- Any builder can pre-initialize a market before users trade it using `GET /prediction-market-init`.
- DFlow pre-initializes some popular markets.
- If not pre-initialized, the first user's trade pays the initialization cost unless the trade is sponsored.

## Fees and Sponsorship

### DFlow Base Trading Fees

DFlow charges base trading fees on all prediction market trades using a probability-weighted model:

```
fees = roundup(0.07 * c * p * (1 - p)) + (0.01 * c * p * (1 - p))
```

Where `p` is the fill price and `c` is the number of contracts. Fees are higher when outcomes are uncertain and lower as markets approach resolution.

**Fee Tiers** (based on rolling 30-day outcome token volume):

| Tier     | 30D Volume  | Taker Fee Scale | Maker Fee Scale |
| -------- | ----------- | --------------- | --------------- |
| Frost    | Below $50M  | 0.09            | 0.0225          |
| Glacier  | $50-150M    | 0.0875          | 0.021875        |
| Steel    | $150-300M   | 0.085           | 0.02125         |
| Obsidian | Above $300M | 0.08            | 0.02            |

Volume is tracked by API key across all applications using the Prediction Markets API.

**Rebate Program**: Builders with over $100k in 30-day volume may qualify for rebates — the greater of 3% of gross fees or incremental rebates at VIP tiers (10-30% on incremental fees above $50M). Contact DFlow for eligibility.

### Platform Fees (Dynamic)

For prediction market outcome token trades, use `platformFeeScale` instead of `platformFeeBps`. The fee is calculated as:

```
k * p * (1 - p) * c
```

Where:
- `k` is `platformFeeScale` with 3 decimals of precision (e.g., `50` means `0.050`)
- `p` is the all-in price (includes all fees + filled price)
- `c` is the contract size

Users pay no platform fee when redeeming a winning outcome (p = 1). The fee is always collected in the settlement mint. `platformFeeMode` is ignored for outcome token trades.

The `feeAccount` must be a settlement mint token account. Use `referralAccount` to auto-create it if it does not exist.

### Sponsorship

There are three distinct costs in prediction market trades that can be sponsored:

1. **Transaction fees** — Solana transaction fees (paid by the fee payer)
2. **ATA creation** — Creating Associated Token Accounts for outcome tokens
3. **Market initialization** — One-time onchain cost (~0.02 SOL) to tokenize a market

Sponsorship options:
- `sponsor` — Covers all three: transaction fees, ATA creation, and market initialization. Simplest option for fully sponsored trades.
- `predictionMarketInitPayer` — Covers only market initialization. Users still pay their own transaction fees. Use when users sign their own transactions but you don't want them paying the one-time init cost.

### Pre-initializing Markets

To avoid initialization costs during a user's first trade, pre-initialize markets using:

`GET /prediction-market-init?payer={payer}&outcomeMint={outcomeMint}`

- `payer` (required): Base58 address that pays for initialization
- `outcomeMint` (required): Base58 mint address of either outcome token

Returns a base64 transaction that the payer must sign and submit.

### Account Rent and Reclamation

Most of the cost users see comes from **Solana account rent**, not platform fees. Prediction market trades create multiple onchain accounts.

**Winning positions**: When redeemed, the outcome token account is closed and rent is returned to the address specified by `outcomeAccountRentRecipient`.

**Losing positions**: The outcome token is worthless. Users can burn the tokens and close the account to reclaim rent. Use `outcomeAccountRentRecipient` on the original `/order` call to control where rent goes.

### Closing Empty Outcome Token Accounts

After a losing position, burn remaining tokens and close the account to reclaim rent:

```ts
import { Connection, PublicKey, Transaction, sendAndConfirmTransaction } from "@solana/web3.js";
import { getAccount, createBurnInstruction, createCloseAccountInstruction } from "@solana/spl-token";

const tokenAccount = new PublicKey("OUTCOME_TOKEN_ACCOUNT");
const outcomeMint = new PublicKey("OUTCOME_TOKEN_MINT");
const rentRecipient = new PublicKey("RENT_DESTINATION"); // user wallet or outcomeAccountRentRecipient

const account = await getAccount(connection, tokenAccount);
const instructions = [];

if (account.amount > 0n) {
  instructions.push(
    createBurnInstruction(tokenAccount, outcomeMint, owner.publicKey, account.amount)
  );
}
instructions.push(
  createCloseAccountInstruction(tokenAccount, rentRecipient, owner.publicKey)
);

const tx = new Transaction().add(...instructions);
await sendAndConfirmTransaction(connection, tx, [owner]);
```

This is a standard SPL Token operation — DFlow does not provide a dedicated endpoint for closing accounts.

## Error Handling

### `route_not_found`

Common causes for prediction markets:
1. **Wrong `outputMint`**: when selling an outcome token, `outputMint` must match the market's settlement mint (USDC or CASH). Check the `accounts` object in the market response.
2. **Wrong `amount` units**: the `amount` is in atomic units (e.g., `8_000_000` for 8 USDC, not `8`).
3. **No liquidity at top of book**: check the orderbook. If selling YES, check `yesBid`; if buying YES, check `yesAsk`. A `null` value means no counterparty.

### Prediction Markets IDL Errors

These onchain program errors may appear when transactions fail:

| Code | Name                    | Meaning                                      |
| ---- | ----------------------- | -------------------------------------------- |
| 16   | MarketNotOpen           | Market is not in `active` status             |
| 17   | MarketOutcomeDetermined | Outcome already decided, cannot trade        |
| 18   | MarketNotDetermined     | Cannot redeem — outcome not yet decided      |
| 19   | InvalidMarketStatus     | Action not allowed for current market status |
| 64   | InvalidQuantity         | Invalid trade quantity                       |
| 80   | OrderAlreadyFilled      | Order was already filled                     |
| 83   | FillUnderproduced       | Output less than minimum expected            |
| 84   | FillOverconsumed        | Input more than maximum expected             |

### Market Images

Market-level images are not currently available. Event-level images exist. For market images, fetch from Kalshi directly: `https://docs.kalshi.com/api-reference/events/get-event-metadata`

## CLI Guidance

If the user is building a CLI, use a local keypair to sign and submit transactions.
Do not embed private keys in code or logs. Emphasize secure key handling and
environment-based configuration.

## Cookbook

Full runnable examples are in the DFlow Cookbook Repo: `https://github.com/DFlowProtocol/cookbook`
