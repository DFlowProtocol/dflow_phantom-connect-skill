# DFlow Crypto Trading (Spot)

General-purpose guidance for spot crypto token trading on Solana using DFlow. Applies to web, mobile, backend, or CLI experiences.

DFlow is a DEX aggregator that sources liquidity across venues on Solana. It supports two trade types for spot crypto: **imperative** and **declarative**.

For detailed API parameters, response schemas, and code examples, use the DFlow MCP server (`SearchDFlow`) or see pond.dflow.net/build.

## First Questions (Always Ask)

Always ask these before giving implementation steps. Do not assume defaults.

1. **Trade type**: Do you want **imperative** or **declarative** trades? If the user is unsure, suggest starting with imperative — it is simpler to integrate, executes synchronously, and is the right starting point for most builders.
2. **Environment**: Are you building against **dev** or **production** endpoints? Dev endpoints work without an API key but are rate-limited and not suitable for production. Production requires an API key — apply at `pond.dflow.net/build/api-key`.
3. **Platform fees**: Do you want to charge platform fees? If yes, what bps and what fee account (wallet address) should receive them?
4. **Client environment**: Are you building web, mobile, backend, or CLI?

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

The user defines what they want (assets + constraints); DFlow determines how the trade executes at execution time.

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

### `executionMode` in the `/order` Response

The response includes an `executionMode` field (`sync` or `async`) that determines how to confirm:

- `sync` — Trade executes atomically in one transaction. Use standard RPC confirmation.
- `async` — Trade executes across multiple transactions. Poll `/order-status` to track fills.

## Recommended Endpoint

The `/order` endpoint is the recommended way to execute imperative trades. The older `/quote`, `/swap`, and `/swap-instructions` endpoints still work but `/order` is simpler and preferred for new integrations.

## Token Lists (Swap UI Guidance)

If building a swap UI:

- **From** list: all tokens detected in the user's wallet
- **To** list: fixed set of supported tokens with known mints (SOL, USDC, CASH — look up addresses via MCP)

## Slippage Tolerance

Two options:

- **Auto slippage**: set `slippageBps=auto`. Recommended for most user-facing flows.
- **Custom slippage**: set `slippageBps` to a non-negative integer (basis points). Too low can cause failures during volatility.

## Priority Fees

Two modes:

- **Max Priority Fee** (recommended): DFlow dynamically selects an optimal fee capped at your maximum. Set `priorityLevel` and `maxPriorityFeeLamports`.
- **Exact Priority Fee**: fixed fee in lamports. For intent endpoints, include the 10,000 lamport base processing fee.

Default if unset: automatic priority fees capped at 0.005 SOL.

## Platform Fees (Ask Early)

Platform fees let builders monetize trades. Key constraints:

- **Imperative trades**: fees can be collected from `inputMint` or `outputMint`
- **Declarative trades**: fees can only be collected from `outputMint`

Use `referralAccount` to auto-create the fee account if it does not exist.

Ask:

- Do you want platform fees?
- What fee in bps?
- Which token should pay the fee?
- What wallet address should receive fees?
- Do you already have a fee account, or should we use a referral account to create it?

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
