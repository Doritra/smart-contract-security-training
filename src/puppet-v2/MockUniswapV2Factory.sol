// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./MockUniswapV2Pair.sol";

// MockUniswapV2Factory.sol - Mock Factory untuk Testing
contract MockUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;
    
    mapping(address => mapping(address => address)) public getPair;
    
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    
    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }
    
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Identical addresses");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), "Pair already exists");
        pair = address(new MockUniswapV2Pair(tokenA, tokenB));
        getPair[token0][token1] = pair;
        emit PairCreated(token0, token1, pair, 1);
    }
}