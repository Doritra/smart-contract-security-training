// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

contract DoubleEntryPoint {
    mapping(address => uint256) public balances;
    mapping(address => address) public bot;
    address public player;

    constructor() {
        player = msg.sender;
    }

    function setDetectionBot(address bot_) external {
        bot[msg.sender] = bot_;
    }

    function transfer(address to, uint256 value) external {
        balances[msg.sender] -= value;
        balances[to] += value;
        // Detection bot hook: only fires when msg.sender is the vault.
        if (bot[msg.sender] != address(0)) {
            IDetectionBot(bot[msg.sender]).handleTransaction(msg.sender, msg.data);
        }
    }

    function setBalance(address who, uint256 amount) external {
        balances[who] = amount;
    }
}

contract CryptoVault {
    DoubleEntryPoint public underlying;
    address public player;

    constructor(DoubleEntryPoint underlying_) {
        underlying = underlying_;
        player = msg.sender;
    }

    function sweepToken(address token) external {
        // Only the vault's owner may sweep, but any token can be targeted.
        require(msg.sender == player, "not owner");
        underlying.transfer(player, underlying.balances(address(this)));
    }
}

contract FortaBot {
    address public owner;
    mapping(address => bool) public alerted;

    constructor() {
        owner = msg.sender;
    }

    function handleTransaction(address user, bytes calldata msgData) external {
        // Only reacts to direct transfers from the vault.
        alerted[user] = true;
    }
}

contract DoubleEntryAttack {
    function drain(CryptoVault vault) external {
        vault.sweepToken(address(vault.underlying()));
    }
}

// Local training fixture: the vault's sweepToken lets the underlying token be
// drained; the detection bot only sees msg.sender, so a reentrant-style call
// from the vault itself can bypass it.

