pragma solidity ^0.5.0;

interface IERC1400  {

    function getDocument(bytes32 name) external view returns (string memory, bytes32); 
    
	function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external; 
    
	event Document(bytes32 indexed name, string uri, bytes32 documentHash);

    function isControllable() external view returns (bool); 

    function isIssuable() external view returns (bool); 

    function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data) external; 

    event IssuedByPartition(bytes32 indexed partition, address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);

    function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data) external; 

    function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data, bytes calldata operatorData) external; 

    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

    function canTransferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external view returns (byte, bytes32, bytes32); 

    function canOperatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external view returns (byte, bytes32, bytes32); 

}

/**
 * Code	Reason
 * 0xA0	Transfer Verified - Unrestricted
 * 0xA1	Transfer Verified - On-Chain approval for restricted token
 * 0xA2	Transfer Verified - Off-Chain approval for restricted token
 * 0xA3	Transfer Blocked - Sender lockup period not ended
 * 0xA4	Transfer Blocked - Sender balance insufficient
 * 0xA5	Transfer Blocked - Sender not eligible
 * 0xA6	Transfer Blocked - Receiver not eligible
 * 0xA7	Transfer Blocked - Identity restriction
 * 0xA8	Transfer Blocked - Token restriction
 * 0xA9	Transfer Blocked - Token granularity
 */