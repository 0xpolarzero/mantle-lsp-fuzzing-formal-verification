// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev A very basic implementation of formal verification (symbolic execution) for the Staking contract
/// with Halmos, with an invariants approach.
/// @dev We basically make a few (here 32, see loop below) symbolic calls to accessible functions, and verify that
/// balances for the caller and all other users are updated correctly; or more precisely, that the caller has no way
/// to extract anymore ETH and mETH than they are supposed to.

/// @dev Run with:
/// halmos

import {Test, console} from "forge-std/Test.sol";

import {StakingBaseHalmos} from "test/formal-verification/halmos/test/Staking.Base.sol";

contract StakingHalmos is StakingBaseHalmos {
    /**
     * @dev Call the `Staking` multiple times with symbolic values, and verify that the balances are correct.
     * Note: The loop value can be increased/decreased to perform more or less calls to the contract.
     */
    /// @custom:halmos --loop 32
    function check_extracted_profit(bytes4[] memory _selector) public {
        // Generate symbolic addresses
        address caller = svm.createAddress("caller");
        address other = svm.createAddress("other");

        // Record initial balances
        uint256 caller_initialBalanceETH = caller.balance;
        uint256 caller_initialBalanceMETH = mETH.balanceOf(caller);
        uint256 other_initialBalanceETH = other.balance;
        uint256 other_initialBalanceMETH = mETH.balanceOf(other);

        // Make {selector.length} calls to the contract with valid selectors
        for (uint256 i = 0; i < _selector.length; i++) {
            _validSelector(_selector[i]);
            // Remember the amount of ETH given to the caller to perform their deposits
            (uint256 amountGiven) = _successfulCall(_selector[i], caller);
            caller_initialBalanceETH += amountGiven;
        }

        // Verify balances
        assumeBalanceCallerCorrect(caller, caller_initialBalanceETH, caller_initialBalanceMETH);
        vm.assume(other != caller && other != address(staking));
        assumeBalanceOtherCorrect(other, other_initialBalanceETH, other_initialBalanceMETH);
    }

    /// @dev Verify that the caller could not extract more ETH and mETH than expected.
    function assumeBalanceCallerCorrect(address account, uint256 initialBalanceETH, uint256 initialBalanceMETH)
        internal
        view
    {
        uint256 currentBalanceETH = account.balance;
        uint256 currentBalanceMETH = mETH.balanceOf(account);
        // Convert to a common unit
        uint256 currentBalanceMETHConverted = staking.mETHToETH(currentBalanceMETH);
        uint256 initialBalanceMETHConverted = staking.mETHToETH(initialBalanceMETH);

        // They should not have more than they started with
        assert(currentBalanceETH + currentBalanceMETHConverted <= initialBalanceETH + initialBalanceMETHConverted);
    }

    /// @dev Verify that the balances of all other users are unchanged.
    function assumeBalanceOtherCorrect(address account, uint256 initialBalanceETH, uint256 initialBalanceMETH)
        internal
    {
        assertEq(account.balance, initialBalanceETH, "other.balance");
        assertEq(mETH.balanceOf(account), initialBalanceMETH, "other.mETHBalance");
    }

    /* -------------------------------------------------------------------------- */
    /*                                   HELPERS                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Discard any call using a selector that is not supported/not accessible.
    function _validSelector(bytes4 _selector) internal view {
        vm.assume(
            _selector == staking.stake.selector || _selector == staking.unstakeRequest.selector
                || _selector == staking.claimUnstakeRequest.selector || _selector == bytes4(0)
        );
    }

    /// @dev Generate appropriate calldata for a given selector, and call the contract.
    function _successfulCall(bytes4 _selector, address _caller) internal returns (uint256 msg_value) {
        if (_selector == staking.stake.selector) {
            // `stake(uint256)
            uint256 minMETHAmount = svm.createUint256("minMETHAmount");
            msg_value = svm.createUint256("msg.value");
            hoax(_caller, msg_value);
            staking.stake{value: msg_value}(minMETHAmount);
        } else if (_selector == staking.unstakeRequest.selector) {
            // `unstakeRequest(uint128, uint128)`
            uint128 mETHAmount = uint128(svm.createUint(128, "mETHAmount"));
            uint128 ETHAmount = uint128(svm.createUint(128, "ETHAmount"));
            staking.unstakeRequest(mETHAmount, ETHAmount);
        } else if (_selector == staking.claimUnstakeRequest.selector) {
            // `claimUnstakeRequest(uint256)`
            uint256 unstakeRequestId = svm.createUint256("unstakeRequestId");
            staking.claimUnstakeRequest(unstakeRequestId);
        } else {
            // skip this call
        }
    }
}
