// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CooldownVaultClaimFixture } from "../../src/audit/CooldownVaultClaimFixture.sol";

/**
 * @title CooldownVaultFIFOTest
 * @notice Bukti partial-claim full-credit bug di CooldownVault._claim()
 *         Pola asli: accClaimedAmount += request.assets (FULL) padahal cuma assetsOut dibayar.
 *         Dampak: reservedForPriorRequests jadi over-kecil → request baru bisa overtake FIFO.
 */
contract CooldownVaultFIFOTest is Test {
    CooldownVaultClaimFixture vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vault = new CooldownVaultClaimFixture();
    }

    /// @notice Skenario dasar: partial claim over-credit accClaimedAmount
    function test_PartialClaimOvercreditsAccClaimed() public {
        // Alice request 100, vault kosong
        vault.requestRedeem(100, alice); // requestId 1
        assertEq(vault.accClaimedAmount(), 0);

        // Vault dapat 50 (strategy repay)
        vault.depositAssets(50);

        // Alice claim partial 50 (reservedForPrior=0, jadi partial claim lolos)
        (string memory reason, uint256 assetsOut) = vault.claim(1, 0);
        assertEq(reason, "");
        assertEq(assetsOut, 50);

        // BUG: accClaimedAmount = 100 (FULL) padahal cuma 50 dibayar
        // Seharusnya 50 (actual payout), tapi over-credit 50
        assertEq(vault.accClaimedAmount(), 100, "BUG: over-credit accClaimedAmount");
        emit log_named_uint("accClaimedAmount (actual 50, recorded)", vault.accClaimedAmount());
    }

    /// @notice Dampak FIFO: Bob overtake Alice karena accClaimedAmount over-credit
    function test_BobOvertakesAliceViaOvercredit() public {
        // Alice request 100 (id 1), vault kosong
        vault.requestRedeem(100, alice);
        // Bob request 100 (id 2)
        vault.requestRedeem(100, bob);

        // Vault dapat 50
        vault.depositAssets(50);

        // Alice claim partial 50 -> accClaimedAmount = 100 (FULL, over-credit)
        (string memory reasonA, uint256 aliceOut) = vault.claim(1, 0);
        assertEq(reasonA, "");
        assertEq(aliceOut, 50);

        // Vault dapat 50 lagi (total managed = 50)
        vault.depositAssets(50);

        // Bob claim: reservedForPrior = accRequested[1] - accClaimed = 100 - 100 = 0
        // (seharusnya 100 - 50 = 50, karena Alice belum dapat 50 sisanya)
        (string memory reasonB, uint256 bobOut) = vault.claim(2, 0);
        assertEq(reasonB, "");
        emit log_named_uint("Bob payout (seharusnya 0, Alice belum lunas)", bobOut);

        // BUG: Bob dapat 50, padahal 50 itu harusnya reserve buat Alice
        // Alice total dapat 50 dari 100, Bob dapat 50 dari 100 -> total 100, tapi
        // accClaimedAmount = 200 (Alice 100 + Bob 100) padahal cuma 100 dibayar
        assertEq(bobOut, 50, "BUG: Bob overtake Alice via over-credit accClaimedAmount");
        emit log_named_uint("accClaimedAmount (actual 100, recorded)", vault.accClaimedAmount());
    }

    /// @notice Invariant: totalAssets tidak boleh underflow dari over-credit
    function test_TotalAssetsUnderflowRisk() public {
        vault.requestRedeem(100, alice);
        vault.depositAssets(50);
        vault.claim(1, 0); // partial 50, accClaimed=100, managed=0, locked=0

        // totalAssets = managed(0) - locked(0) = 0 (tidak underflow di fixture)
        // Tapi di kode asli: totalLockedAssets -= request.assets (FULL) padahal
        // cuma assetsOut dibayar -> locked bisa underflow kalau banyak partial claim
        uint256 ta = vault.totalAssets();
        emit log_named_uint("totalAssets", ta);
        assertEq(ta, 0);
    }
}
