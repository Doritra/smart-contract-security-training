// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EthernautNaughtCoin is IERC20 {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public totalSupply = INITIAL_SUPPLY;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = INITIAL_SUPPLY;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "insufficient");
        require(to != address(0), "zero");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "insufficient");
        require(allowance[from][msg.sender] >= value, "allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function lockTokens(address who) external onlyOwner {
        // In the real challenge the lock is enforced in transfer().
        // This fixture models the same lock by requiring owner for a direct unlock.
        require(who == owner, "not owner");
    }
}

contract NaughtCoinAttack {
    function drain(IERC20 token, address from, address to, uint256 amount) external {
        token.transferFrom(from, to, amount);
    }
}

// Local training fixture: the 10-year lock is applied only on transfer(),
// so transferFrom can move tokens without hitting the lock.

