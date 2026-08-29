// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CooldownVaultClaimFixture } from "../../src/audit/CooldownVaultClaimFixture.sol";

/**
 * @title CooldownVaultInvariantTest
 * @notice Invariant testing dengan handler-based fuzzing terhadap CooldownVaultClaimFixture.
 *         Latihan: nemu bug yang kelewat analisis manual — invariant fuzzing.
 *
 * Invariant yang diuji:
 *   I1. accClaimedAmount <= total yang direquest (over-credit melanggar: recorded > requested)
 *   I2. totalLockedAssets <= total yang direquest (locked ngggak boleh melebih request)
 *   I3. FIFO fairness: total payout per receiver <= total request per receiver
 *         (partial-claim full-credit bikin accClaimedAmount over-credit -> request baru
 *          bisa overtake -> payout melebihi yang seharusnya)
 *
 * Handler: depositAssets (naikkan managed), requestRedeem (tambah request),
 *          claim (partial/full claim), setActualBalance (simulasi backing).
 */
contract CooldownVaultHandler is Test {
    CooldownVaultClaimFixture public vault;
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);
    address public carol = address(0xC4A01);

    uint256 public totalRequested;
    uint256 public totalPayout; // akumulasi assetsOut aktual
    mapping(address => uint256) public payoutPerUser;

    constructor(CooldownVaultClaimFixture _vault) {
        vault = _vault;
    }

    function depositAssets(uint256 amount) external {
        amount = bound(amount, 1, 10); // sangat kecil — partial claim hampir pasti
        vault.depositAssets(amount);
        vault.setActualBalance(vault._managedAssets()); // backing cukup
    }

    function requestRedeem(uint256 assets) external {
        assets = bound(assets, 50, 100); // besar relatif ke deposit (1-50)
        address recv = _pickUser();
        vault.requestRedeem(assets, recv);
        totalRequested += assets;
    }

    function claim(uint256 requestId) external {
        // claim request yang valid (1..lastRequestId)
        uint256 last = vault.lastRequestId();
        if (last == 0) return;
        requestId = bound(requestId, 1, last);
        (string memory reason, uint256 assetsOut) = vault.claim(requestId, 0);
        if (bytes(reason).length == 0) {
            totalPayout += assetsOut;
            // track per receiver — cari receiver request
            // fixture nggak expose receiver per id, jadi track global
        }
    }

    function _pickUser() internal view returns (address) {
        uint256 r = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, totalRequested))) % 3;
        if (r == 0) return alice;
        if (r == 1) return bob;
        return carol;
    }

    // ghost: total payout nggak boleh > total requested
    function ghost_payout_leq_requested() external view returns (bool) {
        return totalPayout <= totalRequested;
    }
}

contract CooldownVaultInvariantTest is Test {
    CooldownVaultClaimFixture internal vault;
    CooldownVaultHandler internal handler;

    function setUp() public {
        vault = new CooldownVaultClaimFixture();
        handler = new CooldownVaultHandler(vault);
        targetContract(address(handler));
    }

    /// @notice I1: accClaimedAmount (recorded) nggak boleh > total yang direquest
    function invariant_accClaimed_leq_totalRequested() public view {
        uint256 accClaimed = vault.accClaimedAmount();
        uint256 requested = vault.accRedeemRequestedAmount(vault.lastRequestId());
        // accClaimedAmount = akumulasi FULL request.assets (over-credit kalau partial)
        // requested = akumulasi semua request
        // Invariant: accClaimed <= requested
        assertLe(accClaimed, requested, "I1 VIOLATED: accClaimedAmount > total requested (over-credit)");
    }

    /// @notice I2: totalLockedAssets nggak boleh > total requested (locked = sisa belum dibayar)
    function invariant_locked_leq_totalRequested() public view {
        uint256 locked = vault.totalLockedAssets();
        uint256 requested = vault.accRedeemRequestedAmount(vault.lastRequestId());
        // totalLockedAssets -= request.assets (FULL) saat claim, padahal cuma assetsOut dibayar
        // -> locked bisa jadi 0 lebih cepat dari yang seharusnya (bukan underflow di fixture,
        //    tapi drift: locked < sisa yang beneran belum dibayar)
        assertLe(locked, requested, "I2 VIOLATED: totalLockedAssets > total requested");
    }

    /// @notice I3: total payout aktual (ghost) nggak boleh > total requested
    function invariant_payout_leq_requested() public view {
        assertTrue(
            handler.ghost_payout_leq_requested(),
            "I3 VIOLATED: total payout > total requested (FIFO overtake)"
        );
    }

    /// @notice I4: accClaimedAmount (recorded) nggak boleh > total payout aktual
    ///         INI yang dilanggar over-credit: accClaimedAmount += request.assets (FULL)
    ///         padahal cuma assetsOut dibayar -> recorded > actual
    function invariant_accClaimed_leq_payout() public view {
        uint256 accClaimed = vault.accClaimedAmount();
        uint256 actualPayout = handler.totalPayout();
        assertLe(
            accClaimed,
            actualPayout,
            "I4 VIOLATED: accClaimedAmount > actual payout (over-credit)"
        );
    }
}
