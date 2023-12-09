// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Run the fuzzing campaign:
/// echidna test/Invariants.sol --contract Invariants --config echidna-config.yaml

/// @dev This contract inherits from the handler contracts, trusted to make calls to the target contracts.
/// Here, we basically:
/// - set up the configuration for the test suite;
/// - keep track of balances (for both native ETH and mETH);
/// - (try to) verify the invariants.

// Utils
import {hevm} from "echidna/utils/HEVM.sol";

// Interfaces
import {Staking} from "echidna/interfaces/IStaking.sol";
import {METH} from "echidna/interfaces/ImETH.sol";
import {DepositContract} from "echidna/interfaces/IDepositContract.sol";

// Handlers
import {StakingHandler} from "echidna/test/handlers/Staking.Handler.sol";
import {ValidatorHandler} from "echidna/test/handlers/Validator.Handler.sol";

contract Invariants is StakingHandler, ValidatorHandler {
    // Addresses of the proxies
    address constant STAKING_PROXY = payable(0xe3cBd06D7dadB3F4e6557bAb7EdD924CD1489E8f);
    address constant METH_PROXY = 0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa;
    address constant UNSTAKE_REQUESTS_MANAGER_PROXY = 0x38fDF7b489316e03eD8754ad339cb5c4483FDcf9;
    // Address of the Eth2.0 deposit contract
    address constant DEPOSIT_CONTRACT = 0x00000000219ab540356cBB839Cbe05303d7705Fa;

    /// @dev Keep track of balances
    uint256 initialMETHBalance;
    // The ETH that we own (sent from the fuzzer in the constructor & fallback)
    uint256 initialETHBalance;
    // The ETH that we stake and receive back from the staking contract
    // It might be negative, if the contract actually sends us more than initially staked
    // which might, depending on the scale, indicate an issue
    int256 ethStaked;

    constructor()
        payable
        StakingHandler(STAKING_PROXY, METH_PROXY, UNSTAKE_REQUESTS_MANAGER_PROXY)
        ValidatorHandler(STAKING_PROXY, DEPOSIT_CONTRACT)
    {
        // Fork the desired block, and use it as a starting point
        hevm.roll(18714518);

        // Initialize balances
        initialETHBalance = address(this).balance;
        initialMETHBalance = METH(METH_PROXY).balanceOf(address(this));

        require(initialETHBalance > 0, "StakingInvariants: contract needs to have an initial balance of ETH");
        require(initialMETHBalance == 0, "StakingInvariants: contract needs to have an initial balance of 0 mETH");
    }

    /* -------------------------------------------------------------------------- */
    /*                                  OVERRIDES                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Call `stake` in the handler, and keep track of the ETH staked
    function stake(uint256 _amount) public payable override {
        super.stake(_amount);
        ethStaked += int256(msg.value);
    }

    fallback() external payable {
        _onReceiveETH();
    }

    receive() external payable {
        _onReceiveETH();
    }

    /// @dev Invariant: try to get the most optimized profit from a transactions sequence
    /// Note: We basically substract the initial ETH and mETH balances from the current ones,
    /// as well as the staked ETH.
    function echidna_optimize_extracted_profit() public view returns (int256 profit) {
        // Get current balances
        int256 balanceETH = int256(address(this).balance);
        uint256 balanceMETH = METH(METH_PROXY).balanceOf(address(this));

        // Calculate the equivalent of mETH in ETH, to be able to calculate with the same base
        int256 balanceMETHConverted = int256(Staking(payable(STAKING_PROXY)).mETHToETH(balanceMETH));
        int256 initialMETHBalanceConverted = int256(Staking(payable(STAKING_PROXY)).mETHToETH(initialMETHBalance));

        // Substract the initial (or given from the fuzzer) balances and the staked ETH from the current balances
        // The staked ETH might be negative, if we received back more than initially staked
        // which will in this case increase the profit as expected
        profit =
            balanceETH + balanceMETHConverted - (int256(initialETHBalance) + initialMETHBalanceConverted) - ethStaked;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   HELPERS                                  */
    /* -------------------------------------------------------------------------- */

    function _onReceiveETH() internal {
        // If echidna is calling this function with ETH, it's our own
        if (_isSenderFuzzer()) {
            initialETHBalance += msg.value;
        } else {
            // Otherwise, we're either receiving ETH back from staking, or from anything else (which is unexpected)
            ethStaked -= int256(msg.value);
        }
    }

    function _isSenderFuzzer() internal view returns (bool) {
        return msg.sender == address(0x10000) || msg.sender == address(0x20000) || msg.sender == address(0x30000);
    }
}
