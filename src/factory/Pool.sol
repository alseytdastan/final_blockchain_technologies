// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Pool {
    address public immutable tokenA;
    address public immutable tokenB;
    address public immutable creator;

    constructor(address _tokenA, address _tokenB, address _creator) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        creator = _creator;
    }
}
