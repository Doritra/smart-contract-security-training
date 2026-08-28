// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface INotify {
    function notify(uint256 amount) external;
}

contract GoodSamaritan {
    address public wallet;
    address public coin;

    constructor(address wallet_, address coin_) {
        wallet = wallet_;
        coin = coin_;
    }

    function requestDonation() external returns (bool enoughBalance) {
        address caller = msg.sender;
        uint256 amount = 10;
        (bool ok,) = coin.call(abi.encodeWithSignature("transfer(address,uint256)", caller, amount));
        if (ok) {
            return true;
        }
        // If the transfer fails, the wallet is notified and remainder is sent.
        (bool notified,) = wallet.call(abi.encodeWithSignature("notify(uint256)", amount));
        if (notified) {
            (bool ok2,) = wallet.call(abi.encodeWithSignature("transfer(address,uint256)", caller, 100));
            require(ok2, "remainder failed");
            return false;
        }
        return false;
    }
}

contract GoodSamaritanWallet {
    address public coin;

    constructor(address coin_) {
        coin = coin_;
    }

    function notify(uint256 amount) external {
        // Only forwards to the coin's notify, which reverts when amount > 10.
        (bool ok,) = coin.call(abi.encodeWithSignature("notify(uint256)", amount));
        if (!ok) revert("notify failed");
    }

    function transfer(address to, uint256 amount) external {
        (bool ok,) = coin.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        require(ok, "wallet transfer failed");
    }
}

contract GoodSamaritanCoin {
    mapping(address => uint256) public balances;
    address public wallet;
    address public owner;

    constructor(address wallet_) {
        wallet = wallet_;
        owner = msg.sender;
    }

    function notify(uint256 amount) external {
        require(amount <= 10, "amount too big");
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "insufficient");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }

    function setBalance(address who, uint256 amount) external {
        balances[who] = amount;
    }
}

contract GoodSamaritanAttack {
    function attack(GoodSamaritan sam) external {
        sam.requestDonation();
    }
}

// Local training fixture: requestDonation's fallback path sends a 100-token
// remainder whenever the initial 10-token transfer fails.

