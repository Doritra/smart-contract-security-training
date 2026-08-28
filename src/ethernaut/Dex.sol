// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EthernautDex {
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    address public token1;
    address public token2;

    constructor(address token1_, address token2_) {
        token1 = token1_;
        token2 = token2_;
    }

    function setTokens(address token1_, address token2_) external {
        token1 = token1_;
        token2 = token2_;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        uint256 balanceFrom = IERC20(from).balanceOf(address(this));
        uint256 balanceTo = IERC20(to).balanceOf(address(this));
        return (amount * balanceTo) / balanceFrom;
    }

    function swap(address from, address to, uint256 amount) external {
        uint256 price = getSwapPrice(from, to, amount);
        allowance[msg.sender][address(this)] -= amount;
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).transfer(msg.sender, price);
    }
}

contract DexAttack {
    function swap(address from, address to, EthernautDex dex, uint256 amount) external {
        dex.approve(address(dex), type(uint256).max);
        dex.swap(from, to, amount);
    }
}

// Local training fixture: the swap price uses the wrong constant-product
// formula, letting an attacker drain reserves with alternating swaps.

