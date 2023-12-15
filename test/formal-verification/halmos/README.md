# Formally verifying Mantle LSP with Halmos

A simple Halmos symbolic execution test to try to break the invariants—meaning that there should be no way to extract more ETH than initially staked, and no way to extract more `mETH` than the internal accounting allows.

Basically, it will call accessible functions with symbolic inputs, a given amount of times, and check if the invariants are broken (verify the caller's balances in ETH and `mETH`).

## Running Halmos tests

1. [Install Halmos](https://github.com/a16z/halmos/blob/main/docs/getting-started.md).

2. Run (from root) `halmos`

## Tips

- [See Halmos SVM cheatcodes for reference](https://github.com/a16z/halmos-cheatcodes/blob/main/src/SVM.sol)
