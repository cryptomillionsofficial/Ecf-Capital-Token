pragma solidity 0.5.0;

interface ERC1820ImplementerInterface {
    
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr) external view returns(bytes32);
	
}