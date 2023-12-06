// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// echidna src/Invariants.sol --contract Invariants --config echidna-config.yaml

// Utils
import {hevm} from "utils/HEVM.sol";

// Interfaces
import {Staking} from "interfaces/IStaking.sol";
import {METH} from "interfaces/ImETH.sol";

// Handlers
import {StakingHandler} from "src/handlers/Staking.Handler.sol";

contract Invariants is StakingHandler {
    // Addresses of the proxies
    address constant STAKING_PROXY = payable(0xe3cBd06D7dadB3F4e6557bAb7EdD924CD1489E8f);
    address constant METH_PROXY = 0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa;
    address constant UNSTAKE_REQUESTS_MANAGER_PROXY = 0x38fDF7b489316e03eD8754ad339cb5c4483FDcf9;

    // Keep track of balances
    uint256 initialMETHBalance;
    // The ETH that we own (sent from the fuzzer in the constructor & fallback)
    uint256 initialETHBalance;
    // The ETH that we stake and receive back from the staking contract
    // It might be negative, if the contract actually sends us more than initially staked
    // which might, depending on the scale, indicate an issue
    int256 ethStaked;

    constructor() payable StakingHandler(STAKING_PROXY, METH_PROXY, UNSTAKE_REQUESTS_MANAGER_PROXY) {
        // Navigate to the desired fork block
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

    function stake(uint256 _amount) public payable override {
        super.stake(_amount);
        ethStaked += int256(msg.value);
    }

    fallback() external payable {
        _onReceiveETH(msg.value);
    }

    receive() external payable {
        _onReceiveETH(msg.value);
    }

    function echidna_optimize_extracted_profit() public view returns (int256 profit) {
        // Get balances
        int256 balanceETH = int256(address(this).balance);
        uint256 balanceMETH = METH(METH_PROXY).balanceOf(address(this));

        // Calculate the equivalent of mETH in ETH
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

    function _onReceiveETH(uint256 _amount) internal {
        // If echidna is calling this function with ETH, it's our own
        if (_isSenderFuzzer()) {
            initialETHBalance += msg.value;
        } else {
            // Otherwise, we're either receiving ETH back from staking, or from an issue
            ethStaked -= int256(msg.value);
        }
    }

    function _isSenderFuzzer() internal view returns (bool) {
        return msg.sender == address(0x10000) || msg.sender == address(0x20000) || msg.sender == address(0x30000);
    }
}
