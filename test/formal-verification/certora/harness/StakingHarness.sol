// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "src/Staking.sol";

contract VoteLockupHarness is Staking {
    constructor() Staking() {}
}
