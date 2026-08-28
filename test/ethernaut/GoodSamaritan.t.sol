// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {GoodSamaritan, GoodSamaritanWallet, GoodSamaritanCoin, GoodSamaritanAttack} from "../../src/ethernaut/GoodSamaritan.sol";

contract GoodSamaritanTest is Test {
    GoodSamaritan sam;
    GoodSamaritanWallet wallet;
    GoodSamaritanCoin coin;
    GoodSamaritanAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        coin = new GoodSamaritanCoin(address(this));
        wallet = new GoodSamaritanWallet(address(coin));
        sam = new GoodSamaritan(address(wallet), address(coin));
        coin.setBalance(address(wallet), 100);
        attack = new GoodSamaritanAttack();
    }

    function testGoodSamaritanExploit() public {
        vm.prank(player);
        attack.attack(sam);
        assertEq(coin.balances(address(attack)), 100);
    }
}

contract GoodSamaritanControlTest is Test {
    function testWalletStartsFunded() public {
        GoodSamaritanCoin coin = new GoodSamaritanCoin(address(this));
        GoodSamaritanWallet wallet = new GoodSamaritanWallet(address(coin));
        coin.setBalance(address(wallet), 100);
        assertEq(coin.balances(address(wallet)), 100);
    }
}

// end

