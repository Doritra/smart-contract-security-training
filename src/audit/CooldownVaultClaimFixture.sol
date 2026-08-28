// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CooldownVaultClaimFixture
 * @notice Fixture minimal yang memodelkan logika _claim() CooldownVault SuperEarn
 *         Fokus: partial-claim full-credit bug (accClaimedAmount += request.assets
 *         padahal cuma assetsOut yang dibayar).
 *
 * Pola asli (src/superearn/core/CooldownVault.sol baris 586-686):
 *   - reservedForPriorRequests = accRequested[reqId-1] - accClaimedAmount
 *   - availableLiquidity = _managedAssets - reservedForPriorRequests
 *   - assetsOut = min(request.assets, availableLiquidity)
 *   - if (reservedForPrior > 0 && assetsOut < request.assets) revert INSUFFICIENT_ASSETS
 *   - request.claimed = true
 *   - totalLockedAssets -= request.assets        // FULL
 *   - accClaimedAmount += request.assets         // FULL  <-- BUG: over-credit
 *   - _decreaseManagedAssets(assetsOut)          // partial
 */
contract CooldownVaultClaimFixture {
    uint256 public totalLockedAssets;
    uint256 public accClaimedAmount;
    uint256 public _managedAssets;
    uint256 public lastRequestId;

    mapping(uint256 => uint256) public accRedeemRequestedAmount;
    mapping(uint256 => RedeemRequest) public redeemRequests;

    struct RedeemRequest {
        address receiver;
        uint256 assets;
        bool claimed;
    }

    // === Simulasi deposit (managedAssets naik) ===
    function depositAssets(uint256 amount) external {
        _managedAssets += amount;
    }

    // === Simulasi request redeem ===
    function requestRedeem(uint256 assets, address receiver) external returns (uint256 requestId) {
        unchecked {
            requestId = ++lastRequestId;
        }
        redeemRequests[requestId] = RedeemRequest(receiver, assets, false);
        accRedeemRequestedAmount[requestId] = accRedeemRequestedAmount[requestId - 1] + assets;
        totalLockedAssets += assets;
    }

    // === _claim replika (tanpa cooldown, fokus FIFO + partial claim) ===
    function claim(uint256 requestId, uint256 minAssetsOut)
        external
        returns (string memory reason, uint256 assetsOut)
    {
        RedeemRequest storage request = redeemRequests[requestId];
        if (request.claimed) return ("INVALID", 0);

        uint256 _accRedeemRequestedAmount = accRedeemRequestedAmount[requestId - 1];
        uint256 reservedForPriorRequests =
            _accRedeemRequestedAmount > accClaimedAmount ? _accRedeemRequestedAmount - accClaimedAmount : 0;

        uint256 availableLiquidity =
            _managedAssets > reservedForPriorRequests ? _managedAssets - reservedForPriorRequests : 0;

        assetsOut = request.assets < availableLiquidity ? request.assets : availableLiquidity;

        // FIFO: partial claim diblokir kalau ada prior request
        if (reservedForPriorRequests > 0 && assetsOut < request.assets) {
            return ("INSUFFICIENT_ASSETS", 0);
        }
        if (assetsOut < minAssetsOut) {
            return ("EXCESSIVE_LOSS", assetsOut);
        }

        // Effects
        request.claimed = true;
        totalLockedAssets -= request.assets;   // FULL
        accClaimedAmount += request.assets;    // FULL  <-- over-credit kalau partial
        _managedAssets -= assetsOut;           // partial

        return ("", assetsOut);
    }

    // === View: totalAssets replika (managedAssets + debt - locked) ===
    function totalAssets() external view returns (uint256) {
        if (_managedAssets > totalLockedAssets) {
            return _managedAssets - totalLockedAssets;
        }
        return 0;
    }
}
