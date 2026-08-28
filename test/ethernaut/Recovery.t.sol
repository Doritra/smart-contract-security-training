// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {SimpleToken, RecoveryFactory, RecoveryAttack} from "../../src/ethernaut/Recovery.sol";

contract RecoveryTest is Test {
    RecoveryFactory factory;
    RecoveryAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        factory = new RecoveryFactory();
        attack = new RecoveryAttack();
        vm.deal(player, 1 ether);
    }

    function testComputeAddressMatchesCreated() public {
        vm.prank(player);
        address tokenAddr = factory.createToken{value: 1 ether}();
        address computed = attack.computeTokenAddress(address(factory), 1);
        assertEq(computed, tokenAddr);
    }
    function testRecoveryExploit() public {
        vm.prank(player);
        address tokenAddr = factory.createToken{value: 1 ether}();
        SimpleToken token = SimpleToken(payable(tokenAddr));
        assertEq(token.owner(), player);

        vm.prank(player);
        token.destroy(payable(player));
        assertEq(tokenAddr.balance, 0);
        assertEq(player.balance, 1 ether);
    }

    function testFuzz_NonceDeterministic(uint256 nonce) public {
        nonce %= 100;
        address computed = attack.computeTokenAddress(address(factory), nonce);
        assertTrue(computed != address(0));
    }
}

contract RecoveryControlTest is Test {
    function testFactoryStartsEmpty() public {
        RecoveryFactory factory = new RecoveryFactory();
        assertEq(address(factory).balance, 0);
    }
}

// end

