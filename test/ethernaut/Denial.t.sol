// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {EthernautDenial, DenialPartner, DenialAttack} from "../../src/ethernaut/Denial.sol";
contract DenialTest is Test {
    EthernautDenial level;
    DenialAttack attack;

    function setUp() public {
        level = new EthernautDenial{value: 1 ether}();
        attack = new DenialAttack();
    }

    receive() external payable {}

    function testNormalPartnerReceivesShare() public {
        DenialPartner partner = new DenialPartner();
        level.setWithdrawPartner(address(partner));
        uint256 before = address(this).balance;
        level.withdraw();
        assertEq(address(this).balance, before + 0.1 ether);
        assertEq(address(partner).balance, 0.1 ether);
    }

    function testDenialExploitBlocksOwner() public {
        attack.setPartner(level);
        uint256 before = address(this).balance;
        level.withdraw();
        assertEq(address(this).balance, before);
        assertEq(address(level).balance, 1 ether);
    }

    function testFuzz_RepeatedWithdrawStaysBlocked(uint256 seed) public {
        attack.setPartner(level);
        for (uint256 i = 0; i < 5; i++) {
            level.withdraw();
        }
        assertEq(address(level).balance, 1 ether);
    }
}

contract DenialControlTest is Test {
    function testStartsWithOwner() public {
        EthernautDenial level = new EthernautDenial();
        assertEq(level.owner(), address(this));
    }
}

// end

