// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautReentrance, ReentranceAttack} from "../../src/ethernaut/Reentrance.sol";

contract ReentranceTest is Test {
    EthernautReentrance level;
    ReentranceAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautReentrance{value: 10 ether}();
        attack = new ReentranceAttack();
        vm.deal(player, 1 ether);
    }

    function testDirectWithdrawalReturnsDeposit() public {
        vm.prank(player);
        level.donate{value: 1 ether}(player);
        vm.prank(player);
        level.withdraw(1 ether);
        assertEq(level.balanceOf(player), 0);
        assertEq(address(level).balance, 10 ether);
    }

    function testReentranceDrainsTarget() public {
        uint256 before = address(level).balance;
        vm.prank(player);
        attack.attack{value: 1 ether}(level, 1 ether);
        assertEq(address(level).balance, 0);
        assertEq(attack.drained(), before + 1 ether);
    }

    function testFuzz_ReentranceDrains(uint96 seed) public {
        uint256 deposit = 10 ether + (uint256(seed) % 1 ether);
        vm.deal(player, deposit);
        vm.prank(player);
        attack.attack{value: deposit}(level, deposit);
        assertEq(address(level).balance, 0);
        assertEq(attack.drained(), 10 ether + deposit);
    }
}

contract ReentranceControlTest is Test {
    function testTargetHasInitialFunds() public {
        EthernautReentrance level = new EthernautReentrance{value: 10 ether}();
        assertEq(address(level).balance, 10 ether);
    }
}

// end

