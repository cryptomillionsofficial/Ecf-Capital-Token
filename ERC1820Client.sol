pragma solidity 0.5.0;

import "./ERC1820Registry.sol";


contract ERC1820Client {

    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(ERC1820Registry REGISTERED CONTRACT ADDRESS);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {

        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));

        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {

        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));

        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {

        ERC1820REGISTRY.setManager(address(this), _newManager);

    }

}