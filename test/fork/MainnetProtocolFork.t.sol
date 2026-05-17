// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20Metadata {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract MainnetProtocolForkTest is Test {
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant CHAINLINK_ETH_USD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address internal constant USDC_WHALE = 0x55FE002aefF02F77364de339a1292923A15844B8;

    modifier withMainnetFork() {
        string memory rpcUrl = vm.envOr("MAINNET_RPC_URL", string(""));
        if (bytes(rpcUrl).length == 0) return;
        vm.createSelectFork(rpcUrl);
        _;
    }

    function testFork_USDCMetadataAndBalance() public withMainnetFork {
        IERC20Metadata usdc = IERC20Metadata(USDC);

        assertEq(usdc.decimals(), 6);
        assertGt(usdc.balanceOf(USDC_WHALE), 0);
    }

    function testFork_UniswapV2RouterQuotesWethToUsdc() public withMainnetFork {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        uint256[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(1 ether, path);

        assertEq(amounts.length, 2);
        assertEq(amounts[0], 1 ether);
        assertGt(amounts[1], 0);
    }

    function testFork_ChainlinkEthUsdFeedIsLive() public withMainnetFork {
        IChainlinkFeed feed = IChainlinkFeed(CHAINLINK_ETH_USD);
        (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();

        assertEq(feed.decimals(), 8);
        assertGt(answer, 0);
        assertGt(updatedAt, 0);
    }
}
