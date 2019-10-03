pragma solidity ^0.5.0;

import "./MinterRole.sol";

import "./IERC1400.sol";

import "./ERC1400Partition.sol";

contract ERC1400 is IERC1400, ERC1400Partition, MinterRole {

    struct Doc {

        string docURI;

        bytes32 docHash;

    }

    mapping(bytes32 => Doc) internal _documents;

    bool internal _isIssuable;

    modifier issuableToken() {

        require(_isIssuable, "A8"); 

        _;

    }

    constructor (string memory name, string memory symbol, uint256 granularity, address[] memory controllers, address certificateSigner, bytes32[] memory defaultPartitions ) public ERC1400Partition (name, symbol, granularity, controllers, certificateSigner, defaultPartitions) {

        setInterfaceImplementation("ERC1400Token", address(this));

        _isControllable = true;

        _isIssuable = true;

    }

    function getDocument(bytes32 name) external view returns (string memory, bytes32) {

        require(bytes(_documents[name].docURI).length != 0); 

        return (_documents[name].docURI, _documents[name].docHash);

    }

    function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external {

        require(_isController[msg.sender]);

        _documents[name] = Doc({docURI: uri,docHash: documentHash});

        emit Document(name, uri, documentHash);

    }

    function isControllable() external view returns (bool) {

        return _isControllable;

    }

    function isIssuable() external view returns (bool) {

        return _isIssuable;

    }

    function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data) external onlyMinter issuableToken isValidCertificate(data) {

        _issueByPartition(partition, msg.sender, tokenHolder, value, data, "");

    }

    function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data) external isValidCertificate(data) {

        _redeemByPartition(partition, msg.sender, msg.sender, value, data, "");

    }

    function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data, bytes calldata operatorData) external isValidCertificate(operatorData) {

        require(_isOperatorForPartition(partition, msg.sender, tokenHolder), "A7"); 

        _redeemByPartition(partition, msg.sender, tokenHolder, value, data, operatorData);

    }

    function canTransferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external view returns (byte, bytes32, bytes32) {

        if(!_checkCertificate(data, 0, this.transferByPartition.selector)) { 

            return(hex"A3", "", partition); // Transfer Blocked - Sender lockup period not ended

        } else {

            return _canTransfer(partition, msg.sender, msg.sender, to, value, data, "");

        }

    }

    function canOperatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external view returns (byte, bytes32, bytes32) {

        if(!_checkCertificate(operatorData, 0, this.operatorTransferByPartition.selector)) { 

            return(hex"A3", "", partition); // Transfer Blocked - Sender lockup period not ended

        } else {

            return _canTransfer(partition, msg.sender, from, to, value, data, operatorData);

        }

    }

    function _canTransfer(bytes32 partition, address operator, address from, address to, uint256 value, bytes memory data, bytes memory operatorData) internal view returns (byte, bytes32, bytes32) {

        if(!_isOperatorForPartition(partition, operator, from))

            return(hex"A7", "", partition); 

        if((_balances[from] < value) || (_balanceOfByPartition[from][partition] < value))

            return(hex"A4", "", partition); 

        if(to == address(0))

            return(hex"A6", "", partition); 

        address senderImplementation;

        address recipientImplementation;

        senderImplementation = interfaceAddr(from, "ERC1400TokensSender");

        recipientImplementation = interfaceAddr(to, "ERC1400TokensRecipient");

        if((senderImplementation != address(0)) && !IERC1400TokensSender(senderImplementation).canTransfer(partition, from, to, value, data, operatorData))

            return(hex"A5", "", partition); 

        if((recipientImplementation != address(0)) && !IERC1400TokensRecipient(recipientImplementation).canReceive(partition, from, to, value, data, operatorData))

            return(hex"A6", "", partition); 

        if(!_isMultiple(value))

            return(hex"A9", "", partition); 

        return(hex"A2", "", partition);
    }

    function _issueByPartition(bytes32 toPartition, address operator, address to, uint256 value, bytes memory data, bytes memory operatorData) internal {

        _issue(toPartition, operator, to, value, data, operatorData);

        _addTokenToPartition(to, toPartition, value);

        emit IssuedByPartition(toPartition, operator, to, value, data, operatorData);

    }

    function _redeemByPartition(bytes32 fromPartition, address operator, address from, uint256 value, bytes memory data, bytes memory operatorData) internal {

        require(_balanceOfByPartition[from][fromPartition] >= value, "A4"); 

        _removeTokenFromPartition(from, fromPartition, value);

        _redeem(fromPartition, operator, from, value, data, operatorData);

        emit RedeemedByPartition(fromPartition, operator, from, value, data, operatorData);

    }

    function renounceControl() external onlyOwner {

        _isControllable = false;

    }

    function renounceIssuance() external onlyOwner {

        _isIssuable = false;

    }

    function setControllers(address[] calldata operators) external onlyOwner {

        _setControllers(operators);

    }

    function setPartitionControllers(bytes32 partition, address[] calldata operators) external onlyOwner {

        _setPartitionControllers(partition, operators);

    }

    function setCertificateSigner(address operator, bool authorized) external onlyOwner {

        _setCertificateSigner(operator, authorized);

    }

    function redeem(uint256 value, bytes calldata data) external isValidCertificate(data) {

        _redeemByDefaultPartitions(msg.sender, msg.sender, value, data, "");

    }

    function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external isValidCertificate(operatorData) {

        require(_isOperator(msg.sender, from), "A7");

        _redeemByDefaultPartitions(msg.sender, from, value, data, operatorData);

    }

    function _redeemByDefaultPartitions(address operator, address from, uint256 value, bytes memory data, bytes memory operatorData) internal {

        require(_defaultPartitions.length != 0, "A8"); 

        uint256 _remainingValue = value;

        uint256 _localBalance;

        for (uint i = 0; i < _defaultPartitions.length; i++) {

            _localBalance = _balanceOfByPartition[from][_defaultPartitions[i]];

            if(_remainingValue <= _localBalance) {

                _redeemByPartition(_defaultPartitions[i], operator, from, _remainingValue, data, operatorData);

                _remainingValue = 0;

                break;

            } else {

                _redeemByPartition(_defaultPartitions[i], operator, from, _localBalance, data, operatorData);

                _remainingValue = _remainingValue - _localBalance;

            }

        }

        require(_remainingValue == 0, "A8"); 

    }

}