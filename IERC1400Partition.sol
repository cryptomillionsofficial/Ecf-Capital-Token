pragma solidity ^0.5.0;


interface IERC1400Partition {

    function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256); 

    function partitionsOf(address tokenHolder) external view returns (bytes32[] memory); 

    function transferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external returns (bytes32); 

    function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external returns (bytes32); 

    function getDefaultPartitions() external view returns (bytes32[] memory); 

    function setDefaultPartitions(bytes32[] calldata partitions) external; 

    function controllersByPartition(bytes32 partition) external view returns (address[] memory); 

    function authorizeOperatorByPartition(bytes32 partition, address operator) external; 

    function revokeOperatorByPartition(bytes32 partition, address operator) external; 

    function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool); 

    event TransferByPartition(bytes32 indexed fromPartition, address operator, address indexed from, address indexed to, uint256 value, bytes data, bytes operatorData);

    event ChangedPartition(bytes32 indexed fromPartition, bytes32 indexed toPartition, uint256 value);

    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

}