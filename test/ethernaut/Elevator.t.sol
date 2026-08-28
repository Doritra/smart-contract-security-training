// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautElevator, ElevatorAttack} from "../../src/ethernaut/Elevator.sol";

contract ElevatorTest is Test {
    EthernautElevator level;
    ElevatorAttack attack;

    function setUp() public {
        level = new EthernautElevator();
        attack = new ElevatorAttack();
    }

    function testTargetStartsBelowTop() public {
        assertFalse(level.top());
        assertEq(level.floor(), 0);
    }

    function testElevatorExploit() public {
        attack.attack(level, 99);
        assertTrue(level.top());
        assertEq(level.floor(), 99);
    }

    function testFuzz_TogglePredicateReachesTop(uint256 floor_) public {
        floor_ %= 1_000_000;
        attack.attack(level, floor_);
        assertTrue(level.top());
        assertEq(level.floor(), floor_);
    }
}

contract ElevatorControlTest is Test {
    function testPlainCallerCannotUseElevator() public {
        EthernautElevator level = new EthernautElevator();
        (bool ok,) = address(level).call(abi.encodeWithSignature("goTo(uint256)", 1));
        assertFalse(ok);
        assertFalse(level.top());
    }
}

// end

