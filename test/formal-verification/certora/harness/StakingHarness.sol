// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Copy of Staking
import {Staking} from "test/formal-verification/certora/src/Staking.sol";

contract StakingHarness is Staking {
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    // Declared in Initializer, just for quick access
    address public ADMIN;
    address public MANAGER;
    address public ALLOCATOR_SERVICE;
    address public INITIATOR_SERVICE;
    address public WITHDRAWAL_WALLET;
    address public REQUEST_CANCELLER;
    address public ORACLE_UPDATER;
    address public PENDING_RESOLVER;
    address public PAUSER;
    address public UNPAUSER;
    address public FEE_RECIPIENT;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    constructor() Staking() {}

    function init_helpers(
        address _admin,
        address _manager,
        address _allocatorService,
        address _initiatorService,
        address _withdrawalWallet,
        address _requestCanceller,
        address _oracleUpdater,
        address _pendingResolver,
        address _pauser,
        address _unpauser,
        address _feeRecipient
    ) external {
        ADMIN = _admin;
        MANAGER = _manager;
        ALLOCATOR_SERVICE = _allocatorService;
        INITIATOR_SERVICE = _initiatorService;
        WITHDRAWAL_WALLET = _withdrawalWallet;
        REQUEST_CANCELLER = _requestCanceller;
        ORACLE_UPDATER = _oracleUpdater;
        PENDING_RESOLVER = _pendingResolver;
        PAUSER = _pauser;
        UNPAUSER = _unpauser;
        FEE_RECIPIENT = _feeRecipient;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   HELPERS                                  */
    /* -------------------------------------------------------------------------- */

    function helper_balance(address account) external view returns (uint256) {
        return account.balance;
    }
}
