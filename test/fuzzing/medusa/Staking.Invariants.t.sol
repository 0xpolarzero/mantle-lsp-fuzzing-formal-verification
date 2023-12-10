// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev The following will do virtually the same as Echidna invariant tests, that's why
/// it inherits from its handlers. Except that we try to run it with no guidance.

/// @dev Run with:
/// medusa --config test/fuzzing/medusa/config.json fuzz

import {StakingBaseMedusa} from "test/fuzzing/medusa/Staking.Base.sol";

import {StakingHandler} from "test/fuzzing/echidna/src/handlers/Staking.Handler.sol";
import {ValidatorHandler} from "test/fuzzing/echidna/src/handlers/Validator.Handler.sol";

contract StakingInvariantsMedusa is StakingBaseMedusa, StakingHandler, ValidatorHandler {
    /// @dev Keep track of balances
    uint256 initialMETHBalance;
    // The ETH that we own (sent from the fuzzer in the constructor & fallback)
    uint256 initialETHBalance;
    // The ETH that we stake and receive back from the staking contract
    // It might be negative, if the contract actually sends us more than initially staked
    // which might, depending on the scale, indicate an issue
    int256 ethStaked;

    constructor()
        StakingHandler(address(staking), address(mETH), address(unstakeManager))
        ValidatorHandler(address(staking), address(depositContract))
    {
        // Initialize balances
        initialETHBalance = address(this).balance;
        initialMETHBalance = mETH.balanceOf(address(this));

        require(initialETHBalance > 0, "StakingInvariants: contract needs to have an initial balance of ETH");
        require(initialMETHBalance == 0, "StakingInvariants: contract needs to have an initial balance of 0 mETH");
    }

    /* -------------------------------------------------------------------------- */
    /*                                  OVERRIDES                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev
    function stake(uint256 _amount) public payable override {
        super.stake(_amount);
        ethStaked += int256(msg.value);
    }

    /// @dev
    function unstakeRequest(uint128 _mETHAmount, uint128 ETHAmount) public {
        staking.unstakeRequest(_mETHAmount, ETHAmount);
    }

    function unstakeRequest(uint256 _seed) public override {}

    /// @dev
    function claimUnstakeRequest(uint256 _unstakeRequestId) public override {
        staking.claimUnstakeRequest(_unstakeRequestId);
    }

    fallback() external payable {
        _onReceiveETH();
    }

    receive() external payable {
        _onReceiveETH();
    }

    /* -------------------------------------------------------------------------- */
    /*                                 INVARIANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Invariant: try to get the most optimized profit from a transactions sequence
    /// Note: We basically substract the initial ETH and mETH balances from the current ones,
    /// as well as the staked ETH.
    function optimize_extracted_profit() public view returns (int256 profit) {
        // Get current balances
        int256 balanceETH = int256(address(this).balance);
        uint256 balanceMETH = mETH.balanceOf(address(this));

        // Calculate the equivalent of mETH in ETH, to be able to calculate with the same base
        int256 balanceMETHConverted = int256(staking.mETHToETH(balanceMETH));
        int256 initialMETHBalanceConverted = int256(staking.mETHToETH(initialMETHBalance));

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
        // If Medusa is calling this function with ETH, it's our own
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
