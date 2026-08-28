// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautShop, ShopBuyer} from "../../src/ethernaut/Shop.sol";

contract ShopTest is Test {
    EthernautShop level;
    ShopBuyer buyer;

    function setUp() public {
        level = new EthernautShop();
        buyer = new ShopBuyer();
    }

    function testDirectEOACannotBuy() public {
        address player = makeAddr("player");
        vm.prank(player, player);
        (bool ok,) = address(level).call(abi.encodeWithSignature("buy()"));
        assertFalse(ok);
        assertFalse(level.isSold());
    }

    function testShopExploit() public {
        buyer.attack(level);
        assertTrue(level.isSold());
        assertEq(level.price(), 0);
    }

    function testFuzz_BuyerReturnsZeroAfterSold(uint256 seed) public {
        buyer.attack(level);
        assertTrue(level.isSold());
        assertEq(level.price(), 0);
    }
}

contract ShopControlTest is Test {
    function testInitialPrice() public {
        EthernautShop level = new EthernautShop();
        assertEq(level.price(), 100);
        assertFalse(level.isSold());
    }
}

// end

