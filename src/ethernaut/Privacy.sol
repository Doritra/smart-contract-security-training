// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautPrivacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory initialData) {
        data = initialData;
    }

    function unlock(bytes16 key) external {
        require(key == bytes16(data[2]), "Wrong key");
        locked = false;
    }
}

contract PrivacyAttack {
    function attack(EthernautPrivacy target, bytes16 key) external {
        target.unlock(key);
    }
}

// Local training fixture: private and packed storage remain readable from EVM state.

// end


// done


