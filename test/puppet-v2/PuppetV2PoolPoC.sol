// SPDX-License-Identifier: MIT
// PoC version - bypass oracle for testing
pragma solidity =0.8.25;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

contract PuppetV2PoolPoC {
    IERC20 private _token;
    IERC20 private _weth;

    mapping(address => uint256) public deposits;

    event Borrowed(address indexed borrower, uint256 depositRequired, uint256 borrowAmount, uint256 timestamp);

    constructor(address wethAddress, address tokenAddress) {
        _weth = IERC20(wethAddress);
        _token = IERC20(tokenAddress);
    }

    // Bypass oracle - fixed deposit factor for PoC
    function borrow(uint256 borrowAmount) external {
        uint256 amount = borrowAmount * 3; // Fixed 3x deposit

        // VULNERABILITY: External call BEFORE state update
        _weth.transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender] += amount;

        require(_token.transfer(msg.sender, borrowAmount), "Transfer failed");

        emit Borrowed(msg.sender, amount, borrowAmount, block.timestamp);
    }
}
