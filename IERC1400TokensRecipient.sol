pragma solidity ^0.5.0;

interface IERC1400TokensRecipient {

    function canReceive(bytes32 partition, address from, address to, uint value, bytes calldata data, bytes calldata operatorData ) external view returns(bool);

    function tokensReceived(bytes32 partition, address operator, address from, address to, uint value, bytes calldata data, bytes calldata operatorData ) external;

}