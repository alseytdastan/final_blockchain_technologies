// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PriceOracle {
    mapping(address => int256) public latestPrice;

    event PriceUpdated(address indexed asset, int256 price);

    function setPrice(address asset, int256 price) external {
        latestPrice[asset] = price;
        emit PriceUpdated(asset, price);
    }
}
