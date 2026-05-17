// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ProtocolAccessNFT} from "../../contracts/token/ProtocolAccessNFT.sol";

contract ProtocolAccessNFTTest is Test {
    ProtocolAccessNFT internal badge;

    address internal user = makeAddr("user");
    address internal attacker = makeAddr("attacker");

    function setUp() public {
        badge = new ProtocolAccessNFT(address(this));
    }

    function testMetadata() public view {
        assertEq(badge.name(), "DeFiHub Protocol Badge");
        assertEq(badge.symbol(), "DFHB");
    }

    function testOwnerCanMintBadge() public {
        uint256 tokenId = badge.mint(user);

        assertEq(tokenId, 1);
        assertEq(badge.ownerOf(tokenId), user);
        assertEq(badge.nextTokenId(), 2);
    }

    function testMintEmitsBadgeMinted() public {
        vm.expectEmit(true, true, false, true);
        emit ProtocolAccessNFT.BadgeMinted(user, 1);

        badge.mint(user);
    }

    function testRevertMintWhenCallerIsNotOwner() public {
        vm.prank(attacker);
        vm.expectRevert();
        badge.mint(attacker);
    }

    function testTokenUriForMintedBadge() public {
        uint256 tokenId = badge.mint(user);

        assertEq(badge.tokenURI(tokenId), "ipfs://defihub-protocol-badge");
    }

    function testRevertTokenUriForMissingBadge() public {
        vm.expectRevert();
        badge.tokenURI(999);
    }
}
