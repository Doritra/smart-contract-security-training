// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautGatekeeperThree, GatekeeperThreeAttack} from "../../src/ethernaut/GatekeeperThree.sol";

contract GatekeeperThreeTest is Test {
    EthernautGatekeeperThree level;
    GatekeeperThreeAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautGatekeeperThree();
        attack = new GatekeeperThreeAttack();
    }

    function testGatekeeperThreeExploit() public {
        bytes32 key = bytes32(uint256(uint160(player)) & 0xFFFFFFFFFFFFFFFF);
        vm.prank(player, player);
        attack.attack(level, key);
        assertEq(level.entrant(), player);
    }
}

contract GatekeeperThreeControlTest is Test {
    function testStartsLocked() public {
        EthernautGatekeeperThree level = new EthernautGatekeeperThree();
        assertEq(level.entrant(), address(0));
        assertFalse(level.allowEntrant());
    }
}

// end

