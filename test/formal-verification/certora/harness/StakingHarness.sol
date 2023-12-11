// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "src/Staking.sol";

contract StakingHarness is Staking {
    constructor() Staking() {
        // call init
    }
}
