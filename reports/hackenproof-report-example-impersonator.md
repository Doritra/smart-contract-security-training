# [High] ECLocker: ECDSA signature malleability bypasses used-signature protection

## Summary
Target: `EthernautImpersonator` (ECLocker) — Ethernaut 2025 Impersonator level (local training fixture).
A used-signature guard (`usedSignatures[keccak256(abi.encode([r,s,v]))]`) can be bypassed by flipping the `s` component of an ECDSA signature (`s → n - s`, `v → 28`). Both signatures recover to the same signer but produce different hash keys, so the "already used" check is defeated and the protected action can be replayed.

## Severity
**High** — the signature replay allows re-executing a signed authorization (e.g. a controller handover) after it was meant to be consumed once.

## Vulnerability Details
The locker validates signatures with:
```solidity
address recovered = ecrecover(msgHash, v, r, s);
require(recovered == controller, "invalid signature");
require(!usedSignatures[keccak256(abi.encode([r, s, v]))], "signature already used");
usedSignatures[keccak256(abi.encode([r, s, v]))] = true;
```
ECDSA is malleable: for any valid `(r, s, v=27)`, the tuple `(r, n-s, 28)` is also valid and recovers to the **same signer** (`n` = secp256k1 order). Because the guard hashes the *encoded signature bytes* rather than the *message hash*, the malleated signature produces a different `keccak256` key and is not flagged as used.

## Proof of Concept
```solidity
function testImpersonatorExploit() public {
    // factory-provided signature (r, s, v) recovers to the controller
    // malleate: s' = n - s, v' = 28
    bytes32 sMalleated = bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - uint256(s));
    bytes memory malleatedSig = abi.encodePacked(r, sMalleated, uint8(28));

    locker.setController(malleatedSig, address(0)); // replay succeeds
    assertEq(locker.controller(), address(0));       // goal reached
}
```
Before: `controller = 0x43af...` (factory-set). After: `controller = address(0)` — the authorization was replayed despite the used-signature guard.

## Impact
- Replay of one-time authorizations (controller handover, approvals, withdrawal permits).
- In a real protocol this can re-execute a signed action that should be single-use, e.g. re-approve a malicious spender or re-claim a reward.

## Recommendation / Fix
Enforce **low-s** signatures (reject `s > n/2`) — the standard ECDSA malleability fix — and/or key the used-guard on the **message hash** (`msgHash`) instead of the encoded signature bytes.

## References
- OZ 4.6 `ECDSA.recover` does not enforce low-s; OZ 5.x does.
- CVE-2021-... (ECDSA malleability class).
