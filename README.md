# Phantom Connect Skill for Claude

A skill that teaches Claude how to build wallet-connected Solana apps with
Phantom Connect SDKs. Also covers DFlow token swaps, prediction market trading,
and Proof KYC verification.

## What It Does

Once installed, Claude automatically uses this skill when you ask about:

- Connecting Phantom wallets in React, React Native, or vanilla JS
- Signing messages or transactions with Phantom
- Building token-gated pages
- NFT minting experiences
- Crypto payment flows
- Solana transactions and transfers
- DFlow token swaps (declarative and imperative)
- Prediction market discovery and trading
- Proof KYC identity verification

## Installation

### Claude.ai

1. Download or clone this repo
2. Zip the `skill/` folder
3. Go to Claude.ai > Settings > Capabilities > Skills
4. Click "Upload skill" and select the zip

### Claude Code (Personal)

```bash
git clone https://github.com/DFlowProtocol/dflow_phantom-connect-skill.git
cp -r dflow_phantom-connect-skill/skill ~/.claude/skills/dflow-phantom-connect
```

### Claude Code (Project)

```bash
cp -r dflow_phantom-connect-skill/skill .claude/skills/dflow-phantom-connect
```

### Using the Install Script

```bash
# Install to personal directory (default)
./install.sh

# Install to project directory
./install.sh --project

# Install to custom location
./install.sh --path /custom/path/skills/dflow-phantom-connect
```

## Skill Structure

```
skill/
├── SKILL.md                         # Main skill instructions (required)
└── references/                      # Detailed references (loaded as needed)
    ├── react-sdk.md                 # @phantom/react-sdk hooks, components, theming
    ├── react-native-sdk.md          # @phantom/react-native-sdk setup, Expo, deep links
    ├── browser-sdk.md               # @phantom/browser-sdk init, events, discovery
    ├── transactions.md              # SOL/SPL transfers, signing, fee estimation
    ├── token-gating.md              # Client-side and server-side token gating
    ├── nft-minting.md               # Mint pages, Metaplex Core, compressed NFTs
    ├── payments.md                  # SOL/USDC payments, checkout verification
    ├── dflow-crypto-trading.md      # DFlow spot trading, declarative vs imperative
    ├── dflow-prediction-markets.md  # Market discovery, trading, redemption
    ├── dflow-websockets.md          # Real-time price, trade, orderbook streaming
    └── dflow-proof.md               # Proof KYC verification
```

## Example Prompts

```
"Create a Next.js app with Phantom wallet connection"
"Build a token-gated page that requires 100 BONK to access"
"Make an NFT mint page with quantity selector and status handling"
"Add crypto checkout to my e-commerce site"
"Help me send a Solana transaction with the React SDK"
"Convert this to use the Browser SDK instead of React"
"Add a DFlow swap flow to my app"
"Help me trade into a prediction market position"
"Build a swap UI that lists wallet tokens on the FROM side"
"Add Proof KYC verification before prediction market buys"
```

## SDK Choices

| Platform     | Package                     | Use Case               |
| ------------ | --------------------------- | ---------------------- |
| React Web    | `@phantom/react-sdk`        | Next.js, Vite, CRA     |
| React Native | `@phantom/react-native-sdk` | Expo, bare RN          |
| Vanilla JS   | `@phantom/browser-sdk`      | Vue, Angular, vanilla  |
| Solana       | `@solana/web3.js`           | Transactions, balances |

## Prerequisites

All Phantom Connect integrations require:

1. **Phantom Portal Account** — [phantom.com/portal](https://phantom.com/portal)
2. **App ID** — Get from Portal, required for Google/Apple social login
3. **Allowlisted URLs** — Add domains and redirect URLs in Portal

For DFlow integrations:

- Dev endpoints work without an API key but are rate-limited
- [Apply for an API key](https://pond.dflow.net/build/api-key) before releasing to production
- Prediction markets [require geoblocking](https://pond.dflow.net/learn/prediction-markets#regulatory-and-compliance-requirements) for restricted jurisdictions

## How the Skill Works

The skill uses progressive disclosure. `SKILL.md` provides Claude with routing
instructions and core knowledge. When a specific topic comes up, Claude reads
the relevant file from `references/` to get detailed implementation patterns.
This keeps context usage efficient.

## Related Resources

- [Phantom Developer Docs](https://docs.phantom.com)
- [Phantom Portal](https://phantom.com/portal)
- [SDK Examples](https://github.com/phantom/wallet-sdk/tree/main/examples)
- [Phantom MCP Server](https://docs.phantom.com/resources/mcp-server)
- [DFlow MCP Server](https://pond.dflow.net/mcp)
- [DFlow Docs](https://pond.dflow.net/introduction)
- [DFlow Cookbook](https://github.com/DFlowProtocol/cookbook)

## Contributing

Contributions welcome! Please ensure updates reflect current SDK best practices.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License — see [LICENSE](LICENSE) for details.
