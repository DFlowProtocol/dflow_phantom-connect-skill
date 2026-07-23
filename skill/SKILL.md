---
name: dflow-phantom-connect
description: "Build Solana wallet-connected apps with Phantom Connect SDKs and DFlow spot trading. Use when user asks to connect a Phantom wallet, integrate Phantom in React, React Native, or vanilla JS, sign messages or transactions, build token-gated pages, mint NFTs, accept crypto payments, or swap/stream tokens with DFlow. Covers @phantom/react-sdk, @phantom/react-native-sdk, @phantom/browser-sdk, and DFlow spot trading and market-data streaming. Do NOT use for Ethereum or EVM wallet integrations, or non-DFlow DEX routing."
license: MIT
metadata:
  author: DFlow & Phantom Connect
  version: 1.1.0
  tags: [solana, phantom, wallet, trading, market-data]
  mcp-server: pond.dflow.net/mcp
---

# Phantom Connect + DFlow Skill

## Instructions

### Step 1: Identify What the User Wants to Build

Determine the domain, then route to the right references.

**Wallet connection and Solana interactions:**

- Connecting a Phantom wallet (React, React Native, vanilla JS)
- Signing messages or transactions
- Token-gated access
- NFT minting
- Crypto payments
- Solana transfers (SOL or SPL tokens)

**DFlow trading & market data:**

- Spot token swaps (quote, sign, submit, confirm)
- Live prices, order-book depth, or priority-fee streaming

Many tasks combine both (for example, a swap UI needs wallet connection AND DFlow trading). Read all relevant references before writing code.

### Step 2: Read the Relevant References

**Phantom Connect SDKs** (wallet connection, signing, auth):

- `references/react-sdk.md`: React hooks, components, theming, PhantomProvider
- `references/react-native-sdk.md`: Expo config, polyfills, deep links, mobile auth
- `references/browser-sdk.md`: BrowserSDK init, events, wallet discovery, vanilla JS

**Solana patterns** (transactions, gating, minting, payments):

- `references/transactions.md`: SOL/SPL transfers, signing, fee estimation
- `references/token-gating.md`: client-side and server-side token-gated access
- `references/nft-minting.md`: mint pages, Metaplex Core, compressed NFTs
- `references/payments.md`: SOL/USDC payments, checkout with backend verification

**DFlow** (swaps, streaming):

- `references/dflow-crypto-trading.md`: spot swaps via `/order` (atomic units, base58 mints, quote-without-wallet, priority/platform/sponsor fees)
- `references/dflow-websockets.md`: real-time quote, order-book, and priority-fee streaming (browser proxies through the backend)

### Step 3: Ask the Right Questions

Before implementing, ask questions based on the domain:

**For Phantom Connect tasks:**

- Which platform? (React, React Native, vanilla JS)
- Do they need social login (Google/Apple) or extension only?

**For DFlow tasks:**

- Do you have a DFlow API key? (Yes: prod host with `x-api-key`. No: dev host, rate-limited. Prod key: pond.dflow.net/get-started/api-key.) It's one key for everything DFlow.
- Client environment? (web, mobile, backend, CLI) Browser apps keep the key on the backend and proxy DFlow HTTP and WebSocket through it.
- Platform fees? If yes, what bps and which builder-owned fee account (which must already exist)?

### Step 4: Implement

Follow the patterns in the reference files. Key rules by domain:

**Phantom Connect:**

- All SDK details (provider setup, hooks, components, auth providers) are in the SDK reference files. Read them before writing Phantom integration code.

**DFlow:**

- Trades are synchronous: one `/order` call returns a signed-ready transaction that you sign, submit, and confirm.
- As a security best practice, keep the DFlow API key on the backend, not in browser code. Browser apps proxy DFlow HTTP (`/order` serves no CORS) and the WebSocket streams through their backend.
- Dev endpoints (`dev-quote-api.dflow.net`) work without a key but are rate-limited; production requires a key from pond.dflow.net/get-started/api-key. In production, quote and book stream access is granted per key.

### Step 5: Handle Errors

Each reference file contains domain-specific error handling. Key cross-cutting concerns:

- User rejects a transaction or signature request
- Wallet not connected when a signed action is attempted
- DFlow API returns 429 (rate limited): retry with backoff or get a production API key
- `route_not_found` from DFlow: a likely cause is insufficient liquidity for the pair at that size; also check the mint addresses and that `amount` is in atomic units

## Examples

### Example 1: React wallet connection

User says: "Add Phantom wallet login to my Next.js app"

Actions:

1. Read `references/react-sdk.md`
2. Install `@phantom/react-sdk`
3. Wrap app in PhantomProvider with desired auth providers and appId
4. Use `useModal` hook for a connect button
5. Use `useAccounts` to display the connected wallet address

Result: Working wallet connection with social login and extension support

### Example 2: Token-gated page

User says: "Build a page that only BONK holders can see"

Actions:

1. Read `references/react-sdk.md` and `references/token-gating.md`
2. Set up wallet connection
3. Query the BONK token balance for the connected wallet
4. Conditionally render content based on balance threshold
5. For production: add server-side signature verification

Result: Page that checks wallet token balance and gates content

### Example 3: DFlow token swap

User says: "Add a swap feature using DFlow"

Actions:

1. Ask: API key? Client environment? Platform fees?
2. Read `references/dflow-crypto-trading.md`
3. Use the `/order` flow: request the order (proxy through the backend in a browser), deserialize the returned transaction, sign, submit, and confirm
4. In a browser, sign and send with the Phantom SDK (see `references/transactions.md`); server-side, sign with a keypair and submit through your RPC

Result: Working swap with DFlow routing

### Example 4: Full swap page with wallet connection

User says: "Build a full swap page with wallet connect and DFlow"

Actions:

1. Ask: which platform? API key? Platform fees?
2. Read the relevant SDK reference AND `references/dflow-crypto-trading.md`
3. Set up wallet connection with the Phantom SDK
4. Build the swap form; proxy `/order` through the backend so the key stays server-side
5. Sign and send with the Phantom SDK, then confirm

Result: End-to-end swap page combining Phantom wallet and DFlow trading

### Example 5: Live order book

User says: "Show a live order book for a token pair"

Actions:

1. Read `references/dflow-websockets.md`
2. Stand up a backend relay that holds the key, opens `/book-stream` with the `x-api-key` header, and relays frames to the browser
3. Subscribe with `{ op: "subscribe", base_mint, quote_mint }`; render the batched per-slot `updates[]`
4. Reconnect and re-subscribe on drop

Result: Live streaming order book, key kept server-side

## Resources

- Phantom Portal: phantom.com/portal/login
- Phantom Docs: docs.phantom.com/introduction
- SDK Examples: github.com/phantom/phantom-connect-sdk/tree/main/examples
- Phantom MCP Server: docs.phantom.com/resources/mcp-server
- DFlow MCP Server: pond.dflow.net/mcp
- DFlow MCP Docs: pond.dflow.net/ai/mcp
- DFlow Docs: pond.dflow.net/introduction
