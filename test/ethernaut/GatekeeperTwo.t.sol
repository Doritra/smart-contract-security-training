// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautGatekeeperTwo, GatekeeperTwoAttack} from "../../src/ethernaut/GatekeeperTwo.sol";

contract GatekeeperTwoTest is Test {
    EthernautGatekeeperTwo level;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautGatekeeperTwo();
    }

    function testDirectEOAIsBlocked() public {
        vm.prank(player, player);
        bytes8 key = bytes8(uint64(uint160(player)));
        (bool ok,) = address(level).call(abi.encodeWithSignature("enter(bytes8)", key));
        assertFalse(ok);
        assertEq(level.entrant(), address(0));
    }

    function testGatekeeperTwoExploit() public {
        vm.prank(player, player);
        new GatekeeperTwoAttack(level);
        assertEq(level.entrant(), player);
    }

    function testFuzz_KeyDerivation(uint256 seed) public {
        uint64 low = uint64(seed);
        vm.assume(low != 0);
        bytes8 key = bytes8(low);
        assertEq(uint64(key), low);
        assertTrue(uint64(key) != 0);
    }
}

contract GatekeeperTwoControlTest is Test {
    function testStartsWithNoEntrant() public {
        EthernautGatekeeperTwo level = new EthernautGatekeeperTwo();
        assertEq(level.entrant(), address(0));
    }
}

// end

