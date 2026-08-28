// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import {ForgerToken, ForgerAttack} from "../../src/ethernaut2025/Forger.sol";

contract ForgerTest is Test {
    ForgerToken token;
    ForgerAttack attack;

    function setUp() public {
        token = new ForgerToken();
        attack = new ForgerAttack();
    }

    function testForgerExploit() public {
        attack.attack(token);
        assertGt(token.totalSupply(), 100 ether);
    }
}

contract ForgerControlTest is Test {
    function testSupplyStartsZero() public {
        ForgerToken token = new ForgerToken();
        assertEq(token.totalSupply(), 0);
    }
}

// end

