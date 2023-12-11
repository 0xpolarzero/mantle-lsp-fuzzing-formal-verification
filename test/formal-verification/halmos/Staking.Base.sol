// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev This is a copy of StakingTest deployments, using a mock `DepositContract` instead of the real one,
/// since Halmos won't support its deployment using the bytecode, neither will it support the merkle tree generation in
/// the constructor.

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

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
import {IDepositContract} from "test/doubles/DepositContract.sol";
import {MockDepositContract} from "test/formal-verification/mocks/MockDepositContract.sol";

import {newMETH, newUnstakeRequestsManager} from "test/utils/Deploy.sol";
import {upgradeToAndCall} from "script/helpers/Proxy.sol";

contract StakingBaseHalmos is SymTest, Test {
    /// @dev From BaseTest
    TimelockController public proxyAdmin;
    address admin;

    /// @dev From StakingTest
    Staking public staking;
    METH public mETH;
    OracleStub public oracle;
    IDepositContract public depositContract;
    PauserStub public pauser;
    UnstakeRequestsManager public unstakeManager;

    address manager;
    address initiator;
    address allocator;
    address withdrawalWallet;
    address requestCanceller;
    address returnsAggregator;

    function setUp() public virtual {
        admin = address(0x10000);
        manager = address(0x20000);
        initiator = address(0x30000);
        allocator = address(0x40000);
        withdrawalWallet = address(0x50000);
        requestCanceller = address(0x60000);
        returnsAggregator = address(0x70000);

        /// @dev From BaseTest
        address[] memory operators = new address[](1);
        operators[0] = address(this);
        proxyAdmin = new TimelockController({minDelay: 0, proposers: operators, executors: operators, admin: admin});

        // `timestamps <= 1` have a special meaning in `TimelockController`, so we have to advance past those.
        vm.warp(2);

        /// @dev From StakingTest
        // Mock deposit contract
        depositContract = new MockDepositContract();
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
}
