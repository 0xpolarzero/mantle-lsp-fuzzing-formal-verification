// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/// @dev Copy of Staking
import "test/formal-verification/certora/src/Staking.sol";

contract StakingHarness is Staking {
    address public admin;
    address public manager;
    address public allocatorService;
    address public initiatorService;

    constructor() Staking() {
        // call init
        // or since we already define the mocks we don't need init, just associate addresses to the ones above
        // or maybe yes to initiate the roles
    }
}
