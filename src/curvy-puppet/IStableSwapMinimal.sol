// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface IStableSwapMinimal {
    function lp_token() external view returns (address);
    function coins(uint256 arg0) external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}
