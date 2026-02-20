# DFlow Proof (KYC)

Identity verification that links verified real-world identities to Solana wallets. Builders check wallet verification status and deep-link users to Proof for KYC when needed.

**Required for**: Prediction market outcome token buying and selling. See [dflow-prediction-markets.md](dflow-prediction-markets.md) for when to gate.

**Also useful for**: Gated features, compliance-aware apps, onboarding flows, or any flow that needs verified wallet ownership.

For full docs, integration timelines, and API reference, use the DFlow MCP server (`SearchDFlow`) or see pond.dflow.net/learn/proof.

## Key Facts

- **KYC provider**: Proof uses Stripe Identity under the hood.
- **Cost**: There is no fee to use Proof.
- **Geoblocking is still required**: KYC verifies identity, but geoblocking is still needed because prediction markets are not permitted in all jurisdictions.

## Verify API

Check if a wallet is verified by calling `GET https://proof.dflow.net/verify/{address}`. Returns `{ "verified": true }` or `{ "verified": false }`.

For prediction markets: call before allowing buys/sells of outcome tokens. Gate only at trade time — not for browsing markets or API access.

## Deep Link Flow (Send Unverified Users to Proof)

When a user is unverified, redirect them to Proof with ownership proof:

1. User connects wallet (e.g., via Phantom Connect).
2. Have user sign the message: `Proof KYC verification: {timestamp}` (timestamp is `Date.now()` in milliseconds).
3. Build deep link: `https://dflow.net/proof?wallet=...&signature=...&timestamp=...&redirect_uri=...`
4. Open in new tab or redirect.
5. User completes KYC at Proof (or cancels) and is redirected to your `redirect_uri`.
6. Call verify API again on return to confirm status. If they cancelled, `verified` will still be false.

Required params: `wallet`, `signature` (base58-encoded), `timestamp`, `redirect_uri`. Optional: `projectId` for tracking.

## Gating Rules

- Gate Proof verification **only when the user attempts to trade** (buy or sell outcome tokens).
- Do **not** gate browsing, market discovery, fetching events/orderbooks, or any read-only API access.
- Always re-verify after the user returns from the Proof deep link — do not cache the result indefinitely.

## Resources

- [Proof overview and timelines](https://pond.dflow.net/learn/proof)
- [Partner integration guide](https://pond.dflow.net/build/proof/partner-integration)
- [Proof API reference](https://pond.dflow.net/build/proof-api/introduction)
