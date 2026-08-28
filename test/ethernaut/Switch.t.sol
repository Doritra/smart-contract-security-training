// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautSwitch, SwitchAttack} from "../../src/ethernaut/Switch.sol";

contract SwitchTest is Test {
    EthernautSwitch level;
    SwitchAttack attack;

    function setUp() public {
        level = new EthernautSwitch();
        attack = new SwitchAttack();
    }

    function testSwitchExploit() public {
        attack.attack(level);
        assertTrue(level.switchOn());
        assertEq(level.lastSelector(), bytes4(keccak256("turnSwitchOn()")));
    }
}

contract SwitchControlTest is Test {
    function testStartsOff() public {
        EthernautSwitch level = new EthernautSwitch();
        assertFalse(level.switchOn());
    }
}

// end

