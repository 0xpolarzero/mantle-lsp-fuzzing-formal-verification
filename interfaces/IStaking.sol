// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface Staking {
    struct Init {
        address admin;
        address manager;
        address allocatorService;
        address initiatorService;
        address returnsAggregator;
        address withdrawalWallet;
        address mETH;
        address depositContract;
        address oracle;
        address pauser;
        address unstakeRequestsManager;
    }

    struct ValidatorParams {
        uint256 operatorID;
        uint256 depositAmount;
        bytes pubkey;
        bytes withdrawalCredentials;
        bytes signature;
        bytes32 depositDataRoot;
    }

    error DoesNotReceiveETH();
    error InvalidConfiguration();
    error InvalidDepositRoot(bytes32);
    error InvalidWithdrawalCredentialsNotETH1(bytes12);
    error InvalidWithdrawalCredentialsWrongAddress(address);
    error InvalidWithdrawalCredentialsWrongLength(uint256);
    error MaximumMETHSupplyExceeded();
    error MaximumValidatorDepositExceeded();
    error MinimumStakeBoundNotSatisfied();
    error MinimumUnstakeBoundNotSatisfied();
    error MinimumValidatorDepositNotSatisfied();
    error NotEnoughDepositETH();
    error NotEnoughUnallocatedETH();
    error NotReturnsAggregator();
    error NotUnstakeRequestsManager();
    error Paused();
    error PreviouslyUsedValidator();
    error StakeBelowMinimumMETHAmount(uint256 methAmount, uint256 expectedMinimum);
    error UnstakeBelowMinimumETHAmount(uint256 ethAmount, uint256 expectedMinimum);
    error ZeroAddress();

    event AllocatedETHToDeposits(uint256 amount);
    event AllocatedETHToUnstakeRequestsManager(uint256 amount);
    event Initialized(uint8 version);
    event ProtocolConfigChanged(bytes4 indexed setterSelector, string setterSignature, bytes value);
    event ReturnsReceived(uint256 amount);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Staked(address indexed staker, uint256 ethAmount, uint256 mETHAmount);
    event UnstakeRequestClaimed(uint256 indexed id, address indexed staker);
    event UnstakeRequested(uint256 indexed id, address indexed staker, uint256 ethAmount, uint256 mETHLocked);
    event ValidatorInitiated(bytes32 indexed id, uint256 indexed operatorID, bytes pubkey, uint256 amountDeposited);

    fallback() external payable;

    receive() external payable;

    function ALLOCATOR_SERVICE_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function INITIATOR_SERVICE_ROLE() external view returns (bytes32);
    function STAKING_ALLOWLIST_MANAGER_ROLE() external view returns (bytes32);
    function STAKING_ALLOWLIST_ROLE() external view returns (bytes32);
    function STAKING_MANAGER_ROLE() external view returns (bytes32);
    function TOP_UP_ROLE() external view returns (bytes32);
    function allocateETH(uint256 allocateToUnstakeRequestsManager, uint256 allocateToDeposits) external;
    function allocatedETHForDeposits() external view returns (uint256);
    function claimUnstakeRequest(uint256 unstakeRequestID) external;
    function depositContract() external view returns (address);
    function ethToMETH(uint256 ethAmount) external view returns (uint256);
    function exchangeAdjustmentRate() external view returns (uint16);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function initializationBlockNumber() external view returns (uint256);
    function initialize(Init memory init) external;
    function initiateValidatorsWithDeposits(ValidatorParams[] memory validators, bytes32 expectedDepositRoot)
        external;
    function isStakingAllowlist() external view returns (bool);
    function mETH() external view returns (address);
    function mETHToETH(uint256 mETHAmount) external view returns (uint256);
    function maximumDepositAmount() external view returns (uint256);
    function maximumMETHSupply() external view returns (uint256);
    function minimumDepositAmount() external view returns (uint256);
    function minimumStakeBound() external view returns (uint256);
    function minimumUnstakeBound() external view returns (uint256);
    function numInitiatedValidators() external view returns (uint256);
    function oracle() external view returns (address);
    function pauser() external view returns (address);
    function receiveFromUnstakeRequestsManager() external payable;
    function receiveReturns() external payable;
    function reclaimAllocatedETHSurplus() external;
    function renounceRole(bytes32 role, address account) external;
    function returnsAggregator() external view returns (address);
    function revokeRole(bytes32 role, address account) external;
    function setExchangeAdjustmentRate(uint16 exchangeAdjustmentRate_) external;
    function setMaximumDepositAmount(uint256 maximumDepositAmount_) external;
    function setMaximumMETHSupply(uint256 maximumMETHSupply_) external;
    function setMinimumDepositAmount(uint256 minimumDepositAmount_) external;
    function setMinimumStakeBound(uint256 minimumStakeBound_) external;
    function setMinimumUnstakeBound(uint256 minimumUnstakeBound_) external;
    function setStakingAllowlist(bool isStakingAllowlist_) external;
    function setWithdrawalWallet(address withdrawalWallet_) external;
    function stake(uint256 minMETHAmount) external payable;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function topUp() external payable;
    function totalControlled() external view returns (uint256);
    function totalDepositedInValidators() external view returns (uint256);
    function unallocatedETH() external view returns (uint256);
    function unstakeRequest(uint128 methAmount, uint128 minETHAmount) external returns (uint256);
    function unstakeRequestInfo(uint256 unstakeRequestID) external view returns (bool, uint256);
    function unstakeRequestWithPermit(
        uint128 methAmount,
        uint128 minETHAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);
    function unstakeRequestsManager() external view returns (address);
    function usedValidators(bytes memory pubkey) external view returns (bool exists);
    function withdrawalWallet() external view returns (address);
}
