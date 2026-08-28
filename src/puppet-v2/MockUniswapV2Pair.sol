// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// MockUniswapV2Pair.sol - Mock Uniswap V2 Pair untuk Testing
contract MockUniswapV2Pair is Ownable {
    IERC20 public token0;
    IERC20 public token1;
    
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public blockTimestampLast;
    
    event Sync(uint256 reserve0, uint256 reserve1);
    
    constructor(address _token0, address _token1) Ownable(msg.sender) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }
    
    // Override getReserves untuk bypass pairFor
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) {
        return (reserve0, reserve1, blockTimestampLast);
    }
    
    function setReserves(uint256 _reserve0, uint256 _reserve1) external onlyOwner {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = block.timestamp;
        emit Sync(reserve0, reserve1);
    }
    
    function mint(address to) external onlyOwner {
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);
        reserve0 += amount0;
        reserve1 += amount1;
        emit Sync(reserve0, reserve1);
    }
}