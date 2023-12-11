// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev A very basic implementation of formal verification (symbolic execution) for the Staking contract
/// with Halmos, with an invariants approach.

import {Test, console} from "forge-std/Test.sol";

import {StakingBaseHalmos} from "test/formal-verification/halmos/test/Staking.Base.sol";

// --solver-timeout-assertion 0
contract StakingHalmos is StakingBaseHalmos {
    /// @custom:halmos --loop 8
    function check_extracted_profit(bytes4[] memory _selector) public {
        address caller = svm.createAddress("caller");
        address other = svm.createAddress("other");

        uint256 caller_initialBalanceETH = caller.balance;
        uint256 caller_initialBalanceMETH = mETH.balanceOf(caller);
        uint256 other_initialBalanceETH = other.balance;
        uint256 other_initialBalanceMETH = mETH.balanceOf(other);

        for (uint256 i = 0; i < _selector.length; i++) {
            _validSelector(_selector[i]);
            (uint256 amountGiven) = _successfulCall(_selector[i], caller);
            caller_initialBalanceETH += amountGiven;
        }

        // Nobody should be able to straight up extract ETH from the contract
        assert(caller.balance <= caller_initialBalanceETH);
        // The balances of other parties should not change
        vm.assume(other != caller && other != address(staking));
        assertEq(other.balance, other_initialBalanceETH, "other.balance");
        assertEq(mETH.balanceOf(other), other_initialBalanceMETH, "other.mETHBalance");
    }

    /* -------------------------------------------------------------------------- */
    /*                                   HELPERS                                  */
    /* -------------------------------------------------------------------------- */

    function _validSelector(bytes4 _selector) internal view {
        vm.assume(
            _selector == staking.stake.selector || _selector == staking.unstakeRequest.selector
                || _selector == staking.claimUnstakeRequest.selector || _selector == bytes4(0)
        );
    }

    function _successfulCall(bytes4 _selector, address _caller) internal returns (uint256 msg_value) {
        if (_selector == staking.stake.selector) {
            uint256 minMETHAmount = svm.createUint256("minMETHAmount");
            msg_value = svm.createUint256("msg.value");
            hoax(_caller, msg_value);
            staking.stake{value: msg_value}(minMETHAmount);
        } else if (_selector == staking.unstakeRequest.selector) {
            uint128 mETHAmount = uint128(svm.createUint(128, "mETHAmount"));
            uint128 ETHAmount = uint128(svm.createUint(128, "ETHAmount"));
            staking.unstakeRequest(mETHAmount, ETHAmount);
        } else if (_selector == staking.claimUnstakeRequest.selector) {
            uint256 unstakeRequestId = svm.createUint256("unstakeRequestId");
            staking.claimUnstakeRequest(unstakeRequestId);
        } else {
            // skip this call
        }
    }
}
