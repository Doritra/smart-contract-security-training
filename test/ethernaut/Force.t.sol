// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautForce, ForceAttack} from "../../src/ethernaut/Force.sol";

contract ForceTest is Test {
    EthernautForce level;
    ForceAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautForce();
        attack = new ForceAttack();
        vm.deal(player, 1 ether);
    }

    function testNormalTransferBlocked() public {
        vm.prank(player);
        (bool ok,) = address(level).call{value: 1 wei}("");
        assertFalse(ok);
        assertEq(address(level).balance, 0);
    }

    function testForceExploit() public {
        vm.prank(player);
        attack.attack{value: 1 wei}(level);
        assertEq(address(level).balance, 1 wei);
    }

    function testFuzz_ForcedValueArrives(uint96 amount) public {
        vm.assume(amount > 0);
        vm.deal(player, amount);
        vm.prank(player);
        attack.attack{value: amount}(level);
        assertEq(address(level).balance, amount);
    }
}

contract ForceControlTest is Test {
    function testTargetStartsEmpty() public {
        EthernautForce level = new EthernautForce();
        assertEq(address(level).balance, 0);
    }
}

// end
