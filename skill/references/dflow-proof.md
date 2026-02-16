# DFlow Proof (KYC)

Identity verification that links verified real-world identities to Solana wallets. Builders check wallet verification status and deep-link users to Proof for KYC when needed.

**Required for**: Prediction market outcome token buying and selling. See [dflow-prediction-markets.md](dflow-prediction-markets.md) for when to gate.

**Also useful for**: Gated features, compliance-aware apps, onboarding flows, or any flow that needs verified wallet ownership. The same verify API and deep link work for any use case.

For full docs and integration timelines: https://pond.dflow.net/learn/proof

## Key Facts

- **KYC provider**: Proof uses Stripe Identity under the hood.
- **Cost**: There is no fee to use Proof.
- **Geoblocking is still required**: KYC verifies user identity, but geoblocking is still required because prediction markets are not permitted in all jurisdictions. Use geoblocking to restrict access where local regulations do not allow prediction markets, even if Proof KYC is in place.

## Verify API

Check if a wallet is verified:

```bash
curl "https://proof.dflow.net/verify/{address}"
# → { "verified": true } or { "verified": false }
```

For prediction markets: call before allowing buys/sells of outcome tokens. Gate only at trade time—not for browsing markets or API access. For other use cases: call whenever you need to gate a feature by verification status.

## Deep Link (Send Unverified Users to Proof)

When a user is unverified, redirect them to Proof with ownership proof. Required params:

| Param         | Required | Description                              |
| ------------- | -------- | ---------------------------------------- |
| `wallet`      | Yes      | Solana wallet address                    |
| `signature`   | Yes      | Base58-encoded signature of the message  |
| `timestamp`   | Yes      | Unix timestamp in milliseconds          |
| `redirect_uri`| Yes      | URL to return to after verification     |
| `projectId`   | No       | Project identifier for tracking          |

**Message format** (user must sign this with their wallet):

```
Proof KYC verification: {timestamp}
```

Example flow:

1. User connects wallet (e.g. via Phantom Connect).
2. Have user sign `Proof KYC verification: {Date.now()}`.
3. Build deep link: `https://dflow.net/proof?wallet=...&signature=...&timestamp=...&redirect_uri=...`
4. Open in new tab or redirect.
5. User completes KYC at Proof (or cancels); they are redirected to your `redirect_uri` either way.
6. Call verify API again on return to confirm status. If they cancelled, `verified` will still be false.

## Minimal Code

```ts
// Verify
const res = await fetch(`https://proof.dflow.net/verify/${address}`);
const { verified } = await res.json();

// Build deep link (after user signs message)
const timestamp = Date.now();
const message = `Proof KYC verification: ${timestamp}`;
const signatureBytes = await wallet.signMessage(new TextEncoder().encode(message));
const signature = bs58.encode(signatureBytes);

const params = new URLSearchParams({
  wallet,
  signature,
  timestamp: timestamp.toString(),
  redirect_uri,
});
const deepLink = `https://dflow.net/proof?${params.toString()}`;
```

## Handling the Return

When the user completes verification (or cancels), they are redirected to your `redirect_uri`. Run this handler on that page to confirm status:

```ts
async function handleProofCallback(walletAddress: string): Promise<boolean> {
  const response = await fetch(
    `https://proof.dflow.net/verify/${walletAddress}`
  );
  const { verified } = await response.json();
  return verified;
}
```

Use the same wallet address you sent in the deep link. If the user cancelled, `verified` will be false; if they completed KYC, it will be true.

## Resources

- [Proof overview and timelines](https://pond.dflow.net/learn/proof)
- [Partner integration guide](https://pond.dflow.net/build/proof/partner-integration)
- [Proof API reference](https://pond.dflow.net/build/proof-api/introduction)
