/// @dev Verify on original (harness) contract:
/// certoraRun test/formal-verification/certora/confs/Staking_verified.conf

/* -------------------------------------------------------------------------- */
/*                                   METHODS                                  */
/* -------------------------------------------------------------------------- */

using METH as mETH;

methods {
    // Helpers
    function helper_balance(address account) external returns (uint256) envfree;

    // External functions
    function stake(uint256 minMETHAmount) external;
    function unstakeRequest(uint128 methAmount, uint128 minETHAmount) external;
    function claimUnstakeRequest(uint256 unstakeRequestID) external;

    // METH methods
    function mETH.balanceOf(address) external returns (uint256) envfree;
}

/* -------------------------------------------------------------------------- */
/*                                 INVARIANTS                                 */
/* -------------------------------------------------------------------------- */

// Initial ETH balance should never be exceeded

/* -------------------------------------------------------------------------- */
/*                                    RULES                                   */
/* -------------------------------------------------------------------------- */

/// @dev Caller should never end up with more ETH/METH than calculated in the unstake/stake logic.
/// Note: When we strip off any logic and accounting, the cases are basically expected as follows:
/// 1. The caller stakes some ETH, and receives `Staking.ethToMETH(stakedETHAmount)` METH
/// 2. The caller requests to unstake some METH, and receives `Staking.methToETH(unstakedMETHAmount)` ETH
/// Nothing more! Whatever happens, it might revert, but if there is any update in balances it should be as described above.
rule changeInBalance(method f, env e) {
    // Cache balances
    uint256 balanceBeforeETH = helper_balance(e.msg.sender);
    uint256 balanceBeforeMETH = mETH.balanceOf(e.msg.sender);
    // Same with accounting because they might call claimUnstakeRequest
    
    callFunctionWithParams(f, e);

}

/* -------------------------------------------------------------------------- */
/*                                   HELPERS                                  */
/* -------------------------------------------------------------------------- */
/// @dev Call the contract with provided arguments, if it meets an expected function, or with anything if not
function callFunctionWithParams(method f, env e) {
    if (f.selector == sig:stake(uint256).selector) {
        // ...
    } else if (f.selector == sig:unstakeRequest(uint128,uint128).selector) {
        // ...
    } else if (f.selector == sig:claimUnstakeRequest(uint256).selector) {
        // ...
    } else {
        calldataarg args;
        f(e, args);
    }
}