// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautToken, TokenAttack} from "../../src/ethernaut/Token.sol";

contract TokenTest is Test {
    EthernautToken level;
    TokenAttack attack;
    address player = makeAddr("player");
    address recipient = makeAddr("recipient");

    function setUp() public {
        level = new EthernautToken(20);
        attack = new TokenAttack();
        vm.deal(player, 1 ether);
    }

    function testOverTransferWrapsBalance() public {
        uint256 beforeBalance = level.balances(address(this));
        level.transfer(recipient, beforeBalance + 1);
        assertEq(level.balances(address(this)), type(uint256).max);
        assertEq(level.balances(recipient), beforeBalance + 1);
    }

    function testAttackerContractCanTriggerUnderflow() public {
        uint256 amount = level.balances(address(this)) + 1;
        attack.attack(level, recipient, amount);
        assertEq(level.balances(address(attack)), type(uint256).max - amount + 1);
    }

    function testFuzz_OverTransferWraps(uint256 delta) public {
        delta %= 1_000_000;
        uint256 amount = level.balances(address(this)) + delta + 1;
        level.transfer(recipient, amount);
        assertEq(level.balances(address(this)), type(uint256).max - delta);
    }
}

contract TokenControlTest is Test {
    EthernautToken level;

    function setUp() public {
        level = new EthernautToken(20);
    }

    function testInitialSupplyAssignedToDeployer() public view {
        assertEq(level.balances(address(this)), 20);
        assertEq(level.totalSupply(), 20);
    }
}

// Training fixture only. This intentionally models the classic pre-0.8 Ethernaut challenge.
// Production ERC-20 code must use checked arithmetic and enforce balance >= value.

// end
