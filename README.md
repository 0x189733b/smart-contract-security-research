## Setup & Running PoCs

```bash
git clone https://github.com/0x189733b/smart-contract-security-research.git
cd smart-contract-security-research
forge install

# Set RPC URL
export MAINNET_RPC_URL="https://eth-mainnet.alchemyapi.io/v2/YOUR_KEY"

# Example: Run Oracle Manipulation PoC
cd pocs/oracle-manipulation && forge test -vvv

# Run all PoCs
forge test --match-path "pocs/*" -vvv

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
