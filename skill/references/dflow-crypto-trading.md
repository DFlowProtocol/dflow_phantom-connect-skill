# DFlow Crypto Trading (Spot)

General-purpose guidance for spot crypto token trading on Solana using DFlow. Applies to web, mobile, backend, or CLI experiences.

DFlow is a DEX aggregator that sources liquidity across venues on Solana. It supports two trade types for spot crypto: **imperative** and **declarative**.

## First Questions (Always Ask)

Always ask these before giving implementation steps. Do not assume defaults.

1. **Trade type**: Do you want **imperative** or **declarative** trades? If the user is unsure, suggest starting with imperative — it is simpler to integrate, executes synchronously, and is the right starting point for most builders.
2. **Platform fees**: Do you want to charge platform fees? If yes, what bps and what fee account (wallet address) should receive them?
3. **Client environment**: Are you building web, mobile, backend, or CLI?

## Choosing a Trade Type (Imperative vs Declarative)

Ask the user which trade type they want. If they don't know, recommend imperative as the starting point.

### Imperative Trades (Recommended Starting Point)

The app specifies the execution plan before the user signs. The user signs a single transaction, submits it to an RPC, and confirms.

- Deterministic execution: the route is fixed at quote time.
- Synchronous: settles atomically in one transaction.
- The app can modify the swap transaction for composability.
- Supports venue selection via `dexes` parameter.
- Good fit for: most swap UIs, strategy-driven trading, automation, research, and testing.

Flow:
1. `GET /order` with `userPublicKey`, input/output mints, amount, slippage
2. Deserialize and sign the returned base64 transaction
3. Submit to Solana RPC
4. Confirm transaction

### Declarative Trades

The user defines what they want (assets + constraints); DFlow determines how the trade executes at execution time using JIT (just-in-time) routing.

- Routing is finalized at execution, not quote time.
- Reduces slippage and sandwich risk.
- Higher execution reliability in fast-moving markets.
- Uses Jito bundles for atomic open + fill execution.
- Does NOT support Token-2022 mints (use imperative `/order` instead).

Flow:
1. `GET /intent` to get an open order transaction
2. Sign the open transaction
3. `POST /submit-intent` with the signed transaction and quote response
4. Monitor status using `monitorOrder` from `@dflow-protocol/swap-api-utils` or poll `/order-status`

### When to Choose Declarative Over Imperative

Steer users toward declarative only when they specifically need:
- Better pricing in fast-moving or fragmented markets
- Reduced sandwich attack exposure
- Execution reliability over route control
- Lower slippage on large trades

## CORS: Browser Requests Are Blocked

The Trading API does not set CORS headers. Browser requests to `/order` or `/intent` will fail. Builders MUST proxy Trade API calls through their own backend. Most use a lightweight edge function (Cloudflare Workers, Vercel Edge Functions, etc.) to keep latency minimal.

## Endpoints (Development Only)

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

## Token Lists (Swap UI Guidance)

If building a swap UI:
- **From** list: all tokens detected in the user's wallet
- **To** list: fixed set of supported tokens with known mints

Known mints:
- SOL (native): `So11111111111111111111111111111111111111112` (wrapped SOL mint)
- USDC: `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`
- CASH: `CASHx9KJUStyftLFWGvEVf59SGeG9sh5FfcnZMVPCASH`

## Slippage Tolerance

Two options:
- **Auto slippage**: set `slippageBps=auto`. DFlow chooses dynamically based on market conditions.
- **Custom slippage**: set `slippageBps` to a non-negative integer (basis points, 1 bp = 0.01%).

Auto slippage is recommended for most user-facing flows. Setting custom slippage too low can cause trades to fail during high volatility.

Both `/order` and `/intent` support the `slippageBps` parameter.

## Priority Fees

Priority fees affect when a trade executes (transaction ordering), not how it executes. They do not change routing or slippage.

Two modes:
- **Max Priority Fee** (recommended): DFlow dynamically selects an optimal fee capped at your maximum. Set `priorityLevel` (`medium`, `high`, `veryHigh`) and `maxPriorityFeeLamports`.
- **Exact Priority Fee**: fixed fee in lamports, no adjustment. Use for automation or strict budgets. For intent endpoints, include the 10,000 lamport base processing fee.

If no priority fee parameters are provided, DFlow defaults to automatic priority fees capped at 0.005 SOL.

## Platform Fees (Ask Early)

Platform fees let builders monetize trades. They:

- Apply only on successful trades
- Do not affect routing, slippage checks, or execution behavior
- Change net proceeds only

Key parameters:

- `platformFeeBps` (fixed fee in basis points, e.g. 50 = 0.5%)
- `platformFeeMode` (`outputMint` default, or `inputMint`)
- `feeAccount` (token account that receives fees; must match the fee token)

Constraints:

- **Imperative trades**: fees can be collected from `inputMint` or `outputMint`
- **Declarative trades**: fees can only be collected from `outputMint`

Use `referralAccount` to auto-create the fee account if it does not exist. DFlow derives it using the Referral program.

Ask:

- Do you want platform fees?
- What fee in bps?
- Which token should pay the fee?
- What wallet address should receive fees (fee account)?
- Do you already have a fee account, or should we use a referral account to create it?

## Liquidity Venues

If asked which DEXs DFlow sources liquidity from, fetch the current venue list:

```bash
curl --request GET \
  --url https://quote-api.dflow.net/venues
```

For imperative trades, use the `dexes` parameter to restrict execution to specific venues.

## Imperative Trade Example (TypeScript)

```ts
import { Connection, VersionedTransaction } from "@solana/web3.js";

const API_BASE_URL = "https://dev-quote-api.dflow.net";
const connection = new Connection("https://api.mainnet-beta.solana.com", "confirmed");

const inputMint = "So11111111111111111111111111111111111111112";
const outputMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
const amount = 100000; // in atomic units (lamports for SOL)
const slippageBps = 50;

// 1. Request order
const params = new URLSearchParams({
  inputMint,
  outputMint,
  amount: amount.toString(),
  slippageBps: slippageBps.toString(),
  userPublicKey: keypair.publicKey.toBase58(),
});

const headers: HeadersInit = {};
if (process.env.DFLOW_API_KEY) {
  headers["x-api-key"] = process.env.DFLOW_API_KEY;
}

const orderResponse = await fetch(
  `${API_BASE_URL}/order?${params.toString()}`,
  { headers }
).then((x) => x.json());

// 2. Deserialize and sign
const tx = VersionedTransaction.deserialize(
  Buffer.from(orderResponse.transaction, "base64")
);
tx.sign([keypair]);

// 3. Submit and confirm
const signature = await connection.sendRawTransaction(tx.serialize());
await connection.confirmTransaction(signature, "confirmed");
```

## Declarative Trade Example (TypeScript)

```ts
import { Transaction } from "@solana/web3.js";
import { monitorOrder } from "@dflow-protocol/swap-api-utils";

const API_BASE_URL = "https://dev-quote-api.dflow.net";

const params = new URLSearchParams({
  inputMint: "So11111111111111111111111111111111111111112",
  outputMint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
  amount: "1000000000",
  slippageBps: "1",
  userPublicKey: keypair.publicKey.toBase58(),
});

const headers: HeadersInit = {};
if (process.env.DFLOW_API_KEY) {
  headers["x-api-key"] = process.env.DFLOW_API_KEY;
}

// 1. Request intent
const intentData = await fetch(
  `${API_BASE_URL}/intent?${params.toString()}`,
  { headers }
).then((x) => x.json());

// 2. Sign open transaction
const openTransaction = Transaction.from(
  Buffer.from(intentData.openTransaction, "base64")
);
openTransaction.sign(keypair);

// 3. Submit intent
const submitResponse = await fetch(`${API_BASE_URL}/submit-intent`, {
  method: "POST",
  headers: { "Content-Type": "application/json", ...headers },
  body: JSON.stringify({
    quoteResponse: intentData,
    signedOpenTransaction: Buffer.from(openTransaction.serialize()).toString("base64"),
  }),
}).then((x) => x.json());

// 4. Monitor until settled
const result = await monitorOrder({
  connection,
  intent: intentData,
  signedOpenTransaction: openTransaction,
  submitIntentResponse: submitResponse,
});
```

## Error Handling

### `route_not_found`

Common causes:
1. **Wrong `amount` units**: the `amount` parameter is in atomic units (scaled by decimals). Passing human-readable units (e.g. `8` instead of `8_000_000`) will fail.
2. **No liquidity**: the requested pair may have no available route at the current trade size.

### 429 Rate Limit

Dev endpoints are rate-limited. Retry with backoff, reduce request rate, or use a production API key.

## CLI Guidance

If the user is building a CLI, use a local keypair to sign and submit transactions.
Do not embed private keys in code or logs. Emphasize secure key handling and
environment-based configuration.

## Cookbook

Full runnable examples for both imperative and declarative trades are in the DFlow Cookbook Repo: `https://github.com/DFlowProtocol/cookbook`
