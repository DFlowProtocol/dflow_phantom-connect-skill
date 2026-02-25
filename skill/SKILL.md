---
name: dflow-phantom-connect
description: "Build Solana wallet-connected apps with Phantom Connect SDKs and DFlow trading. Use when user asks to connect a Phantom wallet, integrate Phantom in React, React Native, or vanilla JS, sign messages or transactions, build token-gated pages, mint NFTs, accept crypto payments, swap tokens with DFlow, trade prediction markets, or integrate Proof KYC verification. Covers @phantom/react-sdk, @phantom/react-native-sdk, @phantom/browser-sdk, DFlow spot trading, DFlow prediction markets, and DFlow Proof identity verification. Do NOT use for Ethereum or EVM wallet integrations, or non-DFlow DEX routing."
license: MIT
metadata:
  author: DFlow & Phantom Connect
  version: 1.0.0
  tags: [solana, phantom, wallet, trading, prediction-markets, kyc]
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

**DFlow trading:**

- Spot token swaps (imperative or declarative)
- Prediction market discovery, trading, and redemption
- Proof KYC identity verification

Many tasks combine both (e.g., a swap UI needs wallet connection AND DFlow trading). Read all relevant references before writing code.

### Step 2: Read the Relevant References

**Phantom Connect SDKs** (wallet connection, signing, auth):

- `references/react-sdk.md` — React hooks, components, theming, PhantomProvider
- `references/react-native-sdk.md` — Expo config, polyfills, deep links, mobile auth
- `references/browser-sdk.md` — BrowserSDK init, events, wallet discovery, vanilla JS

**Solana patterns** (transactions, gating, minting, payments):

- `references/transactions.md` — SOL/SPL transfers, signing, fee estimation
- `references/token-gating.md` — client-side and server-side token-gated access
- `references/nft-minting.md` — mint pages, Metaplex Core, compressed NFTs
- `references/payments.md` — SOL/USDC payments, checkout with backend verification

**DFlow trading** (swaps, prediction markets, KYC):

- `references/dflow-crypto-trading.md` — spot token swaps, imperative vs declarative trades, slippage, priority fees, platform fees
- `references/dflow-prediction-markets.md` — market discovery, trading, redemption, maintenance windows, fee models
- `references/dflow-websockets.md` — real-time price, trade, and orderbook streaming via WebSocket
- `references/dflow-proof.md` — Proof KYC verification (required for prediction market trades, usable for any gated feature)

### Step 3: Ask the Right Questions

Before implementing, ask questions based on the domain:

**For Phantom Connect tasks:**

- Which platform? (React, React Native, vanilla JS)
- Do they need social login (Google/Apple) or extension only?

**For DFlow spot trades:**

- Imperative or declarative? If unsure, suggest starting with imperative.
- Dev or production endpoints? If production, remind them to apply for an API key at pond.dflow.net/build/api-key.
- Platform fees? If yes, what bps and what fee account?
- Client environment? (web, mobile, backend, CLI)

**For DFlow prediction markets:**

- Settlement mint? (USDC or CASH — these are the only two)
- Dev or production endpoints? If production, remind them to apply for an API key at pond.dflow.net/build/api-key.
- Platform fees? If yes, use `platformFeeScale` for dynamic fees.
- Client environment? (web, mobile, backend, CLI)

### Step 4: Implement

Follow the patterns in the reference files. Key rules by domain:

**Phantom Connect:**

- All SDK details (provider setup, hooks, components, auth providers) are in the SDK reference files. Read them before writing Phantom integration code.

**DFlow Trading:**

- Dev endpoints (`dev-quote-api.dflow.net`, `dev-prediction-markets-api.dflow.net`, `wss://dev-prediction-markets-api.dflow.net/api/v1/ws`) work without an API key but are rate-limited. Production requires a key from pond.dflow.net/build/api-key.
- Prediction market trades require Proof KYC before buying or selling outcome tokens. Browsing and discovery do not require KYC.
- Prediction markets also require geoblocking for restricted jurisdictions.

### Step 5: Handle Errors

Each reference file contains domain-specific error handling. Key cross-cutting concerns:

- User rejects a transaction or signature request
- Wallet not connected when a signed action is attempted
- DFlow API returns 429 (rate limited) — retry with backoff or get a production API key
- `route_not_found` from DFlow — check amount units (must be atomic), check liquidity, check mint addresses

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

1. Ask: imperative or declarative? Platform fees? Client environment?
2. Read `references/dflow-crypto-trading.md`
3. If unsure on trade type, suggest imperative `/order` flow (simpler, synchronous)
4. Connect wallet with Phantom, sign and submit transaction to Solana RPC

Result: Working swap UI with DFlow routing

### Example 4: Prediction market trade

User says: "Let users buy YES/NO positions on prediction markets"

Actions:

1. Ask: settlement mint (USDC or CASH)? Platform fees? Client environment?
2. Read `references/dflow-prediction-markets.md` and `references/dflow-proof.md`
3. Build market discovery UI from Metadata API
4. Gate trades behind Proof KYC verification
5. Use /order endpoint to trade settlement mint into outcome tokens

Result: Prediction market UI with KYC-gated trading

### Example 5: Swap UI with wallet connection

User says: "Build a full swap page with wallet connect and DFlow"

Actions:

1. Ask: which platform? Imperative or declarative swap? Platform fees?
2. Read the relevant SDK reference AND `references/dflow-crypto-trading.md`
3. Set up wallet connection with Phantom
4. Build swap form, proxy `/order` calls through backend
5. Sign transaction with connected wallet, submit to RPC

Result: End-to-end swap page combining Phantom wallet and DFlow trading

## Resources

- Phantom Portal: phantom.com/portal
- Phantom Docs: docs.phantom.com
- SDK Examples: github.com/phantom/wallet-sdk/tree/main/examples
- Phantom MCP Server: docs.phantom.com/resources/mcp-server
- DFlow MCP Server: pond.dflow.net/mcp
- DFlow MCP Docs: pond.dflow.net/build/mcp
- DFlow Docs: pond.dflow.net/introduction
- DFlow Cookbook: github.com/DFlowProtocol/cookbook
