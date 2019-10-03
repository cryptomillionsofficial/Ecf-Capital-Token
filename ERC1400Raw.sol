pragma solidity ^0.5.0;

import "./SafeMath.sol";

import "./Ownable.sol";

import "./ReentrancyGuard.sol";

import "./ERC1820Client.sol";

import "./CertificateController.sol";

import "./IERC1400Raw.sol";

import "./IERC1400TokensSender.sol";

import "./IERC1400TokensRecipient.sol";

contract ERC1400Raw is IERC1400Raw, Ownable, ERC1820Client, CertificateController, ReentrancyGuard {

    using SafeMath for uint256;

    string internal _name;

    string internal _symbol;

    uint256 internal _granularity;

    uint256 internal _totalSupply;

    bool internal _isControllable;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => bool)) internal _authorizedOperator;

    address[] internal _controllers;

    mapping(address => bool) internal _isController;
  
    constructor(string memory name, string memory symbol, uint256 granularity, address[] memory controllers, address certificateSigner) public CertificateController(certificateSigner) {

        _name = name;

        _symbol = symbol;

        _totalSupply = 0;

        require(granularity >= 1); 

        _granularity = granularity;

        _setControllers(controllers);

    }

    function name() external view returns(string memory) {

        return _name;

    }

    function symbol() external view returns(string memory) {

        return _symbol;

    }

    function totalSupply() external view returns (uint256) {

        return _totalSupply;

    }

    function balanceOf(address tokenHolder) external view returns (uint256) {

        return _balances[tokenHolder];

    }

    function granularity() external view returns(uint256) {

        return _granularity;

    }

    function controllers() external view returns (address[] memory) {

        return _controllers;

    }

    function authorizeOperator(address operator) external {

        require(operator != msg.sender);

        _authorizedOperator[operator][msg.sender] = true;

        emit AuthorizedOperator(operator, msg.sender);

    }

    function revokeOperator(address operator) external {

        require(operator != msg.sender);

        _authorizedOperator[operator][msg.sender] = false;

        emit RevokedOperator(operator, msg.sender);

    }

    function isOperator(address operator, address tokenHolder) external view returns (bool) {

        return _isOperator(operator, tokenHolder);

    }

    function transferWithData(address to, uint256 value, bytes calldata data) external isValidCertificate(data) {

        _transferWithData("", msg.sender, msg.sender, to, value, data, "", true);

    }

    function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external isValidCertificate(operatorData) {

        require(_isOperator(msg.sender, from), "A7"); 

        _transferWithData("", msg.sender, from, to, value, data, operatorData, true);

    }

    function redeem(uint256 value, bytes calldata data) external isValidCertificate(data) {

        _redeem("", msg.sender, msg.sender, value, data, "");

    }

    function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external isValidCertificate(operatorData) {

        require(_isOperator(msg.sender, from), "A7"); 

        _redeem("", msg.sender, from, value, data, operatorData);

    }

    function _isMultiple(uint256 value) internal view returns(bool) {

        return(value.div(_granularity).mul(_granularity) == value);

    }

    function _isRegularAddress(address addr) internal view returns(bool) {

        if (addr == address(0)) { 

            return false; 

        }
        
        uint size;

        assembly { size := extcodesize(addr) } 

        return size == 0;

    }

    function _isOperator(address operator, address tokenHolder) internal view returns (bool) {

        return (operator == tokenHolder || _authorizedOperator[operator][tokenHolder] || (_isControllable && _isController[operator]));

    }

    function _transferWithData(bytes32 partition, address operator, address from, address to, uint256 value, bytes memory data, bytes memory operatorData, bool preventLocking) internal nonReentrant {

        require(_isMultiple(value), "A9"); 

        require(to != address(0), "A6"); 

        require(_balances[from] >= value, "A4"); 

        _callSender(partition, operator, from, to, value, data, operatorData);

        _balances[from] = _balances[from].sub(value);

        _balances[to] = _balances[to].add(value);

        _callRecipient(partition, operator, from, to, value, data, operatorData, preventLocking);

        emit TransferWithData(operator, from, to, value, data, operatorData);

    }

    function _redeem(bytes32 partition, address operator, address from, uint256 value, bytes memory data, bytes memory operatorData) internal nonReentrant {

        require(_isMultiple(value), "A9"); 

        require(from != address(0), "A5"); 

        require(_balances[from] >= value, "A4"); 

        _callSender(partition, operator, from, address(0), value, data, operatorData);

        _balances[from] = _balances[from].sub(value);

        _totalSupply = _totalSupply.sub(value);

        emit Redeemed(operator, from, value, data, operatorData);

    }

    function _callSender(bytes32 partition, address operator, address from, address to, uint256 value, bytes memory data, bytes memory operatorData) internal {

        address senderImplementation;

        senderImplementation = interfaceAddr(from, "ERC1400TokensSender");

        if (senderImplementation != address(0)) {

            IERC1400TokensSender(senderImplementation).tokensToTransfer(partition, operator, from, to, value, data, operatorData);

        }

    }

    function _callRecipient(bytes32 partition, address operator, address from, address to, uint256 value, bytes memory data, bytes memory operatorData, bool preventLocking) internal {

        address recipientImplementation;

        recipientImplementation = interfaceAddr(to, "ERC1400TokensRecipient");

        if (recipientImplementation != address(0)) {

            IERC1400TokensRecipient(recipientImplementation).tokensReceived(partition, operator, from, to, value, data, operatorData);

        } else if (preventLocking) {

            require(_isRegularAddress(to), "A6"); 

        }

    }

    function _issue(bytes32 partition, address operator, address to, uint256 value, bytes memory data, bytes memory operatorData) internal nonReentrant {

        require(_isMultiple(value), "A9"); 

        require(to != address(0), "A6"); 

        _totalSupply = _totalSupply.add(value);

        _balances[to] = _balances[to].add(value);
    
        _callRecipient(partition, operator, address(0), to, value, data, operatorData, true);
    
        emit Issued(operator, to, value, data, operatorData);

    }

    function _setControllers(address[] memory operators) internal {

        for (uint i = 0; i<_controllers.length; i++){

          _isController[_controllers[i]] = false;

        }
        
        for (uint j = 0; j<operators.length; j++){

          _isController[operators[j]] = true;

        }
        
        _controllers = operators;

    }

}