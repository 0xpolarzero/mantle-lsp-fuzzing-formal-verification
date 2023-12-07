// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface DepositContract {
    event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index);

    function deposit(
        bytes memory pubkey,
        bytes memory withdrawal_credentials,
        bytes memory signature,
        bytes32 deposit_data_root
    ) external payable;
    function get_deposit_count() external view returns (bytes memory);
    function get_deposit_root() external view returns (bytes32);
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}
