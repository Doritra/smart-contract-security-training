// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {Stake, StakeAttack} from "../../src/ethernaut/Stake.sol";

contract StakeTest is Test {
    Stake level;
    StakeAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new Stake{value: 1 ether}();
        attack = new StakeAttack();
    }

    function testStakeExploit() public {
        vm.deal(player, 0.001 ether);
        vm.prank(player);
        attack.attack{value: 0.001 ether}(level);
        // The contract is drained below 1 ether (attacker keeps withdrawing).
        assertLt(address(level).balance, 1 ether);
    }
}

contract StakeControlTest is Test {
    function testStakeStartsFunded() public {
        Stake level = new Stake{value: 1 ether}();
        assertEq(address(level).balance, 1 ether);
    }
}

// end

