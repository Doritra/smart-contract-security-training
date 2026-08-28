// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import {BetHouse, Pool, PoolToken, BetHouseAttack} from "../../src/ethernaut2025/BetHouse.sol";

contract BetHouseTest is Test {
    BetHouse betHouse;
    Pool pool;
    PoolToken wrapped;
    PoolToken pdt;
    BetHouseAttack attack;
    address player = makeAddr("player");

    function setUp() public {
        wrapped = new PoolToken("Wrapped", "W");
        pdt = new PoolToken("PDT", "P");
        pool = new Pool(address(wrapped), address(pdt));
        betHouse = new BetHouse(address(pool));
        attack = new BetHouseAttack();
    }

    function testBetHouseExploit() public {
        vm.deal(address(attack), 0.001 ether);
        attack.attack{value: 0.001 ether}(betHouse, pool, pdt, wrapped, player);
        assertTrue(betHouse.isBettor(player));
    }
}

contract BetHouseControlTest is Test {
    function testNotBettorInitially() public {
        BetHouse betHouse = new BetHouse(address(1));
        assertFalse(betHouse.isBettor(makeAddr("x")));
    }
}

// end

