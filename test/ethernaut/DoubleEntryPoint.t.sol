// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {DoubleEntryPoint, CryptoVault, FortaBot, DoubleEntryAttack} from "../../src/ethernaut/DoubleEntryPoint.sol";

contract DoubleEntryPointTest is Test {
    DoubleEntryPoint dep;
    CryptoVault vault;
    FortaBot bot;
    DoubleEntryAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        dep = new DoubleEntryPoint();
        vm.prank(player);
        vault = new CryptoVault(dep);
        bot = new FortaBot();
        dep.setDetectionBot(address(bot));
        dep.setBalance(address(vault), 100);
        attack = new DoubleEntryAttack();
    }

    function testDoubleEntryExploit() public {
        vm.prank(player);
        vault.sweepToken(address(dep));
        assertEq(dep.balances(address(vault)), 0);
        assertEq(dep.balances(player), 100);
    }
}

contract DoubleEntryControlTest is Test {
    function testVaultStartsFunded() public {
        DoubleEntryPoint dep = new DoubleEntryPoint();
        CryptoVault vault = new CryptoVault(dep);
        dep.setBalance(address(vault), 100);
        assertEq(dep.balances(address(vault)), 100);
    }
}

// end

