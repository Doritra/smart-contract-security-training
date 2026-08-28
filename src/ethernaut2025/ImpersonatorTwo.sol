// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "./Ownable.sol";

// Local training fixture (Ethernaut 2025 ImpersonatorTwo). Uses raw
// ecrecover (no low-s) to model OZ 4.6 ECDSA.
contract ImpersonatorTwo is Ownable {
    address public admin;
    uint256 public nonce;
    bool locked;

    error NotAdmin();
    error InvalidSignature();
    error FundsLocked();

    constructor() payable {}

    modifier onlyAdmin() {
        require(msg.sender == admin, NotAdmin());
        _;
    }

    function setAdmin(bytes memory signature, address newAdmin) public {
        bytes32 message = _hashMessage(abi.encodePacked("admin", _toString(nonce), newAdmin));
        require(_verify(message, signature), InvalidSignature());
        nonce++;
        admin = newAdmin;
    }

    function switchLock(bytes memory signature) public {
        bytes32 message = _hashMessage(abi.encodePacked("lock", _toString(nonce)));
        require(_verify(message, signature), InvalidSignature());
        nonce++;
        locked = !locked;
    }

    function withdraw() public onlyAdmin {
        require(!locked, FundsLocked());
        payable(admin).transfer(address(this).balance);
    }

    function _hashMessage(bytes memory message) internal pure returns (bytes32) {
        // OZ 4.6 toEthSignedMessageHash(bytes): prefix includes message length.
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", _toString(message.length), message));
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(hash, v, r, s) == owner();
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

