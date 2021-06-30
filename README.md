# NFT Example

## Description
Just an example of an NFT contract implementing openzeppelin interfaces. Fully functional and tested.

## Installation

1. Install truffle

```bash
npm install truffle -g
```

2. Install dependencies by running:

```bash
npm install

```

## Test

```bash
truffle test
```

## Deploy

.secret file requires to have MNEMONIC seed in it to deploy to other networks and configure rpc url in truffle-config.js

```bash
npm run migrate:network_name
```

You can also run:

```bash
truffle migrate --network network_name --reset
```
