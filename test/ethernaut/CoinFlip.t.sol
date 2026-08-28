// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautCoinFlip, CoinFlipAttack} from "../../src/ethernaut/CoinFlip.sol";

contract CoinFlipTest is Test {
    EthernautCoinFlip level;
    CoinFlipAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautCoinFlip();
        attack = new CoinFlipAttack();
    }

    function testWrongGuessLoses() public {
        vm.roll(100);
        bool predicted = uint256(blockhash(99)) / (2 ** 255) == 1;
        vm.roll(101);
        assertFalse(level.flip(!predicted));
        assertEq(level.consecutiveWins(), 0);
    }

    function testCoinFlipExploit() public {
        vm.startPrank(player);
        for (uint256 i = 0; i < 10; ++i) {
            vm.roll(block.number + 1);
            assertTrue(attack.attack(level));
        }
        vm.stopPrank();
        assertEq(level.consecutiveWins(), 10);
    }

    function testFuzz_PredictionMatchesTarget(uint256 seed) public {
        uint256 nextBlock = 100 + (seed % 1000);
        vm.roll(nextBlock);
        bool result = attack.attack(level);
        assertTrue(result);
        assertEq(level.consecutiveWins(), 1);
    }
}

contract CoinFlipControlTest is Test {
    EthernautCoinFlip level;

    function setUp() public {
        level = new EthernautCoinFlip();
    }

    function testSameBlockReplayBlocked() public {
        vm.roll(100);
        bool guess = uint256(blockhash(99)) / (2 ** 255) == 1;
        assertTrue(level.flip(guess));
        vm.expectRevert("Same block");
        level.flip(guess);
    }
}

