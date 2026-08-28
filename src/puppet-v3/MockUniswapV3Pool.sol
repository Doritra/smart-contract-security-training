// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

// This lightweight mock is intentionally standalone. PuppetV3Pool's current
// local PoC uses a hardcoded quote and does not require the full Uniswap V3
// interface. Inheriting the upstream interface here would require implementing
// every pool method and would make this unrelated mock block all project builds.
contract MockUniswapV3Pool {
    address public token0;
    address public token1;
    uint24 public fee;
    int24 public tickSpacing;
    int24 public tickCurrent;
    uint128 public liquidity;
    uint256 public sqrtPriceX96 = 2**96; // 1:1 price

    constructor(address _token0, address _token1, uint24 _fee) {
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        tickSpacing = 1;
        tickCurrent = 0;
    }

    // Override functions to return hardcoded values
    function slot0() external view returns (uint160 sqrtPriceX96Out, int24 tick, uint16 observationIndexCardinality, uint16 observationIndexCardinalityNext, uint8 feeProtocol, bool unlocked) {
        return (uint160(sqrtPriceX96), tickCurrent, 0, 0, 0, true);
    }

    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, uint128[] memory secondsPerLiquidityCumulativeX128s) {
        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulativeX128s = new uint128[](secondsAgos.length);
    }

    function getPoolImmutables() external view returns (uint160 sqrtPriceX96Out, int24 tickSpacingOut, int24 maxLiquidityPerTick) {
        return (uint160(sqrtPriceX96), tickSpacing, 0);
    }

    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) external returns (int256 amount0, int256 amount1) {
        revert("Mock: swap not implemented");
    }

    // Required by IUniswapV3Pool but not used in PuppetV3
    function initialize(uint160) external {}
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external {}
    function setFeeProtocol(uint8 feeProtocol) external {}
    function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested) external returns (uint128 amount0, uint128 amount1) {}
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external returns (uint256 amount0Out, uint256 amount1Out) {}
    function ticks(int24 tick) external view returns (uint128 liquidityGross, int128 liquidityNet, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128, int56 tickCumulativeOutside, uint160 secondsPerLiquidityOutsideX128, uint32 secondsOutside, bool initialized) {
        return (0, 0, 0, 0, 0, 0, 0, false);
    }
    
    function tickBitmap(int16 wordPosition) external view returns (uint256) {
        return 0;
    }
}