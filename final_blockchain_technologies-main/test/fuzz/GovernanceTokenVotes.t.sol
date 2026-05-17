// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GovernanceToken} from "../../contracts/token/GovernanceToken.sol";

contract GovernanceTokenVotesFuzzTest is Test {
    GovernanceToken internal token;
    address internal owner = address(0xDEAD);

    function setUp() public {
        token = new GovernanceToken(owner);
    }

    function testFuzz_MintAndSelfDelegateMatchesVotes(uint96 amount) public {
        amount = uint96(bound(amount, 1, type(uint208).max));

        address holder = makeAddr("holder");

        vm.prank(owner);
        token.mint(holder, amount);

        vm.prank(holder);
        token.delegate(holder);

        assertEq(token.getVotes(holder), amount);
        assertEq(token.balanceOf(holder), amount);
    }
}
