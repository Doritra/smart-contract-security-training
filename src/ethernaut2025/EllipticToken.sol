// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

// Local training fixture (Ethernaut 2025 EllipticToken). Uses raw ecrecover
// (no low-s) to model OZ 4.6 ECDSA.
contract EllipticToken {
    string public name = "EllipticToken";
    string public symbol = "ETK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;
    mapping(bytes32 => bool) public usedHashes;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "not owner");
        owner = newOwner;
    }

    function redeemVoucher(
        uint256 amount,
        address receiver,
        bytes32 salt,
        bytes memory ownerSignature,
        bytes memory receiverSignature
    ) external {
        bytes32 voucherHash = keccak256(abi.encodePacked(amount, receiver, salt));
        require(!usedHashes[voucherHash], "used");

        require(_recover(voucherHash, ownerSignature) == owner, "bad owner");
        require(_recover(voucherHash, receiverSignature) == receiver, "bad receiver");

        usedHashes[voucherHash] = true;
        _mint(receiver, amount);
    }

    function permit(uint256 amount, address spender, bytes memory tokenOwnerSignature, bytes memory spenderSignature)
        external
    {
        bytes32 permitHash = keccak256(abi.encode(amount));
        require(!usedHashes[permitHash], "used");
        require(!usedHashes[bytes32(amount)], "used");

        address tokenOwner = _recover(bytes32(amount), tokenOwnerSignature);

        bytes32 permitAcceptHash = keccak256(abi.encodePacked(tokenOwner, spender, amount));
        require(_recover(permitAcceptHash, spenderSignature) == spender, "bad spender");

        usedHashes[permitHash] = true;
        _approve(tokenOwner, spender, amount);
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function _approve(address tokenOwner, address spender, uint256 value) internal {
        allowance[tokenOwner][spender] = value;
        emit Approval(tokenOwner, spender, value);
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

