// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautVault, VaultAttack} from "../../src/ethernaut/Vault.sol";

contract VaultTest is Test {
    EthernautVault level;
    VaultAttack attack;
    bytes32 password = keccak256("local-training-password");
    address player = makeAddr("player");

    function setUp() public {
        level = new EthernautVault(password);
        attack = new VaultAttack();
    }

    function testWrongPasswordDoesNotUnlock() public {
        level.unlock(bytes32(0));
        assertTrue(level.locked());
    }

    function testVaultExploitReadsPrivateSlot() public {
        bytes32 recovered = vm.load(address(level), bytes32(uint256(1)));
        vm.prank(player);
        attack.attack(level, recovered);
        assertFalse(level.locked());
    }

    function testFuzz_RecoveredSlotUnlocks(bytes32 candidate) public {
        bytes32 recovered = vm.load(address(level), bytes32(uint256(1)));
        vm.assume(candidate != recovered);
        level.unlock(candidate);
        assertTrue(level.locked());
        level.unlock(recovered);
        assertFalse(level.locked());
    }
}

contract VaultControlTest is Test {
    function testLockedByDefault() public {
        EthernautVault level = new EthernautVault(bytes32(uint256(123)));
        assertTrue(level.locked());
    }
}

// end


