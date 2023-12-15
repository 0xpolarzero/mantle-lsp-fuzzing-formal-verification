# Mantle LSP invariant testings and formal verification

This is a collection of fuzzing/invariant tests and formal verification over the Mantle LSP staking contract.

These additional tests are _not by any means_ an assessment of the execution flow of the whole Mantle LSP system, let alone of its staking contract. It is solely focused on verifying the accuracy of the `Staking` contract's logic, only on the following aspects:

- there should be no way to extract ETH from that contract;
- there should be no way to extract more mETH tokens that expected in the internal accounting.

_Please let me know if you find any mistake or inconsistency within the tests._

## How to setup

1. Clone this repo

```bash
git clone git@github.com:0xpolarzero/mantle-lsp-fuzzing-formal-verification.git
```

2. [Install Foundry](https://book.getfoundry.sh/getting-started/installation)

## What's inside

The current Mantle LSP contracts with existing tests (as of [commit b650094](https://github.com/mantle-lsp/contracts/commit/b650094727b870aa8940e5101667ffd8207ff3d8)).

The following tests in "optimization" mode, meaning trying to extract as much profit as possible from the contract:

- **Invariant tests** with Echidna;
- **Invariant tests** with Medusa (not yet implemented);
- **Formal verification** with Halmos;
- **Formal verification** with Certora (ongoing);

## How to run

### Echidna

Navigate to [the Echidna folder](test/fuzzing/echidna/) and follow [the dedicated instructions there](test/fuzzing/echidna/README.md).

### Medusa

Not yet implemented.

### Halmos

Navigate to [the Halmos folder](test/formal-verification/halmos/) and follow [the dedicated instructions there](test/formal-verification/halmos/README.md).

### Certora

Not yet implemented.

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
