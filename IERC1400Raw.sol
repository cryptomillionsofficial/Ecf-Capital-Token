pragma solidity ^0.5.0;

interface IERC1400Raw {

    function name() external view returns (string memory); 

    function symbol() external view returns (string memory); 

    function totalSupply() external view returns (uint256); 

    function balanceOf(address owner) external view returns (uint256); 

    function granularity() external view returns (uint256); 

    function controllers() external view returns (address[] memory); 

    function authorizeOperator(address operator) external; 

    function revokeOperator(address operator) external; 

    function isOperator(address operator, address tokenHolder) external view returns (bool);

    function transferWithData(address to, uint256 value, bytes calldata data) external; 

    function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; 

    function redeem(uint256 value, bytes calldata data) external; 

    function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; 

    event TransferWithData(address indexed operator, address indexed from, address indexed to, uint256 value, bytes data, bytes operatorData);

    event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);

    event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);

}