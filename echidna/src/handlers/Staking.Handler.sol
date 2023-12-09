// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev This handler makes call to the `Staking` contract, with random yet tailored values,
/// in an attempt to tire out the contract, and get it to behave in an unexpected way.

/// @dev Here we basically only use external functions that are not notably restricted.
/// @dev We could call these restricted functions as well if we wanted to test the correctness of
/// the roles management, but it's not the purpose here.

// Interfaces
import {Staking} from "echidna/interfaces/IStaking.sol";
import {METH} from "echidna/interfaces/ImETH.sol";
import {UnstakeRequestsManager} from "echidna/interfaces/IUnstakeRequestsManager.sol";

contract StakingHandler {
    Staking staking;
    METH mETH;
    UnstakeRequestsManager unstakeRequestsManager;

    /// @dev The unfulfilled unstake requests (basically `Staking.unstakeRequest` but not yet `Staking.claimUnstakeRequest`)
    uint256[] unstakeRequestsIds;

    /// @dev Initialize the contracts used in the handler, at the given addresses on mainnet
    constructor(address _staking, address _mETH, address _unstakeRequestsManager) {
        staking = Staking(payable(_staking));
        mETH = METH(_mETH);
        unstakeRequestsManager = UnstakeRequestsManager(payable(_unstakeRequestsManager));
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Stake ETH in the `Staking` contract, and receive mETH in return
     * Note: We need to give a minMETHAmount that is appropriate relative to the amount of ETH we send.
     * However, we don't want to fit too much to the expected scenario.
     * So we just either send random values, or loosely crafted values.
     */
    function stake(uint256 _amount) public payable virtual {
        bool random = _randomize(_amount);
        uint256 minMETHAmount = staking.ethToMETH(msg.value);

        staking.stake{value: msg.value}(random ? _amount : minMETHAmount);
    }

    /**
     * @dev Make a request to unstake mETH from the `Staking` contract, which is usually followed by the
     * actual claim of the unstake request
     * Note: This will call `UnstakeRequestsManager.create`; which will try to transfer the mETHAmount
     * from `msg.sender` to the `UnstakeRequestsManager` contract.
     * Later, we want to call `Staking.claimUnstakeRequest`, which will call `UnstakeRequestsManager.claim`...
     * -> which will fail if (request.cumulativeETHRequested > allocatedETHForClaims).
     * -- (request.cumulativeETHRequested = latestCumulativeETHRequested + ethRequested)
     * -- (ethRequested = _minETHAmount)
     */
    function unstakeRequest(uint256 _seed) public virtual {
        // Calculate the amount of mETH we can unstake (will be burned in `claimUnstakeRequest`)
        uint128 mETHAmount = uint128(_clampBetween(_seed, 0, mETH.balanceOf(msg.sender)));

        // Calculate the appropriate amount of ETH to request
        uint256 maximumETHAmount =
            unstakeRequestsManager.allocatedETHForClaims() - unstakeRequestsManager.latestCumulativeETHRequested();
        uint128 ETHAmount = uint128(staking.mETHToETH(mETHAmount));

        if (ETHAmount > maximumETHAmount) ETHAmount = uint128(maximumETHAmount);

        uint256 requestId = staking.unstakeRequest(mETHAmount, ETHAmount);

        // Keep track of the unstake request in a mirror
        unstakeRequestsIds.push(requestId);
    }

    /**
     * @dev Claim an unstake request, which will burn the mETH and send the ETH back to the requester
     * Note: This will call `UnstakeRequestsManager.claim`.
     * We actually need to own the requested id, otherwise it will fail, which means, we need to be the `request.requester`.
     * This is not the case if it is owned by someone else, or if it's been claimed already (deleted).
     */
    function claimUnstakeRequest(uint256 _seed) public virtual {
        if (unstakeRequestsIds.length == 0) return;
        uint256 id = unstakeRequestsIds[_seed % unstakeRequestsIds.length];

        staking.claimUnstakeRequest(id);

        // Delete the request from the mirror
        _deleteUnstakeRequest(_seed % unstakeRequestsIds.length);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   HELPERS                                  */
    /* -------------------------------------------------------------------------- */

    function _randomize(uint256 _seed) internal pure returns (bool random) {
        random = _seed % 10 == 0; // 10% chance of returning true
    }

    function _deleteUnstakeRequest(uint256 _index) internal {
        unstakeRequestsIds[_index] = unstakeRequestsIds[unstakeRequestsIds.length - 1];
        unstakeRequestsIds.pop();
    }

    // Adapted from crytic/properties/util/PropertiesHelper.sol:PropertiesAsserts
    function _clampBetween(uint256 value, uint256 low, uint256 high) internal pure returns (uint256) {
        if (value < low || value > high) {
            uint256 ans = low + (value % (high - low + 1));
            return ans;
        }
        return value;
    }
}
