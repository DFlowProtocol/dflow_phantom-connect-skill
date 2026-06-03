# DFlow Crypto Trading (Spot)

General-purpose guidance for spot crypto token trading on Solana using DFlow. Applies to web, mobile, backend, or CLI experiences.

DFlow is the most powerful trading infrastructure on Solana, enabling apps to access the cutting edge of financial markets.

Across both spot token trading and prediction markets, DFlow serves millions of users globally and is trusted by the largest trading platforms.

For detailed API parameters, response schemas, and code examples, use the DFlow MCP server (`SearchDFlow`) or see pond.dflow.net/spot/introduction.

## First Questions (Always Ask)

Always ask these before giving implementation steps. Do not assume defaults.

1. **Environment**: Are you building against **dev** or **production** endpoints? Dev endpoints work without an API key but are rate-limited and not suitable for production. Production requires an API key — apply at `pond.dflow.net/get-started/api-key`.
2. **Platform fees**: Do you want to charge platform fees? If yes, what bps and what fee account (wallet address) should receive them?
3. **Client environment**: Are you building web, mobile, backend, or CLI?

## Trade Flow

The app requests an order, the user signs a single transaction, the app submits it to an RPC, and confirms.

- Deterministic execution: the route is fixed at quote time.
- Synchronous: settles atomically in one transaction.
- The app can modify the swap transaction for composability.
- Supports venue selection via `dexes` parameter.

Flow:

1. `GET /order` with `userPublicKey`, input/output mints, amount, slippage
2. Deserialize and sign the returned base64 transaction
3. Submit to Solana RPC
4. Confirm transaction

### `executionMode` in the `/order` Response

The response includes an `executionMode` field (`sync` or `async`) that determines how to confirm:

- `sync` — Trade executes atomically in one transaction. Use standard RPC confirmation.
- `async` — Trade executes across multiple transactions. Poll `/order-status` to track fills.

## Recommended Endpoint

The `/order` endpoint is the recommended way to execute trades. The older `/quote`, `/swap`, and `/swap-instructions` endpoints still work but `/order` is simpler and preferred for new integrations.

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
- **Exact Priority Fee**: fixed fee in lamports.

Default if unset: automatic priority fees capped at 0.005 SOL.

## Platform Fees (Ask Early)

Platform fees let builders monetize trades. Fees can be collected from `inputMint` or `outputMint`.

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

Full runnable examples are in the DFlow Cookbook Repo: `https://github.com/DFlowProtocol/cookbook`
