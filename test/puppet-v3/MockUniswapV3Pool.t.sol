// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {MockUniswapV3Pool} from "../../src/puppet-v3/MockUniswapV3Pool.sol";

contract MockUniswapV3PoolTest is Test {
    function testReturnsConfiguredPoolValues() public {
        MockUniswapV3Pool pool = new MockUniswapV3Pool(address(1), address(2), 500);
        (uint160 price, int24 tick,,,, bool unlocked) = pool.slot0();
        assertEq(price, uint160(2 ** 96));
        assertEq(tick, 0);
        assertTrue(unlocked);
        (uint160 immutablePrice, int24 spacing,) = pool.getPoolImmutables();
        assertEq(immutablePrice, uint160(2 ** 96));
        assertEq(spacing, 1);
    }
}
