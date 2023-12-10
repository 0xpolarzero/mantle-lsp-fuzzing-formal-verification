// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev The following is basically a copy of test/Staking.t.sol.
/// We can't inherit from it because it inherits from BaseTest and StakingEvents, which would incur unnecessary calls
/// to its public/external functions.

import {hevm} from "test/fuzzing/utils/HEVM.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "openzeppelin/proxy/transparent/ProxyAdmin.sol";
import {TimelockController} from "openzeppelin/governance/TimelockController.sol";

import {METH} from "src/METH.sol";
import {Staking} from "src/Staking.sol";
import {UnstakeRequestsManager} from "src/UnstakeRequestsManager.sol";

import {PauserStub} from "test/doubles/PauserStub.sol";
import {OracleStub} from "test/doubles/OracleStub.sol";
import {deployDepositContract, IDepositContract} from "test/doubles/DepositContract.sol";

import {newMETH, newUnstakeRequestsManager} from "test/utils/Deploy.sol";
import {upgradeToAndCall} from "script/helpers/Proxy.sol";

contract StakingBaseMedusa {
    /// @dev From BaseTest.sol
    address public immutable admin = hevm.addr(uint256(1));
    TimelockController public proxyAdmin;

    /// @dev From StakingTest
    address public immutable manager = hevm.addr(uint256(2));
    address public immutable initiator = hevm.addr(uint256(3));
    address public immutable allocator = hevm.addr(uint256(4));
    address public immutable withdrawalWallet = hevm.addr(uint256(5));
    address public immutable requestCanceller = hevm.addr(uint256(6));
    address public immutable returnsAggregator = hevm.addr(uint256(7));

    Staking public staking;
    METH public mETH;
    OracleStub public oracle;
    IDepositContract public depositContract;
    PauserStub public pauser;

    UnstakeRequestsManager public unstakeManager;

    constructor() {
        /// @dev From BaseTest
        address[] memory operators = new address[](1);
        operators[0] = address(this);
        proxyAdmin = new TimelockController({minDelay: 0, proposers: operators, executors: operators, admin: admin});

        // `timestamps <= 1` have a special meaning in `TimelockController`, so we have to advance past those.
        hevm.warp(2);

        /// @dev From StakingTest
        depositContract = deployDepositContract();
        oracle = new OracleStub();

        pauser = new PauserStub();

        // Deploy proxy manually for custom stubbed contract.
        Staking _staking = new Staking();
        ITransparentUpgradeableProxy stakingProxy = ITransparentUpgradeableProxy(
            address(new TransparentUpgradeableProxy(address(_staking), address(proxyAdmin), ""))
        );

        mETH = newMETH(
            proxyAdmin,
            METH.Init({
                admin: admin,
                staking: Staking(payable(address(stakingProxy))),
                unstakeRequestsManager: UnstakeRequestsManager(payable(address(0)))
            })
        );

        unstakeManager = newUnstakeRequestsManager(
            proxyAdmin,
            UnstakeRequestsManager.Init({
                admin: admin,
                manager: manager,
                requestCanceller: requestCanceller,
                mETH: mETH,
                oracle: oracle,
                stakingContract: Staking(payable(address(stakingProxy))),
                numberOfBlocksToFinalize: 128
            })
        );

        // Initialize staking contract
        Staking.Init memory init = Staking.Init({
            admin: admin,
            manager: manager,
            allocatorService: allocator,
            initiatorService: initiator,
            withdrawalWallet: withdrawalWallet,
            mETH: mETH,
            pauser: pauser,
            depositContract: depositContract,
            oracle: oracle,
            returnsAggregator: returnsAggregator,
            unstakeRequestsManager: unstakeManager
        });
        upgradeToAndCall(proxyAdmin, stakingProxy, address(_staking), abi.encodeCall(Staking.initialize, init));
        staking = Staking(payable(address(stakingProxy)));
    }

    function _mintMETH(uint256 amount) internal {
        _mintMETH(address(this), amount);
    }

    function _mintMETH(address to, uint256 amount) internal {
        hevm.prank(address(staking));
        mETH.mint(to, amount);
    }
}
