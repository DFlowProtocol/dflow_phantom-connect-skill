# DFlow WebSockets

Real-time streaming of prediction market data via WebSocket. Use for live price tickers, trade feeds, orderbook depth, and market monitoring.

## Connection

The WebSocket URL is the production Prediction Markets API URL with the `https` scheme swapped for `wss`:

- Production Metadata API: `https://prediction-markets-api.dflow.net`
- WebSocket URL: `wss://prediction-markets-api.dflow.net`

A valid API key is required. Pass it via the `x-api-key` header when connecting. Request an API key at: pond.dflow.net/build/api-key

```ts
const WS_URL = "wss://prediction-markets-api.dflow.net";
const API_KEY = process.env.DFLOW_API_KEY;

const ws = new WebSocket(WS_URL, {
  headers: {
    "x-api-key": API_KEY,
  },
});
```

## Channels

| Channel     | Description                                   |
| ----------- | --------------------------------------------- |
| `prices`    | Real-time bid/ask price updates for markets   |
| `trades`    | Real-time trade execution updates             |
| `orderbook` | Real-time orderbook depth updates for markets |

## Subscription Management

After connecting, send JSON messages to subscribe or unsubscribe.

### Subscribe to all markets on a channel

```json
{
  "type": "subscribe",
  "channel": "prices",
  "all": true
}
```

### Subscribe to specific market tickers

```json
{
  "type": "subscribe",
  "channel": "prices",
  "tickers": ["BTCD-25DEC0313-T92749.99", "SPX-25DEC0313-T5000"]
}
```

### Unsubscribe from all markets

```json
{
  "type": "unsubscribe",
  "channel": "prices",
  "all": true
}
```

### Unsubscribe from specific tickers

```json
{
  "type": "unsubscribe",
  "channel": "prices",
  "tickers": ["BTCD-25DEC0313-T92749.99"]
}
```

### Subscription rules

- Subscribing to `"all": true` clears any specific ticker subscriptions for that channel.
- Subscribing to specific tickers disables "all" mode for that channel.
- Each channel maintains independent subscription state.
- Unsubscribing from specific tickers has no effect if you are subscribed to "all" for that channel. Unsubscribe from "all" first.

## Prices Channel

Response format:

```json
{
  "channel": "prices",
  "type": "ticker",
  "market_ticker": "BTCD-25DEC0313-T92749.99",
  "yes_bid": "0.45",
  "yes_ask": "0.47",
  "no_bid": "0.53",
  "no_ask": "0.55"
}
```

| Field           | Type           | Description                    |
| --------------- | -------------- | ------------------------------ |
| `market_ticker` | string         | Market identifier              |
| `yes_bid`       | string or null | Best bid price for YES outcome |
| `yes_ask`       | string or null | Best ask price for YES outcome |
| `no_bid`        | string or null | Best bid price for NO outcome  |
| `no_ask`        | string or null | Best ask price for NO outcome  |

Price fields may be `null` if there is no current bid or ask at that level.

## Trades Channel

Response format:

```json
{
  "channel": "trades",
  "type": "trade",
  "market_ticker": "BTCD-25DEC0313-T92749.99",
  "trade_id": "abc123",
  "price": 47,
  "count": 100,
  "yes_price": 47,
  "no_price": 53,
  "yes_price_dollars": "0.47",
  "no_price_dollars": "0.53",
  "taker_side": "yes",
  "created_time": 1702744800000
}
```

| Field               | Type   | Description                           |
| ------------------- | ------ | ------------------------------------- |
| `market_ticker`     | string | Market identifier                     |
| `trade_id`          | string | Unique trade identifier               |
| `price`             | number | Trade execution price                 |
| `count`             | number | Number of contracts traded            |
| `yes_price`         | number | YES outcome price at execution        |
| `no_price`          | number | NO outcome price at execution         |
| `yes_price_dollars` | string | YES price formatted in dollars        |
| `no_price_dollars`  | string | NO price formatted in dollars         |
| `taker_side`        | string | Side of the taker (`"yes"` or `"no"`) |
| `created_time`      | number | Unix timestamp in milliseconds        |

## Orderbook Channel

Response format:

```json
{
  "channel": "orderbook",
  "type": "orderbook",
  "market_ticker": "BTCD-25DEC0313-T92749.99",
  "yes_bids": {
    "0.45": 1000,
    "0.44": 500,
    "0.43": 200
  },
  "no_bids": {
    "0.55": 1500,
    "0.56": 800,
    "0.57": 300
  }
}
```

| Field           | Type   | Description                                                     |
| --------------- | ------ | --------------------------------------------------------------- |
| `market_ticker` | string | Market identifier                                               |
| `yes_bids`      | object | Map of price (string) to quantity (number) for YES outcome bids |
| `no_bids`       | object | Map of price (string) to quantity (number) for NO outcome bids  |

## Quick Start Example

```ts
const WS_URL = "wss://prediction-markets-api.dflow.net";
const API_KEY = process.env.DFLOW_API_KEY;

const ws = new WebSocket(WS_URL, {
  headers: { "x-api-key": API_KEY },
});

ws.onopen = () => {
  // Subscribe to all channels
  ws.send(JSON.stringify({ type: "subscribe", channel: "prices", all: true }));
  ws.send(JSON.stringify({ type: "subscribe", channel: "trades", all: true }));
  ws.send(JSON.stringify({ type: "subscribe", channel: "orderbook", all: true }));
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  switch (msg.channel) {
    case "prices":
      console.log("Price:", msg.market_ticker, msg.yes_bid, msg.yes_ask);
      break;
    case "trades":
      console.log("Trade:", msg.market_ticker, msg.taker_side, msg.count);
      break;
    case "orderbook":
      console.log("Book:", msg.market_ticker, msg.yes_bids, msg.no_bids);
      break;
  }
};

ws.onerror = (err) => console.error("WS error:", err);
ws.onclose = () => console.log("WS closed");
```

## Best Practices

- Implement reconnection logic with exponential backoff.
- Subscribe only to the markets you need. Use specific tickers rather than "all" when possible to reduce bandwidth.
- Process messages asynchronously to avoid blocking during high-volume periods.
- Always implement `onerror` and `onclose` handlers.
