// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev A very basic implementation of formal verification (symbolic execution) for the Staking contract
/// with Halmos, with an invariants approach.

/// @dev The direction we take here, is to call the tested function with any parameters,
/// then assert that the initial conditions for success were actually met.
/// It helps not to make too much assumptions that could otherwise discard an actual bug occuring from
/// passing an unexpected value.

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

import {StakingTest} from "test/Staking.t.sol";

contract StakingHalmos is Test, SymTest, StakingTest {
    /// @dev Test the `stake` function.
    /// Note: Inputs can actually be passed as arguments, the same way as with fuzzing tests.
    /// I just find it more explicit to declare them inside the body of the function, when there are not too many.
    function check_stake() public {
        address caller = svm.createAddress("caller");
        uint256 minMETHAmount = svm.createUint256("minMETHAmount");
        uint256 msg_value = svm.createUint256("msg.value");

        hoax(caller, msg_value);
        (bool success,) =
            address(staking).call{value: msg_value}(abi.encodeWithSelector(staking.stake.selector, minMETHAmount));
    }
    /* -------------------------------------------------------------------------- */
    /*                                   HELPERS                                  */
    /* -------------------------------------------------------------------------- */

    function _assertImplies(bool _a, bool _b) internal pure {
        assert(!_a || _b);
    }
}
