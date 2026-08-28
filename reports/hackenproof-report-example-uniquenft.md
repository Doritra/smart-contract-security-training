# [Medium] UniqueNFT: EIP-7702 delegation turns the "EOA-only" mint into a reentrancy hole

## Summary
Target: `UniqueNFT` (Ethernaut 2025 UniqueNFT level, local training fixture).
`mintNFTEOA` assumes `tx.origin == msg.sender` means the caller is a plain EOA that cannot reenter. Under EIP-7702 an EOA can carry contract code, so `msg.sender` is an EOA *and* executes arbitrary code. The `onERC721Received` callback (invoked before `_mint`, while the balance is still 0) reenters `mintNFTEOA` and mints unlimited NFTs.

## Severity
**Medium** — the "one NFT per address" invariant is broken; an attacker can mint unlimited NFTs (here: 4 from a single call). No funds are stolen directly, but the asset's scarcity/utility is destroyed.

## Vulnerability Details
```solidity
function mintNFTEOA() external returns (uint256) {
    require(tx.origin == msg.sender, "not an EOA"); // assumed safe
    return _mintNFT();
}
function _mintNFT() private returns (uint256) {
    require(balanceOf(msg.sender) == 0, "only one unique NFT allowed");
    uint256 _tokenId = tokenId++;
    ERC721Utils.checkOnERC721Received(address(0), address(0), msg.sender, _tokenId, "");
    _mint(msg.sender, _tokenId);
}
```
`checkOnERC721Received(..., to = msg.sender, ...)` calls `onERC721Received` on `msg.sender` **before** `_mint`. With EIP-7702, `msg.sender` (an EOA) can have code whose `onERC721Received` reenters `mintNFTEOA`. Because the reentrant call happens before `_mint`, `balanceOf(msg.sender)` is still 0, so the "only one" check passes again — minting another token each round.

## Proof of Concept
```solidity
function testUniqueNFTExploit() public {
    // EIP-7702: give the player EOA the attack contract's code
    vm.etch(player, address(attack).code); // attack.onERC721Received reenters mintNFTEOA
    vm.prank(player, player); // tx.origin == msg.sender == player
    nft.mintNFTEOA();
    assertGt(nft.balanceOf(player), 1); // goal reached (4 in the fixture)
}
```

## Impact
- Unlimited NFT minting by one address → breaks the "one badge per address" invariant.
- In a real protocol: unlimited claim of scarce assets, rewards, or access-gated benefits.

## Recommendation / Fix
1. Don't rely on `tx.origin == msg.sender` as an EOA/anti-reentrancy guarantee (EIP-7702 makes it false).
2. Move the balance check **after** `_mint` (or use a reentrancy guard on `mintNFTEOA`), and/or mint with `_mint` instead of the callback-invoking path.

## References
- EIP-7702 (set EOA account code).
- Reentrancy via `onERC721Received` / ERC-721 callback class.
