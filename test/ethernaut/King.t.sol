// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautKing, KingAttack} from "../../src/ethernaut/King.sol";

contract KingTest is Test {
    EthernautKing level;
    KingAttack attack;
    address player = makeAddr("player");
    address nextBidder = makeAddr("nextBidder");

    function setUp() public {
        level = new EthernautKing{value: 1 ether}();
        attack = new KingAttack();
        vm.deal(player, 2 ether);
        vm.deal(nextBidder, 3 ether);
    }

    receive() external payable {}

    function testNormalBidChangesKing() public {
        vm.prank(player);
        (bool ok,) = address(level).call{value: 2 ether}("");
        assertTrue(ok);
        assertEq(level.king(), player);
        assertEq(level.prize(), 2 ether);
    }

    function testKingAttackLocksFurtherBids() public {
        vm.prank(player);
        attack.attack{value: 2 ether}(level);
        assertEq(level.king(), address(attack));

        vm.prank(nextBidder);
        (bool ok,) = address(level).call{value: 3 ether}("");
        assertFalse(ok);
        assertEq(level.king(), address(attack));
        assertEq(level.prize(), 2 ether);
    }

    function testFuzz_RevertingKingBlocksLargerBid(uint96 extra) public {
        uint256 bid = 1 ether + (uint256(extra) % 1 ether) + 1;
        vm.deal(player, bid);
        vm.prank(player);
        attack.attack{value: bid}(level);

        vm.deal(nextBidder, bid + 1 ether);
        vm.prank(nextBidder);
        (bool ok,) = address(level).call{value: bid + 1 ether}("");
        assertFalse(ok);
    }
}

contract KingControlTest is Test {
    function testInitialKingIsDeployer() public {
        EthernautKing level = new EthernautKing{value: 1 ether}();
        assertEq(level.king(), address(this));
        assertEq(level.prize(), 1 ether);
    }
}

// end
