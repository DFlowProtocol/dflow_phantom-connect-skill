# React SDK Reference

Complete reference for `@phantom/react-sdk`.

## Prerequisites

All Phantom Connect integrations require:

1. **Phantom Portal Account** — Register at phantom.com/portal
2. **App ID** — Get from Portal (required when using Google or Apple auth providers)
3. **Allowlisted URLs** — Add your domains and redirect URLs in Portal settings

## Auth Providers

| Provider      | Description                     | Requires appId |
| ------------- | ------------------------------- | -------------- |
| `"injected"`  | Phantom browser extension       | No             |
| `"google"`    | Google OAuth (embedded wallet)  | Yes            |
| `"apple"`     | Apple ID (embedded wallet)      | Yes            |
| `"deeplink"`  | Phantom mobile app via deeplink | Yes            |

Use `"injected"` for extension-only flows (no appId needed). Add `"google"` and/or `"apple"` for social login (requires appId from Phantom Portal). Add `"deeplink"` to support connecting to the Phantom mobile app on devices where the extension is not available.

## Installation

```bash
npm install @phantom/react-sdk
# For Solana support
npm install @solana/web3.js
```

## PhantomProvider Configuration

```tsx
import { PhantomProvider, darkTheme, lightTheme } from "@phantom/react-sdk";
import { AddressType } from "@phantom/browser-sdk";

<PhantomProvider
  config={{
    providers: ["google", "apple", "injected", "deeplink"],
    appId: "your-app-id",
    addressTypes: [AddressType.solana],
    authOptions: {
      redirectUrl: "https://yourapp.com/auth/callback",
    },
  }}
  theme={darkTheme}
  appIcon="https://yourapp.com/icon.png"
  appName="Your App Name"
>
  <App />
</PhantomProvider>
```

## Available Hooks

| Hook                      | Purpose                      | Returns                                      |
| ------------------------- | ---------------------------- | -------------------------------------------- |
| `useModal`                | Control connection modal     | `{ open, close, isOpened }`                  |
| `usePhantom`              | Access wallet/user state     | `{ isConnected, isLoading, user, wallet }`   |
| `useConnect`              | Connect to wallet            | `{ connect, isConnecting, isLoading, error }`|
| `useAccounts`             | Get wallet addresses         | `WalletAddress[]` or `null`                  |
| `useDisconnect`           | Disconnect wallet            | `{ disconnect, isDisconnecting }`            |
| `useSolana`               | Solana operations            | `{ solana, isAvailable }`                    |
| `useAutoConfirm`          | Auto-confirm (injected only) | `{ enable, disable, status }`                |
| `useDiscoveredWallets`    | List injected wallets        | `{ wallets, isLoading, error, refetch }`     |
| `useIsExtensionInstalled` | Check extension              | `{ isLoading, isInstalled }`                 |
| `useTheme`                | Access current theme         | `PhantomTheme`                               |

## Hook Examples

### useModal

```tsx
function WalletButton() {
  const { open, close, isOpened } = useModal();
  const { isConnected } = usePhantom();

  if (isConnected) {
    return <button onClick={open}>Manage Wallet</button>;
  }
  return <button onClick={open}>Connect Wallet</button>;
}
```

### useConnect (Direct Connection)

```tsx
function DirectConnect() {
  const { connect, isConnecting, error } = useConnect();

  const handleConnect = async () => {
    try {
      const result = await connect({ provider: "google" });
      console.log("Connected:", result.addresses);
    } catch (err) {
      console.error("Connection failed:", err);
    }
  };

  return (
    <button onClick={handleConnect} disabled={isConnecting}>
      {isConnecting ? "Connecting..." : "Sign in with Google"}
    </button>
  );
}
```

### useAccounts

```tsx
function WalletInfo() {
  const { addresses, isConnected, walletId } = useAccounts();

  if (!isConnected) return <p>Not connected</p>;

  return (
    <div>
      <p>Wallet ID: {walletId}</p>
      {addresses?.map((addr, i) => (
        <p key={i}>{addr.addressType}: {addr.address}</p>
      ))}
    </div>
  );
}
```

### useSolana

```tsx
import { useSolana } from "@phantom/react-sdk";

function SolanaActions() {
  const { solana, isAvailable } = useSolana();

  if (!isAvailable) return <p>Solana not available</p>;

  const signMessage = async () => {
    const { signature } = await solana.signMessage("Hello Solana!");
    console.log("Signature:", signature);
  };

  const sendTx = async (transaction) => {
    const result = await solana.signAndSendTransaction(transaction);
    console.log("TX Hash:", result.hash);
  };

  const switchNetwork = async () => {
    await solana.switchNetwork("devnet"); // or "mainnet-beta", "testnet"
  };

  const getAddress = async () => {
    const pubkey = await solana.getPublicKey();
    console.log("Public Key:", pubkey);
  };

  return (
    <div>
      <button onClick={signMessage}>Sign Message</button>
      <button onClick={switchNetwork}>Switch to Devnet</button>
    </div>
  );
}
```

## Components

### ConnectButton

Pre-built button handling connection flow:

```tsx
import { ConnectButton, AddressType } from "@phantom/react-sdk";

// Default
<ConnectButton />

// Specific chain address
<ConnectButton addressType={AddressType.solana} />

// Full width
<ConnectButton fullWidth />
```

### ConnectBox

Inline connection UI (no modal backdrop):

```tsx
import { ConnectBox } from "@phantom/react-sdk";

// Default
<ConnectBox />

// Custom width
<ConnectBox maxWidth="500px" />

// Transparent (no background)
<ConnectBox transparent />
```

Use `ConnectBox` on OAuth callback pages to handle auth flow completion.

## Theming

### Pre-built Themes

```tsx
import { darkTheme, lightTheme } from "@phantom/react-sdk";

<PhantomProvider theme={darkTheme}>...</PhantomProvider>
<PhantomProvider theme={lightTheme}>...</PhantomProvider>
```

### Custom Theme

```tsx
const customTheme = {
  background: "#1a1a1a",
  text: "#ffffff",
  secondary: "#98979C",  // Must be hex for opacity derivation
  brand: "#ab9ff2",
  error: "#ff4444",
  success: "#00ff00",
  borderRadius: "16px",
  overlay: "rgba(0, 0, 0, 0.8)",
};

<PhantomProvider theme={customTheme}>...</PhantomProvider>
```

## Debug Configuration

```tsx
import { PhantomProvider, DebugLevel } from "@phantom/react-sdk";

<PhantomProvider
  config={config}
  debugConfig={{
    enabled: true,
    level: DebugLevel.INFO, // ERROR, WARN, INFO, DEBUG
    callback: (message) => console.log(message),
  }}
>
  ...
</PhantomProvider>
```

## Supported Solana Networks

| Network | Cluster      |
| ------- | ------------ |
| Mainnet | mainnet-beta |
| Devnet  | devnet       |
| Testnet | testnet      |

## Common Issues

### "appId required" error
Cause: Using `"google"` or `"apple"` provider without providing an appId.
Solution: Register at phantom.com/portal, get the App ID, and add it to the PhantomProvider config.

### Redirect not working after OAuth login
Cause: The redirect URL is not allowlisted in Phantom Portal.
Solution: Go to phantom.com/portal, open app settings, and add the exact redirect URL (including protocol and path) to the allowlist.
