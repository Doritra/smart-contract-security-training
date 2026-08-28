// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface IPermit2Minimal {
    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;
    
    function approve(
        address token,
        address spender,
        uint160 amount,
        uint48 expiration
    ) external;
}
