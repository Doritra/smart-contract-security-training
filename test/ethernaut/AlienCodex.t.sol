// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautAlienCodex, AlienCodexAttack} from "../../src/ethernaut/AlienCodex.sol";

contract AlienCodexTest is Test {
    EthernautAlienCodex level;
    AlienCodexAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautAlienCodex();
        attack = new AlienCodexAttack();
    }

    function testDirectEOAIsBlocked() public {
        vm.prank(player, player);
        (bool ok,) = address(level).call(abi.encodeWithSignature("retract()"));
        assertFalse(ok);
        assertEq(level.owner(), address(this));
    }

    function testAlienCodexExploit() public {
        vm.prank(player, player);
        attack.attack(level, player);
        assertEq(level.owner(), player);
    }

    function testFuzz_OwnerOverwrite(uint256 seed) public {
        address who = address(uint160(seed));
        vm.assume(who != address(0));
        vm.prank(player, player);
        attack.attack(level, who);
        assertEq(level.owner(), who);
    }
}

contract AlienCodexControlTest is Test {
    function testInitialOwnerIsDeployer() public {
        EthernautAlienCodex level = new EthernautAlienCodex();
        assertEq(level.owner(), address(this));
    }
}

// end

