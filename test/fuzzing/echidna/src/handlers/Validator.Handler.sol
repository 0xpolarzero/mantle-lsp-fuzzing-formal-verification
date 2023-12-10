// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev This handler simulates the validators allocation/creation logic.
/// @dev Basically, whenever it's called, and there is at least 32 ETH in the `Staking` contract,
/// it will allocate these ETH, and initiate a validator/validators.
/// @dev This is a two step process:
/// 1. `Staking.allocateETH` will allocate the ETH to `allocatedETHForDeposits`, used for initiating new validators.
/// 2. `Staking.initiateValidatorsWithDeposits` will initiate the validators, using the `allocatedETHForDeposits` ETH,
/// by sending these to the beacon chain deposit contract.

// Utils
import {hevm} from "test/fuzzing/utils/HEVM.sol";

// Interfaces
import {Staking} from "test/fuzzing/echidna/interfaces/IStaking.sol";
import {DepositContract} from "test/fuzzing/echidna/interfaces/IDepositContract.sol";

/// @dev Utility struct for the `_validatorParams` function
struct Signature {
    bytes32 left;
    bytes32 right;
}

contract ValidatorHandler {
    DepositContract _depositContract;
    Staking _staking;

    /// @dev The amount deposited when initiating validators
    uint256 constant DEPOSIT_AMOUNT = 32 ether;
    /// @dev The prefix for the withdrawal credentials
    bytes1 constant ETH1_ADDRESS_WITHDRAWAL_PREFIX = 0x01;
    /// @dev The withdrawal wallet
    address _withdrawalWallet;

    /// @dev The addresses the are trusted with special roles for allocating and initiating validators
    address _allocatorService;
    address _initiatorService;

    /// @dev The ETH were allocated, so it's ready to be used for initiating validators
    bool allocatedETHForDeposits;

    /// @dev Initialize the contracts used in the handler, at the given addresses on mainnet
    constructor(address _stakingAddress, address _depositContractAddress) {
        _staking = Staking(payable(_stakingAddress));
        _depositContract = DepositContract(_depositContractAddress);

        // Initialize roles
        _allocatorService = _staking.getRoleMember(_staking.ALLOCATOR_SERVICE_ROLE(), 0);
        _initiatorService = _staking.getRoleMember(_staking.INITIATOR_SERVICE_ROLE(), 0);
        // and withdrawal wallet
        _withdrawalWallet = _staking.withdrawalWallet();
    }

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    modifier enoughETHToInitiateValidators() {
        require(address(_staking).balance >= 32 ether, "ValidatorHandler: not enough ETH to initiate validators");
        _;
    }

    /**
     * @dev Allocate ETH to `allocatedETHForDeposits` used for initiating new validators.
     * Note: This will spoof the `AllocatorService` role, and call `Staking.allocateETH`.
     */
    function allocateETH() public virtual enoughETHToInitiateValidators {
        // Calculate the amount that can be allocated (in 32 ETH chunks)
        uint256 amount = address(_staking).balance - (address(_staking).balance % DEPOSIT_AMOUNT);

        hevm.prank(_allocatorService);
        _staking.allocateETH(0, amount);

        allocatedETHForDeposits = true;
    }

    modifier allocatedETH() {
        require(allocatedETHForDeposits, "ValidatorHandler: ETH hasn't been allocated yet");
        _;
    }

    /**
     * @dev Initiate the validators, using the `allocatedETHForDeposits` ETH,
     * by sending these to the beacon chain deposit contract.
     * Note: This will spoof the `InitiatorService` role, and call `Staking.initiateValidatorsWithDeposits`.
     */
    function initiateValidatorsWithDeposits(uint256 _seed) public virtual allocatedETH {
        uint256 amount = _staking.allocatedETHForDeposits();
        uint256 count = amount / DEPOSIT_AMOUNT;

        Staking.ValidatorParams[] memory validators = new Staking.ValidatorParams[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 uniqueSeed = uint256(keccak256(abi.encode(_seed, i)));
            validators[i] = _validatorParams(uniqueSeed, DEPOSIT_AMOUNT);
        }

        hevm.prank(_initiatorService);
        _staking.initiateValidatorsWithDeposits(validators, _depositContract.get_deposit_root());

        allocatedETHForDeposits = false;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   HELPERS                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Generate parameters for a mock validator (we don't care about the credentials).
    /// Note: See how these values are verified in the Eth 2.0 beacon chain deposit contract:
    /// https://etherscan.io/address/0x00000000219ab540356cBB839Cbe05303d7705Fa#code
    function _validatorParams(uint256 _seed, uint256 _depositAmount)
        internal
        view
        returns (Staking.ValidatorParams memory params)
    {
        // We need:
        // - a unique (not yet used) pubKey
        bytes memory pubKey = _generatePubKey(_seed);
        // - valid withdrawal credentials (`Staking._requireProtocolWithdrawalAccount(withdrawalCredentials)`)
        bytes memory withdrawalCredentials = _retrieveWithdrawalCredentials();
        // - a signature
        bytes memory signature = _generateSignature(_seed);
        // - the deposit data root
        bytes32 depositDataRoot = _depositDataRoot(pubKey, withdrawalCredentials, signature, _depositAmount);

        params = Staking.ValidatorParams(0, _depositAmount, pubKey, withdrawalCredentials, signature, depositDataRoot);
    }

    /// @dev Generate a unique pubKey (48 bytes)
    function _generatePubKey(uint256 _seed) internal view returns (bytes memory pubKey) {
        pubKey = abi.encodePacked(abi.encode(_seed, block.number), bytes16(0));
    }

    /// @dev Retrieve the withdrawal credentials (32 bytes)
    /// @dev The withdrawal_credentials field must be such that:
    /// - withdrawal_credentials[:1] == ETH1_ADDRESS_WITHDRAWAL_PREFIX (0x01)
    /// - withdrawal_credentials[1:12] == b'\x00' * 11
    /// - withdrawal_credentials[12:] == eth1_withdrawal_address
    function _retrieveWithdrawalCredentials() internal view returns (bytes memory withdrawalCredentials) {
        withdrawalCredentials = abi.encodePacked(ETH1_ADDRESS_WITHDRAWAL_PREFIX, bytes11(0), _withdrawalWallet);
    }

    /// @dev Generate a signature (96 bytes)
    function _generateSignature(uint256 _seed) internal view returns (bytes memory signature) {
        signature = abi.encodePacked(abi.encode(_seed, block.number), abi.encode(_seed, block.number), bytes32(0));
    }

    /// @dev Retrieve the deposit data root (32 bytes)
    /// Note: This can be done, given the pubKey, withdrawal credentials, signature and amount deposited
    function _depositDataRoot(
        bytes memory _pubKey,
        bytes memory _withdrawalCredentials,
        bytes memory _signature,
        uint256 _depositAmount
    ) internal pure returns (bytes32 depositDataRoot) {
        // Copied and adapted from `DepositContract.deposit`
        bytes32 pubkey_root = sha256(abi.encodePacked(_pubKey, bytes16(0)));

        // Slice the signature
        Signature memory signature;
        assembly {
            // Store the first 32 bytes of the signature into `signature.left`
            mstore(signature, mload(add(_signature, 32)))
            // Store the next 32 bytes of the signature into `signature.right`
            mstore(add(signature, 32), mload(add(_signature, 64)))
        }

        bytes32 signature_root = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(signature.left)), sha256(abi.encodePacked(signature.right, bytes32(0)))
            )
        );

        depositDataRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkey_root, _withdrawalCredentials)),
                sha256(abi.encodePacked(_depositAmount, bytes24(0), signature_root))
            )
        );
    }
}
