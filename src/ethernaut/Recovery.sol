// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract SimpleToken {
    address public owner;
    bool public claimed;

    constructor(address initialOwner) payable {
        owner = initialOwner;
    }

    function destroy(address payable recipient) external {
        require(msg.sender == owner, "not owner");
        selfdestruct(recipient);
    }
}

contract RecoveryFactory {
    function createToken() external payable returns (address) {
        SimpleToken token = new SimpleToken{value: msg.value}(msg.sender);
        return address(token);
    }
}

contract RecoveryAttack {
    function computeTokenAddress(address factory, uint256 nonce) external pure returns (address) {
        bytes memory rlpNonce = nonce == 0 ? abi.encodePacked(bytes1(0x80)) : abi.encodePacked(uint8(nonce));
        return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), factory, rlpNonce))))
        );
    }
}

// Local training fixture: contract addresses created via CREATE are deterministic
// from creator address and nonce.

