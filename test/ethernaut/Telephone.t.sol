// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautTelephone, TelephoneAttack} from "../../src/ethernaut/Telephone.sol";

contract TelephoneTest is Test {
    EthernautTelephone level;
    TelephoneAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautTelephone();
        attack = new TelephoneAttack();
    }

    function testDirectCallCannotChangeOwner() public {
        vm.prank(player, player);
        level.changeOwner(player);
        assertEq(level.owner(), address(this));
    }

    function testIntermediaryChangesOwner() public {
        vm.prank(player);
        attack.attack(level, player);
        assertEq(level.owner(), player);
    }

    function testFuzz_IntermediaryCanSetAnyOwner(address newOwner) public {
        vm.assume(newOwner != address(0));
        vm.prank(player);
        attack.attack(level, newOwner);
        assertEq(level.owner(), newOwner);
    }
}

contract TelephoneControlTest is Test {
    EthernautTelephone level;

    function setUp() public {
        level = new EthernautTelephone();
    }

    function testOwnerStartsAsDeployer() public view {
        assertEq(level.owner(), address(this));
    }
}

