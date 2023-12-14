// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Initializer contract to call init functions in external contracts.
/// @dev We're actually linking contracts inside the conf file, but we might as well do it right the initialization way...
/// @dev - Staking
//  struct Init {
//      address admin;
//      address manager;
//      address allocatorService;
//      address initiatorService;
//      address returnsAggregator;
//      address withdrawalWallet;
//      IMETH mETH;
//      IDepositContract depositContract;
//      IOracleReadRecord oracle;
//      IPauserRead pauser;
//      IUnstakeRequestsManager unstakeRequestsManager;
//  }
/// @dev - METH
//  struct Init {
//      address admin;
//      IStaking staking;
//      IUnstakeRequestsManager unstakeRequestsManager;
//  }
/// @dev - UnstakeRequestManager
//  struct Init {
//     address admin;
//     address manager;
//     address requestCanceller;
//     IMETH mETH;
//     IStakingReturnsWrite stakingContract;
//     IOracleReadRecord oracle;
//     uint256 numberOfBlocksToFinalize;
//  }
/// @dev - Pauser
//  struct Init {
//     address admin;
//     address pauser;
//     address unpauser;
//     IOracle oracle;
//  }
/// @dev - Oracle
//  struct Init {
//     address admin;
//     address manager;
//     address oracleUpdater;
//     address pendingResolver;
//     IReturnsAggregatorWrite aggregator;
//     IPauser pauser;
//     IStakingInitiationRead staking;
//  }
/// @dev - ReturnsReceiver (x2): consensusLayerReceiver & executionLayerReceiver
//  struct Init {
//     address admin;
//     address manager;
//     address withdrawer;
//  }
/// @dev - ReturnsAggregator
//  struct Init {
//     address admin;
//     address manager;
//     IOracleReadRecord oracle;
//     IPauserRead pauser;
//     ReturnsReceiver consensusLayerReceiver;
//     ReturnsReceiver executionLayerReceiver;
//     IStakingReturnsWrite staking;
//     address payable feesReceiver;
//  }

import {StakingHarness} from "test/formal-verification/certora/harness/StakingHarness.sol";
import {Staking} from "test/formal-verification/certora/src/Staking.sol";
import {MockDepositContract} from "test/formal-verification/certora/mocks/MockDepositContract.sol";
import {METH} from "src/METH.sol";
import {UnstakeRequestsManager} from "src/UnstakeRequestsManager.sol";
import {Pauser} from "src/Pauser.sol";
import {Oracle} from "src/Oracle.sol";
import {ReturnsReceiver} from "src/ReturnsReceiver.sol";
import {ReturnsAggregator} from "src/ReturnsAggregator.sol";

contract Initializer {
    StakingHarness public staking;
    MockDepositContract public depositContract;
    METH public mETH;
    UnstakeRequestsManager public unstakeRequestsManager;
    Oracle public oracle;
    Pauser public pauser;
    ReturnsReceiver public consensusLayerReceiver;
    ReturnsReceiver public executionLayerReceiver;
    ReturnsAggregator public aggregator;

    address public ADMIN = address(0x10000);
    address public MANAGER = address(0x20000);
    address public ALLOCATOR_SERVICE = address(0x30000);
    address public INITIATOR_SERVICE = address(0x40000);
    address public WITHDRAWAL_WALLET = address(0x50000);
    address public REQUEST_CANCELLER = address(0x60000);
    address public ORACLE_UPDATER = address(0x70000);
    address public PENDING_RESOLVER = address(0x80000);
    address public PAUSER = address(0x90000);
    address public UNPAUSER = address(0xA0000);
    address public FEE_RECIPIENT = address(0xB0000);

    constructor() {
        init_helpers();
        init_staking();
        init_meth();
        init_unstakeRequestsManager();
        init_pauser();
        init_oracle();
        init_returnsReceiver();
        init_returnsAggregator();
    }

    function init_helpers() internal {
        staking.init_helpers(
            ADMIN,
            MANAGER,
            ALLOCATOR_SERVICE,
            INITIATOR_SERVICE,
            WITHDRAWAL_WALLET,
            REQUEST_CANCELLER,
            ORACLE_UPDATER,
            PENDING_RESOLVER,
            PAUSER,
            UNPAUSER,
            FEE_RECIPIENT
        );
    }

    function init_staking() internal {
        staking.initialize(
            Staking._Init(
                ADMIN,
                MANAGER,
                ALLOCATOR_SERVICE,
                INITIATOR_SERVICE,
                address(aggregator),
                WITHDRAWAL_WALLET,
                mETH,
                depositContract,
                oracle,
                pauser,
                unstakeRequestsManager
            )
        );
    }

    function init_meth() internal {
        mETH.initialize(METH.Init(ADMIN, staking, unstakeRequestsManager));
    }

    function init_unstakeRequestsManager() internal {
        unstakeRequestsManager.initialize(
            UnstakeRequestsManager.Init(ADMIN, MANAGER, REQUEST_CANCELLER, mETH, staking, oracle, 10)
        );
    }

    function init_pauser() internal {
        pauser.initialize(Pauser.Init(ADMIN, PAUSER, UNPAUSER, oracle));
    }

    function init_oracle() internal {
        oracle.initialize(Oracle.Init(ADMIN, MANAGER, ORACLE_UPDATER, PENDING_RESOLVER, aggregator, pauser, staking));
    }

    function init_returnsReceiver() internal {
        consensusLayerReceiver.initialize(ReturnsReceiver.Init(ADMIN, MANAGER, WITHDRAWAL_WALLET));
        executionLayerReceiver.initialize(ReturnsReceiver.Init(ADMIN, MANAGER, WITHDRAWAL_WALLET));
    }

    function init_returnsAggregator() internal {
        aggregator.initialize(
            ReturnsAggregator.Init(
                ADMIN,
                MANAGER,
                oracle,
                pauser,
                consensusLayerReceiver,
                executionLayerReceiver,
                staking,
                payable(FEE_RECIPIENT)
            )
        );
    }
}
