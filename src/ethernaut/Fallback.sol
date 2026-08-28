// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautFallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        contributions[msg.sender] = 1000 ether;
    }

    function contribute() external payable {
        require(msg.value < 0.001 ether, "Contribution too large");
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0, "Not eligible");
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}

