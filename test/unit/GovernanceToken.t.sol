// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GovernanceToken} from "../../contracts/token/GovernanceToken.sol";

contract GovernanceTokenTest is Test {
    GovernanceToken internal token;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = address(0xB0B);
    address internal spender = makeAddr("spender");

    uint256 internal constant ALICE_PK = 0xA11CE;
    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        token = new GovernanceToken(owner);
        vm.prank(owner);
        token.mint(alice, INITIAL_SUPPLY);
    }

    function testMetadata() public view {
        assertEq(token.name(), "DeFiHub Governance Token");
        assertEq(token.symbol(), "DFH");
        assertEq(token.decimals(), 18);
    }

    function testMintOnlyOwner() public {
        vm.prank(owner);
        token.mint(bob, 100 ether);
        assertEq(token.balanceOf(bob), 100 ether);
    }

    function testRevertMintWhenNotOwner() public {
        vm.prank(bob);
        vm.expectRevert();
        token.mint(bob, 1 ether);
    }

    function testTransfer() public {
        vm.prank(alice);
        token.transfer(bob, 250 ether);
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - 250 ether);
        assertEq(token.balanceOf(bob), 250 ether);
    }

    function testDelegateSelfActivatesVotes() public {
        assertEq(token.getVotes(alice), 0);

        vm.prank(alice);
        token.delegate(alice);

        assertEq(token.getVotes(alice), INITIAL_SUPPLY);
        assertEq(token.delegates(alice), alice);
    }

    function testDelegateToOtherAccount() public {
        vm.prank(alice);
        token.delegate(bob);

        assertEq(token.delegates(alice), bob);
        assertEq(token.getVotes(bob), INITIAL_SUPPLY);
        assertEq(token.getVotes(alice), 0);
    }

    function testTransferUpdatesDelegatedVotes() public {
        uint256 transferAmount = 400 ether;

        vm.prank(alice);
        token.delegate(bob);

        vm.prank(alice);
        token.transfer(bob, transferAmount);

        assertEq(token.getVotes(bob), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - transferAmount);
    }

    function testPermitSetsAllowance() public {
        address holder = vm.addr(ALICE_PK);

        vm.prank(owner);
        token.mint(holder, 10 ether);

        uint256 value = 5 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(holder);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                holder,
                spender,
                value,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, digest);

        token.permit(holder, spender, value, deadline, v, r, s);
        assertEq(token.allowance(holder, spender), value);
    }

    function testPermitAndTransferFrom() public {
        address holder = vm.addr(ALICE_PK);

        vm.prank(owner);
        token.mint(holder, 10 ether);

        uint256 value = 7 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(holder);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                holder,
                spender,
                value,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, digest);

        token.permit(holder, spender, value, deadline, v, r, s);

        vm.prank(spender);
        token.transferFrom(holder, bob, value);

        assertEq(token.balanceOf(bob), value);
        assertEq(token.balanceOf(holder), 10 ether - value);
    }

    function testRevertPermitWithExpiredDeadline() public {
        address holder = vm.addr(ALICE_PK);

        vm.prank(owner);
        token.mint(holder, 1 ether);

        uint256 deadline = block.timestamp - 1;
        uint256 nonce = token.nonces(holder);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                holder,
                spender,
                1 ether,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, digest);

        vm.expectRevert();
        token.permit(holder, spender, 1 ether, deadline, v, r, s);
    }
}
