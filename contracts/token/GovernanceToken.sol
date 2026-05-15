// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GovernanceToken {
    string public constant name = "DeFiHub Governance Token";
    string public constant symbol = "DFH";
    uint8 public constant decimals = 18;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public immutable owner;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(address initialOwner) {
        owner = initialOwner;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "ONLY_OWNER");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
