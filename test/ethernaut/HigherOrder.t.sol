// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {HigherOrder, HigherOrderAttack} from "../../src/ethernaut/HigherOrder.sol";

contract HigherOrderTest is Test {
    HigherOrder level;
    HigherOrderAttack attack;
    address player = makeAddr("player");
    address attacker = makeAddr("attacker");

    function setUp() public {
        level = new HigherOrder();
        attack = new HigherOrderAttack();
    }

    function testHigherOrderExploit() public {
        vm.prank(attacker);
        attack.attack(level);
        assertEq(level.treasury(), address(attack));
    }
}

contract HigherOrderControlTest is Test {
    function testTreasuryStartsZero() public {
        HigherOrder level = new HigherOrder();
        assertEq(level.treasury(), address(0));
    }
}

// end

