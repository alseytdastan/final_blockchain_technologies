// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LPToken {
    string public constant name = "DeFiHub LP Token";
    string public constant symbol = "DFH-LP";
    uint8 public constant decimals = 18;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public immutable pool;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(address initialPool) {
        pool = initialPool;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == pool, "ONLY_POOL");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == pool, "ONLY_POOL");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}
