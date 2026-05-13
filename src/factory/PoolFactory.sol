// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Pool} from "./Pool.sol";

contract PoolFactory {
    event PoolCreated(address indexed pool, address indexed tokenA, address indexed tokenB, bytes32 salt);

    function createPool(address tokenA, address tokenB) external returns (address pool) {
        pool = address(new Pool(tokenA, tokenB, msg.sender));
        emit PoolCreated(pool, tokenA, tokenB, bytes32(0));
    }

    function createPoolDeterministic(address tokenA, address tokenB, bytes32 salt) external returns (address pool) {
        pool = address(new Pool{salt: salt}(tokenA, tokenB, msg.sender));
        emit PoolCreated(pool, tokenA, tokenB, salt);
    }

    function predictDeterministicAddress(
        address tokenA,
        address tokenB,
        address creator,
        bytes32 salt
    ) external view returns (address predicted) {
        bytes memory bytecode = abi.encodePacked(type(Pool).creationCode, abi.encode(tokenA, tokenB, creator));
        bytes32 codeHash = keccak256(bytecode);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, codeHash));
        predicted = address(uint160(uint256(hash)));
    }
}
