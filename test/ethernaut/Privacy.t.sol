// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautPrivacy, PrivacyAttack} from "../../src/ethernaut/Privacy.sol";

contract PrivacyTest is Test {
    EthernautPrivacy level;
    PrivacyAttack attack;
    bytes32[3] data;
    bytes16 key;

    function setUp() public {
        data[0] = keccak256("a");
        data[1] = keccak256("b");
        data[2] = keccak256("c");
        key = bytes16(data[2]);
        level = new EthernautPrivacy(data);
        attack = new PrivacyAttack();
    }

    function testWrongKeyStaysLocked() public {
        vm.expectRevert("Wrong key");
        level.unlock(bytes16(keccak256("wrong")));
        assertTrue(level.locked());
    }

    function testPrivacyExploitReadsPackedSlot() public {
        bytes32 slot5 = vm.load(address(level), bytes32(uint256(5)));
        bytes16 recovered = bytes16(slot5);
        assertEq(recovered, key);
        attack.attack(level, recovered);
        assertFalse(level.locked());
    }

    function testFuzz_RecoveredKeyUnlocks(bytes32 candidate) public {
        bytes32 slot5 = vm.load(address(level), bytes32(uint256(5)));
        bytes16 recovered = bytes16(slot5);
        vm.assume(bytes16(candidate) != recovered);
        vm.expectRevert("Wrong key");
        level.unlock(bytes16(candidate));
        assertTrue(level.locked());
        attack.attack(level, recovered);
        assertFalse(level.locked());
    }
}

contract PrivacyControlTest is Test {
    function testStartsLocked() public {
        bytes32[3] memory data;
        EthernautPrivacy level = new EthernautPrivacy(data);
        assertTrue(level.locked());
    }
}

// end

