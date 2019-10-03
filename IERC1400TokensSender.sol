pragma solidity ^0.5.0;


interface IERC1400TokensSender {

    function canTransfer(bytes32 partition, address from, address to, uint value, bytes calldata data, bytes calldata operatorData) external view returns(bool);

    function tokensToTransfer(bytes32 partition, address operator, address from, address to, uint value, bytes calldata data, bytes calldata operatorData) external;

}
