// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {LibraryContract, EthernautPreservation, PreservationAttack} from "../../src/ethernaut/Preservation.sol";

contract PreservationTest is Test {
    EthernautPreservation level;
    PreservationAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        LibraryContract lib1 = new LibraryContract();
        LibraryContract lib2 = new LibraryContract();
        level = new EthernautPreservation(address(lib1), address(lib2));
        attack = new PreservationAttack();
    }

    function testDirectCallCannotChangeOwner() public {
        vm.prank(player, player);
        (bool ok,) = address(level).call(
            abi.encodeWithSignature("setFirstTime(uint256)", 1)
        );
        assertTrue(ok);
        assertEq(level.owner(), address(this));
    }

    function testPreservationExploit() public {
        vm.prank(player, player);
        attack.attack(level, player);
        assertEq(level.timeZone1Library(), address(attack));
        assertEq(level.owner(), address(attack));
    }
}

contract PreservationControlTest is Test {
    function testInitialOwnerIsDeployer() public {
        LibraryContract lib1 = new LibraryContract();
        LibraryContract lib2 = new LibraryContract();
        EthernautPreservation level = new EthernautPreservation(address(lib1), address(lib2));
        assertEq(level.owner(), address(this));
    }
}

// end

