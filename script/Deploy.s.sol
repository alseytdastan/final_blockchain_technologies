// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {AMMPool} from "../contracts/amm/AMMPool.sol";
import {PoolFactory} from "../contracts/amm/PoolFactory.sol";
import {ProtocolGovernor} from "../contracts/governance/ProtocolGovernor.sol";
import {ProtocolTimelock} from "../contracts/governance/ProtocolTimelock.sol";
import {ProtocolTreasury} from "../contracts/governance/ProtocolTreasury.sol";
import {LendingPool} from "../contracts/lending/LendingPool.sol";
import {MockERC20} from "../contracts/mocks/MockERC20.sol";
import {ChainlinkPriceFeed} from "../contracts/oracle/ChainlinkPriceFeed.sol";
import {MockV3Aggregator} from "../contracts/oracle/MockV3Aggregator.sol";
import {GovernanceToken} from "../contracts/token/GovernanceToken.sol";
import {ProtocolAccessNFT} from "../contracts/token/ProtocolAccessNFT.sol";
import {UpgradeableProtocolConfig} from "../contracts/upgradeable/UpgradeableProtocolConfig.sol";
import {YieldVault} from "../contracts/vault/YieldVault.sol";

contract Deploy is Script {
    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 internal constant INITIAL_LIQUIDITY = 10_000 ether;
    uint256 internal constant GOVERNANCE_SUPPLY = 100_000 ether;
    uint256 internal constant CHAINLINK_MAX_STALENESS = 1 days;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    GovernanceToken internal governanceToken;
    ProtocolTimelock internal timelock;
    ProtocolGovernor internal governor;
    ProtocolTreasury internal treasury;
    MockV3Aggregator internal mockEthUsd;
    ChainlinkPriceFeed internal oracle;
    PoolFactory internal factory;
    AMMPool internal pool;
    YieldVault internal vault;
    LendingPool internal lendingPool;
    ProtocolAccessNFT internal badge;
    UpgradeableProtocolConfig internal implementation;
    ERC1967Proxy internal configProxy;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        _deployTokens(deployer);
        _deployGovernance(deployer);
        _deployOracle();
        _deployAmm();
        _deployVaultAndLending();
        _deployUpgradeableConfig();
        governanceToken.transferOwnership(address(timelock));
        _logAddresses(deployer);

        vm.stopBroadcast();
    }

    function _deployTokens(address deployer) internal {
        tokenA = new MockERC20("Mock USD Coin", "mUSDC");
        tokenB = new MockERC20("Mock Wrapped Ether", "mWETH");
        tokenA.mint(deployer, INITIAL_SUPPLY);
        tokenB.mint(deployer, INITIAL_SUPPLY);
    }

    function _deployGovernance(address deployer) internal {
        governanceToken = new GovernanceToken(deployer);
        governanceToken.mint(deployer, GOVERNANCE_SUPPLY);
        governanceToken.delegate(deployer);

        address[] memory empty = new address[](0);
        address[] memory openExecutor = new address[](1);
        openExecutor[0] = address(0);
        timelock = new ProtocolTimelock(2 days, empty, openExecutor, deployer);
        governor = new ProtocolGovernor(governanceToken, timelock);
        treasury = new ProtocolTreasury(address(timelock));

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), deployer);
    }

    function _deployOracle() internal {
        mockEthUsd = new MockV3Aggregator(8, 2_000e8);
        oracle = new ChainlinkPriceFeed(address(mockEthUsd), CHAINLINK_MAX_STALENESS);
    }

    function _deployAmm() internal {
        factory = new PoolFactory();
        address poolAddress = factory.createPool(address(tokenA), address(tokenB));
        pool = AMMPool(poolAddress);
        tokenA.approve(poolAddress, INITIAL_LIQUIDITY);
        tokenB.approve(poolAddress, INITIAL_LIQUIDITY);
        pool.addLiquidity(INITIAL_LIQUIDITY, INITIAL_LIQUIDITY, 0, 0);
    }

    function _deployVaultAndLending() internal {
        vault = new YieldVault(tokenA, address(timelock));
        lendingPool = new LendingPool(
            address(tokenB), address(tokenA), address(oracle), address(timelock), 7_500, 8_000, 1_000, 500
        );
        tokenA.mint(address(lendingPool), 250_000 ether);

        badge = new ProtocolAccessNFT(address(timelock));
    }

    function _deployUpgradeableConfig() internal {
        implementation = new UpgradeableProtocolConfig();
        bytes memory initData = abi.encodeCall(UpgradeableProtocolConfig.initialize, (address(timelock), 30, "DeFiHub"));
        configProxy = new ERC1967Proxy(address(implementation), initData);
    }

    function _logAddresses(address deployer) internal view {
        console2.log("deployer", deployer);
        console2.log("tokenA", address(tokenA));
        console2.log("tokenB", address(tokenB));
        console2.log("governanceToken", address(governanceToken));
        console2.log("timelock", address(timelock));
        console2.log("governor", address(governor));
        console2.log("treasury", address(treasury));
        console2.log("mockEthUsd", address(mockEthUsd));
        console2.log("oracle", address(oracle));
        console2.log("factory", address(factory));
        console2.log("pool", address(pool));
        console2.log("lpToken", address(pool.lpToken()));
        console2.log("vault", address(vault));
        console2.log("lendingPool", address(lendingPool));
        console2.log("badge", address(badge));
        console2.log("configImplementation", address(implementation));
        console2.log("configProxy", address(configProxy));
    }
}
