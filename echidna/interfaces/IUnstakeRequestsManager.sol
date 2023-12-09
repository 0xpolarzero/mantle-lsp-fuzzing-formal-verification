// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface UnstakeRequestsManager {
    struct Init {
        address admin;
        address manager;
        address requestCanceller;
        address mETH;
        address stakingContract;
        address oracle;
        uint256 numberOfBlocksToFinalize;
    }

    struct UnstakeRequest {
        uint64 blockNumber;
        address requester;
        uint128 id;
        uint128 mETHLocked;
        uint128 ethRequested;
        uint128 cumulativeETHRequested;
    }

    error AlreadyClaimed();
    error DoesNotReceiveETH();
    error NotEnoughFunds(uint256 cumulativeETHOnRequest, uint256 allocatedETHForClaims);
    error NotFinalized();
    error NotRequester();
    error NotStakingContract();

    event Initialized(uint8 version);
    event ProtocolConfigChanged(bytes4 indexed setterSelector, string setterSignature, bytes value);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event UnstakeRequestCancelled(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );
    event UnstakeRequestClaimed(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );
    event UnstakeRequestCreated(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );

    fallback() external payable;

    receive() external payable;

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function MANAGER_ROLE() external view returns (bytes32);
    function REQUEST_CANCELLER_ROLE() external view returns (bytes32);
    function allocateETH() external payable;
    function allocatedETHDeficit() external view returns (uint256);
    function allocatedETHForClaims() external view returns (uint256);
    function allocatedETHSurplus() external view returns (uint256);
    function balance() external view returns (uint256);
    function cancelUnfinalizedRequests(uint256 maxCancel) external returns (bool);
    function claim(uint256 requestID, address requester) external;
    function create(address requester, uint128 mETHLocked, uint128 ethRequested) external returns (uint256);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function initialize(Init memory init) external;
    function latestCumulativeETHRequested() external view returns (uint128);
    function mETH() external view returns (address);
    function nextRequestId() external view returns (uint256);
    function numberOfBlocksToFinalize() external view returns (uint256);
    function oracle() external view returns (address);
    function renounceRole(bytes32 role, address account) external;
    function requestByID(uint256 requestID) external view returns (UnstakeRequest memory);
    function requestInfo(uint256 requestID) external view returns (bool, uint256);
    function revokeRole(bytes32 role, address account) external;
    function setNumberOfBlocksToFinalize(uint256 numberOfBlocksToFinalize_) external;
    function stakingContract() external view returns (address);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function totalClaimed() external view returns (uint256);
    function withdrawAllocatedETHSurplus() external;
}
