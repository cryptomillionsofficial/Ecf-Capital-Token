pragma solidity ^0.5.0;

import "./IERC1400Partition.sol";

import "./ERC1400Raw.sol";

contract ERC1400Partition is IERC1400Partition, ERC1400Raw {

    bytes32[] internal _totalPartitions;

    mapping (bytes32 => uint256) internal _indexOfTotalPartitions;

    mapping (bytes32 => uint256) internal _totalSupplyByPartition;

    mapping (address => bytes32[]) internal _partitionsOf;

    mapping (address => mapping (bytes32 => uint256)) internal _indexOfPartitionsOf;

    mapping (address => mapping (bytes32 => uint256)) internal _balanceOfByPartition;

    bytes32[] internal _defaultPartitions;

    mapping (address => mapping (bytes32 => mapping (address => bool))) internal _authorizedOperatorByPartition;

    mapping (bytes32 => address[]) internal _controllersByPartition;

    mapping (bytes32 => mapping (address => bool)) internal _isControllerByPartition;

    constructor(string memory name, string memory symbol, uint256 granularity, address[] memory controllers, address certificateSigner, bytes32[] memory defaultPartitions) public ERC1400Raw(name, symbol, granularity, controllers, certificateSigner){

        _defaultPartitions = defaultPartitions;

    }

    function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256) {

        return _balanceOfByPartition[tokenHolder][partition];

    }

    function partitionsOf(address tokenHolder) external view returns (bytes32[] memory) {

        return _partitionsOf[tokenHolder];

    }

    function transferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external isValidCertificate(data) returns (bytes32) {

        return _transferByPartition(partition, msg.sender, msg.sender, to, value, data, "", true);

    }

    function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external isValidCertificate(operatorData) returns (bytes32) {

        require(_isOperatorForPartition(partition, msg.sender, from), "A7"); 

        return _transferByPartition(partition, msg.sender, from, to, value, data, operatorData, true);

    }

    function getDefaultPartitions() external view returns (bytes32[] memory) {

        return _defaultPartitions;

    }

    function setDefaultPartitions(bytes32[] calldata partitions) external onlyOwner {

        _defaultPartitions = partitions;

    }

    function controllersByPartition(bytes32 partition) external view returns (address[] memory) {

        return _controllersByPartition[partition];

    }

    function authorizeOperatorByPartition(bytes32 partition, address operator) external {

        _authorizedOperatorByPartition[msg.sender][partition][operator] = true;

        emit AuthorizedOperatorByPartition(partition, operator, msg.sender);

    }

    function revokeOperatorByPartition(bytes32 partition, address operator) external {

        _authorizedOperatorByPartition[msg.sender][partition][operator] = false;

        emit RevokedOperatorByPartition(partition, operator, msg.sender);

    }

    function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool) {

        return _isOperatorForPartition(partition, operator, tokenHolder);

    }

    function _isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) internal view returns (bool) {

        return (_isOperator(operator, tokenHolder) || _authorizedOperatorByPartition[tokenHolder][partition][operator] || (_isControllable && _isControllerByPartition[partition][operator]));

    }

    function _transferByPartition(bytes32 fromPartition, address operator, address from, address to, uint256 value, bytes memory data, bytes memory operatorData, bool preventLocking) internal returns (bytes32) {

        require(_balanceOfByPartition[from][fromPartition] >= value, "A4"); 

        bytes32 toPartition = fromPartition;

        if(operatorData.length != 0 && data.length >= 64) {

            toPartition = _getDestinationPartition(fromPartition, data);

        }

        _removeTokenFromPartition(from, fromPartition, value);

        _transferWithData(fromPartition, operator, from, to, value, data, operatorData, preventLocking);

        _addTokenToPartition(to, toPartition, value);

        emit TransferByPartition(fromPartition, operator, from, to, value, data, operatorData);

        if(toPartition != fromPartition) {

            emit ChangedPartition(fromPartition, toPartition, value);

        }

        return toPartition;

    }

    function _removeTokenFromPartition(address from, bytes32 partition, uint256 value) internal {

        _balanceOfByPartition[from][partition] = _balanceOfByPartition[from][partition].sub(value);

        _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].sub(value);

        if(_totalSupplyByPartition[partition] == 0) {

            uint256 index1 = _indexOfTotalPartitions[partition];

            require(index1 > 0, "A8"); 

            bytes32 lastValue = _totalPartitions[_totalPartitions.length - 1];

            _totalPartitions[index1 - 1] = lastValue; 

            _indexOfTotalPartitions[lastValue] = index1;

            _totalPartitions.length -= 1;

            _indexOfTotalPartitions[partition] = 0;

        }

        if(_balanceOfByPartition[from][partition] == 0) {

            uint256 index2 = _indexOfPartitionsOf[from][partition];

            require(index2 > 0, "A8"); 

            bytes32 lastValue = _partitionsOf[from][_partitionsOf[from].length - 1];

            _partitionsOf[from][index2 - 1] = lastValue;  

            _indexOfPartitionsOf[from][lastValue] = index2;

            _partitionsOf[from].length -= 1;

            _indexOfPartitionsOf[from][partition] = 0;

        }

    }

    function _addTokenToPartition(address to, bytes32 partition, uint256 value) internal {

        if(value != 0) {

            if (_indexOfPartitionsOf[to][partition] == 0) {

                _partitionsOf[to].push(partition);

                _indexOfPartitionsOf[to][partition] = _partitionsOf[to].length;

            }
            
            _balanceOfByPartition[to][partition] = _balanceOfByPartition[to][partition].add(value);

            if (_indexOfTotalPartitions[partition] == 0) {

                _totalPartitions.push(partition);

                _indexOfTotalPartitions[partition] = _totalPartitions.length;

            }
            
            _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].add(value);

        }

    }

    function _getDestinationPartition(bytes32 fromPartition, bytes memory data) internal pure returns(bytes32 toPartition) {

        bytes32 changePartitionFlag = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

        bytes32 flag;

        assembly {

            flag := mload(add(data, 32))

        }
    
        if(flag == changePartitionFlag) {

            assembly {

                toPartition := mload(add(data, 64))

            }

        } else {

            toPartition = fromPartition;

        }  

    }

    function totalPartitions() external view returns (bytes32[] memory) {

        return _totalPartitions;

    }

    function _setPartitionControllers(bytes32 partition, address[] memory operators) internal {

        for (uint i = 0; i<_controllersByPartition[partition].length; i++) {

            _isControllerByPartition[partition][_controllersByPartition[partition][i]] = false;

        }
     
        for (uint j = 0; j<operators.length; j++) {

            _isControllerByPartition[partition][operators[j]] = true;

        }

        _controllersByPartition[partition] = operators;

    }

    function transferWithData(address to, uint256 value, bytes calldata data) external isValidCertificate(data) {

        _transferByDefaultPartitions(msg.sender, msg.sender, to, value, data, "", true);

    }

    function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external isValidCertificate(operatorData) {

        require(_isOperator(msg.sender, from), "A7"); 

        _transferByDefaultPartitions(msg.sender, from, to, value, data, operatorData, true);

    }

    function redeem(uint256 value, bytes calldata data) external { 

        revert("A8: Transfer Blocked - Token restriction");

    }

    function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata /*operatorData*/) external { 

        revert("A8: Transfer Blocked - Token restriction");

    }

    function _transferByDefaultPartitions(address operator, address from, address to, uint256 value, bytes memory data, bytes memory operatorData, bool preventLocking) internal {

        require(_defaultPartitions.length != 0, "A8"); 

        uint256 _remainingValue = value;

        uint256 _localBalance;

        for (uint i = 0; i < _defaultPartitions.length; i++) {

            _localBalance = _balanceOfByPartition[from][_defaultPartitions[i]];
            
            if(_remainingValue <= _localBalance) {

                _transferByPartition(_defaultPartitions[i], operator, from, to, _remainingValue, data, operatorData, preventLocking);

                _remainingValue = 0;

                break;

            } else if (_localBalance != 0) {

                _transferByPartition(_defaultPartitions[i], operator, from, to, _localBalance, data, operatorData, preventLocking);

                _remainingValue = _remainingValue - _localBalance;

            }

        }

        require(_remainingValue == 0, "A8"); 

    }

}