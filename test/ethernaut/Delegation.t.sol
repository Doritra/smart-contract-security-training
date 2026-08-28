// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautDelegate, EthernautDelegation, DelegationAttack} from "../../src/ethernaut/Delegation.sol";

contract DelegationTest is Test {
    EthernautDelegate delegate;
    EthernautDelegation level;
    DelegationAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        delegate = new EthernautDelegate(address(this));
        level = new EthernautDelegation(address(delegate));
        attack = new DelegationAttack();
    }

    function testDirectUnknownCallCannotChangeOwner() public {
        vm.prank(player, player);
        (bool ok,) = address(level).call(abi.encodeWithSignature("unknown()"));
        assertFalse(ok);
        assertEq(level.owner(), address(this));
    }

    function testDelegationExploit() public {
        vm.prank(player);
        attack.attack(level);
        assertEq(level.owner(), address(attack));
    }

    function testFuzz_SelectorChangesProxyOwner(uint256 seed) public {
        vm.assume(seed != 0);
        vm.prank(player);
        attack.attack(level);
        assertEq(level.owner(), address(attack));
    }
}

contract DelegationControlTest is Test {
    function testDelegateHasIndependentOwnerSlot() public {
        EthernautDelegate delegate = new EthernautDelegate(address(this));
        assertEq(delegate.owner(), address(this));
    }
}

// end
