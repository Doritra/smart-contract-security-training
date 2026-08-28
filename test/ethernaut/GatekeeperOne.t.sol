// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautGatekeeperOne, GatekeeperOneAttack} from "../../src/ethernaut/GatekeeperOne.sol";

contract GatekeeperOneTest is Test {
    EthernautGatekeeperOne level;
    GatekeeperOneAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautGatekeeperOne();
        attack = new GatekeeperOneAttack();
    }

    function testDirectEOAIsBlocked() public {
        vm.prank(player, player);
        bytes8 key = bytes8(uint64(uint160(player)) & 0xFFFFFFFF0000FFFF);
        (bool ok,) = address(level).call(abi.encodeWithSignature("enter(bytes8)", key));
        assertFalse(ok);
        assertEq(level.entrant(), address(0));
    }

    function testGatekeeperOneExploit() public {
        vm.prank(player, player);
        attack.attack(level);
        assertEq(level.entrant(), player);
    }

    function testFuzz_KeyMaskMatchesAddress(uint256 seed) public {
        address who = address(uint160(seed));
        bytes8 key = bytes8(uint64(uint160(who)) & 0xFFFFFFFF0000FFFF);
        assertEq(uint32(uint64(key)), uint16(uint64(key)));
        assertEq(uint32(uint64(key)), uint16(uint160(who)));
    }
}

contract GatekeeperOneControlTest is Test {
    function testStartsWithNoEntrant() public {
        EthernautGatekeeperOne level = new EthernautGatekeeperOne();
        assertEq(level.entrant(), address(0));
    }
}

// end

