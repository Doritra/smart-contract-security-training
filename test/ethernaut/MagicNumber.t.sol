// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautMagicNum, MagicNumAttack} from "../../src/ethernaut/MagicNumber.sol";

contract MagicNumberTest is Test {
    EthernautMagicNum level;
    MagicNumAttack attack;

    function setUp() public {
        level = new EthernautMagicNum();
        attack = new MagicNumAttack();
    }

    function testSolverReturns42() public {
        address solver = attack.deploy();
        uint256 runtimeSize;
        assembly {
            runtimeSize := extcodesize(solver)
        }
        assertLe(runtimeSize, 10);
        (bool ok, bytes memory data) = solver.staticcall("");
        assertTrue(ok);
        assertEq(abi.decode(data, (uint256)), 42);
    }

    function testMagicNumberExploit() public {
        address solver = attack.deploy();
        level.setSolver(solver);
        assertEq(level.solver(), solver);
    }
}

contract MagicNumberControlTest is Test {
    function testStartsWithoutSolver() public {
        EthernautMagicNum level = new EthernautMagicNum();
        assertEq(level.solver(), address(0));
    }
}

// end

