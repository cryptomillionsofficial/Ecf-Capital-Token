pragma solidity ^0.5.0;

contract CertificateControllerMock {

    mapping(address => bool) internal _certificateSigners;

    mapping(address => uint256) internal _checkCount;

    event Checked(address sender);

    constructor(address _certificateSigner) public {
        _setCertificateSigner(_certificateSigner, true);
    }

    modifier isValidCertificate(bytes memory data) {

        require(_certificateSigners[msg.sender] || _checkCertificate(data, 0, 0x00000000), "A3"); 
        
        _checkCount[msg.sender] += 1; 
        
        emit Checked(msg.sender);

        _;
    }

    function checkCount(address sender) external view returns (uint256) {

        return _checkCount[sender];

    }

    function certificateSigners(address operator) external view returns (bool) {

        return _certificateSigners[operator];

    }

    function _setCertificateSigner(address operator, bool authorized) internal {

        require(operator != address(0)); 
        
        _certificateSigners[operator] = authorized;

    }

    function _checkCertificate(bytes memory data, uint256 value, bytes4 functionID) internal pure returns(bool) { 

        if(data.length > 0 && (data[0] == hex"10" || data[0] == hex"11" || data[0] == hex"22")) {

            return true;

        } else {

            return false;

        }

    }

}