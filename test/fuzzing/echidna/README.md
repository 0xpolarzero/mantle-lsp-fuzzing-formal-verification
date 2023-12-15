# Fuzzing Mantle LSP with Echidna

A simple Echidna fuzzing campaign directly over the deployed Mantle staking contract, with `optimization` mode, to try to extract as much ETH and/or `mETH` as possible.

Basically, it will fuzz the staking contract with semi-random inputs, and initiate (mock) validators whenever there is a multiple of 32 ETH staked. All this, while the invariant tries to get the highest possible combined `ETH` and `mETH` balance.

See [this article](https://blog.trailofbits.com/2023/07/21/fuzzing-on-chain-contracts-with-echidna/) for reference.

## Running fuzz/invariants tests

1. [Install Echidna](https://github.com/crytic/echidna#installation).

2. Rename `echidna-config.yaml.example` to `echidna-config.yaml` and fill in the values.

3. Run (from root) `echidna test/fuzzing/echidna/src/Staking.Invariants.t.sol --contract StakingInvariantsEchidna --config test/fuzzing/echidna/echidna-config.yaml`

## Tips

- [Get the interfaces for the contracts](#generate-an-interface-from-the-on-chain-contract)

## Generate an interface from the on-chain contract

There are probably more efficient ways than this, but the following works fine.

1. Navigate to the contract on Etherscan

2. Read as proxy, copy the implementation address

3. Run Foundry `cast interface -n METH -o interfaces/ImETH.sol <IMPLEMENTATION_ADDRESS>`
