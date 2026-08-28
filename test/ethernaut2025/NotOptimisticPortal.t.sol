// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {NotOptimisticPortal} from "../../src/ethernaut2025/NotOptimisticPortal.sol";

// Genesis RLP block header from the official factory (stateRoot = 0xd7d3685b...)
bytes constant GENESIS_RLP = hex"f90204a00000000000000000000000000000000000000000000000000000000000000000a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347940000000000000000000000000000000000000000a0d7d3685b57d9897755fad850b19f7c43debfded002e18a9e8e5b63639882b6f9a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470b90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000184039fd3988401c9c38080845fc630578b4354465f5061796c6f6164a00000000000000000000000000000000000000000000000000000000000000000880000000000000000";

contract NotOptimisticPortalTest is Test {
    NotOptimisticPortal portal;
    address player = makeAddr("player");
    address governance = address(uint160(uint256(keccak256("governance"))));

    // Dummy receiver contract with onMessageReceived(bytes) selector = 0x3a69197e
    address receiver;

    function setUp() public {
        portal = new NotOptimisticPortal("CTFToken", "CTFT", GENESIS_RLP, governance);
        receiver = address(new DummyReceiver());
        vm.deal(player, 100 ether);
        // Give player some tokens to burn in sendMessage
        vm.prank(address(portal));
        portal.transfer(player, 0); // no-op, just placeholder
    }

    // CONTROL: hash collision — len 0 and len 1 produce the SAME withdrawalHash.
    // sendMessage with len 1 sets slot; executeMessage with len 0 must pass
    // the `!executedMessages` check (same hash) — proving the loop bug.
    function testHashCollisionLen0EqualsLen1() public {
        bytes memory data = abi.encodeWithSelector(bytes4(0x3a69197e), "hello");
        address[] memory recv1 = new address[](1);
        recv1[0] = receiver;
        bytes[] memory dat1 = new bytes[](1);
        dat1[0] = data;

        // Need tokens for sendMessage burn — mint to player via direct storage? 
        // Instead: prove collision WITHOUT sendMessage by checking both compute
        // differently: executeMessage with len 0 vs len 1.
        // We can't call internal _computeMessageSlot, so we test via behavior:
        // len 1 send sets slot, len 0 execute reuses it (same hash).
        // To have balance, deploy portal with player as owner and mint via _mint is internal.
        // Simplest: use a token transfer — portal starts with 0 supply. Use sendMessage(0) (no burn).
        vm.prank(player, player);
        portal.sendMessage(0, recv1, dat1, 12345); // sets slot = H(player,0,0,0,12345), no burn

        // Now executeMessage with len 0, same tokenReceiver/amount/salt → same hash
        address[] memory recv0 = new address[](0);
        bytes[] memory dat0 = new bytes[](0);
        NotOptimisticPortal.ProofData memory emptyProof =
            NotOptimisticPortal.ProofData("", "", "");

        // Expect revert at proof verification (NOT "Message already executed")
        // This proves the hash collision: the !executedMessages check passed.
        // Empty proof fails RLP parsing first ("RLP item cannot be null") —
        // the key point is it does NOT revert with "Message already executed".
        vm.prank(player, player);
        vm.expectRevert(bytes("RLP item cannot be null."));
        portal.executeMessage(player, 0, recv0, dat0, 12345, emptyProof, 0);
    }

    // CONTROL: same message executed twice with len 1 → blocked by executedMessages
    function testSameHashReplayBlocked() public {
        bytes memory data = abi.encodeWithSelector(bytes4(0x3a69197e), "hello");
        address[] memory recv = new address[](1);
        recv[0] = receiver;
        bytes[] memory dat = new bytes[](1);
        dat[0] = data;

        vm.prank(player, player);
        portal.sendMessage(0, recv, dat, 999);
        // Second send with same params → same slot → "Message already sent"
        vm.prank(player, player);
        vm.expectRevert(bytes("Message already sent"));
        portal.sendMessage(0, recv, dat, 999);
    }
}

contract DummyReceiver {
    function onMessageReceived(bytes calldata) external {}
}
