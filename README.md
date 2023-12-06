# fuzzing-mantle-lsp

A simple echidna fuzzing operation of the Mantle staking contract, with `optimization` mode, to try to extract as much `mETH` as possible.

1. Get the interfaces for the contracts ([see below](#generate-an-interface-from-the-on-chain-contract))

## Contract addresses (2023-12-06)

### Staking

- [Proxy](https://etherscan.io/address/0xe3cBd06D7dadB3F4e6557bAb7EdD924CD1489E8f)
- [Implementation](https://etherscan.io/address/0xdecacc56fc347274d3df2b709602632845611d39)

### mETH

- [Proxy](https://etherscan.io/address/0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa)
- [Implementation](https://etherscan.io/address/0xc9173bf8bd5c1b071b5cae4122202a347b7eefab)

## Generate an interface from the on-chain contract

There are probably more efficient ways than this, but this works fine. Take this example from the `mETH` contract:

1. [Navigate to the contract on Etherscan](https://etherscan.io/address/0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa#code)

2. Read as proxy, copy [the implementation address (2023-12-06)](https://etherscan.io/address/0xc9173bf8bd5c1b071b5cae4122202a347b7eefab#code)

3. Run Foundry `cast interface -n METH -o interfaces/ImETH.sol <IMPLEMENTATION_ADDRESS>`
