# Fuzzing Mantle LSP with Echidna

A simple Echidna fuzzing campaign directly over the deployed Mantle staking contract, with `optimization` mode, to try to extract as much `mETH` as possible.

Basically, it will fuzz the staking contract with semi-random inputs, and initiate (mock) validators whenever there is a multiple of 32 ETH staked. All this, while the invariant tries to get the highest possible combined `ETH` and `mETH` balance.

_Please let me know if you find any mistake or inconsistency within the tests._

See [this article](https://blog.trailofbits.com/2023/07/21/fuzzing-on-chain-contracts-with-echidna/) for reference.

## Running fuzz/invariants tests

1. [Install Echidna](https://github.com/crytic/echidna#installation).

2. Rename `echidna-config.yaml.example` to `echidna-config.yaml` and fill in the values.

3. Run (from root) `echidna test/fuzzing/echidna/src/Staking.Invariants.sol --contract StakingInvariantsEchidna --config test/fuzzing/echidna/echidna-config.yaml`

## Tips

- [Get the interfaces for the contracts](#generate-an-interface-from-the-on-chain-contract)

## Contract addresses (2023-12-06)

### Staking

- [Proxy](https://etherscan.io/address/0xe3cBd06D7dadB3F4e6557bAb7EdD924CD1489E8f)
- [Implementation](https://etherscan.io/address/0xdecacc56fc347274d3df2b709602632845611d39)

### mETH

- [Proxy](https://etherscan.io/address/0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa)
- [Implementation](https://etherscan.io/address/0xc9173bf8bd5c1b071b5cae4122202a347b7eefab)

### UnstakeRequestsManager

- [Proxy](https://etherscan.io/address/0x38fDF7b489316e03eD8754ad339cb5c4483FDcf9)
- [Implementation](https://etherscan.io/address/0x5a7b3cde8ac8d780af4797bf1517464ac54ca033)

## Generate an interface from the on-chain contract

There are probably more efficient ways than this, but the following works fine.

1. Navigate to the contract on Etherscan

2. Read as proxy, copy the implementation address

3. Run Foundry `cast interface -n METH -o interfaces/ImETH.sol <IMPLEMENTATION_ADDRESS>`
