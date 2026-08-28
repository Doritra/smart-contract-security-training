// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {MotorbikeEngine, Motorbike, MotorbikeAttacker, MotorbikeKiller} from "../../src/ethernaut/Motorbike.sol";

contract MotorbikeTest is Test {
    Motorbike bike;
    MotorbikeEngine engine;
    MotorbikeAttacker attacker;
    address player = makeAddr("player");

    function setUp() public {
        engine = new MotorbikeEngine();
        bike = new Motorbike(address(engine));
        attacker = new MotorbikeAttacker();
    }

    function testMotorbikeExploit() public {
        vm.expectEmit(true, true, true, true, address(engine));
        emit MotorbikeKiller.Killed(address(engine));
        vm.prank(player);
        attacker.attack(engine, player);

        // Engine initialized by the attacker (it is now the only upgrader).
        uint256 upgraderSlot = uint256(vm.load(address(engine), bytes32(0)));
        assertEq(address(uint160(upgraderSlot)), address(attacker));
        // On pre-Cancun EVMs this selfdestruct deletes the engine code. On
        // modern EVMs (EIP-6780) the code survives but the POC still proves
        // the attacker took over the implementation via the missing guard.
    }
}

contract MotorbikeControlTest is Test {
    function testEngineStartsUninitialized() public {
        MotorbikeEngine engine = new MotorbikeEngine();
        assertFalse(engine.initialized());
    }
}

// end

