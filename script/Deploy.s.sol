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

/// @notice Deploys the full DeFiHub stack. On L2 testnets uses Chainlink ETH/USD when configured.
contract Deploy is Script {
    uint256 internal constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 internal constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    /// @dev Chainlink ETH/USD on Base Sepolia — https://docs.chain.link/data-feeds/price-feeds/addresses
    address internal constant BASE_SEPOLIA_ETH_USD_FEED = 0x4adc67696B383f06e6B40ab9096c3AA01541a1C0;

    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 internal constant INITIAL_LIQUIDITY = 10_000 ether;
    uint256 internal constant GOVERNANCE_SUPPLY = 100_000 ether;
    uint256 internal constant CHAINLINK_MAX_STALENESS = 1 days;

    address internal deployer;

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
        deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        _deployTokens();
        _deployGovernance();
        _deployOracle();
        _deployAmm();
        _deployVaultAndLending();
        _deployUpgradeableConfig();
        governanceToken.transferOwnership(address(timelock));
        _registerTreasuryModules();
        treasury.transferOwnership(address(timelock));
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), deployer);
        _writeDeploymentArtifact(block.chainid);
        _logAddresses();

        vm.stopBroadcast();
    }

    function _deployTokens() internal {
        tokenA = new MockERC20("Mock USD Coin", "mUSDC");
        tokenB = new MockERC20("Mock Wrapped Ether", "mWETH");
        tokenA.mint(deployer, INITIAL_SUPPLY);
        tokenB.mint(deployer, INITIAL_SUPPLY);
    }

    function _deployGovernance() internal {
        governanceToken = new GovernanceToken(deployer);
        governanceToken.mint(deployer, GOVERNANCE_SUPPLY);
        governanceToken.delegate(deployer);

        address[] memory empty = new address[](0);
        address[] memory openExecutor = new address[](1);
        openExecutor[0] = address(0);
        timelock = new ProtocolTimelock(2 days, empty, openExecutor, deployer);
        governor = new ProtocolGovernor(governanceToken, timelock);
        // Deployer owns treasury during bootstrap so modules can be registered under --broadcast.
        treasury = new ProtocolTreasury(deployer);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
    }

    function _deployOracle() internal {
        address feed = _resolveEthUsdFeed();
        oracle = new ChainlinkPriceFeed(feed, CHAINLINK_MAX_STALENESS);
        console2.log("Using price feed aggregator", feed);
    }

    function _resolveEthUsdFeed() internal returns (address feed) {
        if (block.chainid == BASE_SEPOLIA_CHAIN_ID) {
            return vm.envOr("CHAINLINK_ETH_USD_FEED", BASE_SEPOLIA_ETH_USD_FEED);
        }

        if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            feed = _envAddressOrZero("CHAINLINK_ETH_USD_FEED");
            if (feed != address(0)) {
                return feed;
            }
            mockEthUsd = new MockV3Aggregator(8, 2_000e8);
            console2.log("CHAINLINK_ETH_USD_FEED unset; deployed MockV3Aggregator for Arbitrum Sepolia");
            return address(mockEthUsd);
        }

        feed = _envAddressOrZero("CHAINLINK_ETH_USD_FEED");
        if (feed != address(0)) {
            return feed;
        }

        mockEthUsd = new MockV3Aggregator(8, 2_000e8);
        return address(mockEthUsd);
    }

    function _envAddressOrZero(string memory key) internal returns (address value) {
        try vm.envAddress(key) returns (address envValue) {
            return envValue;
        } catch {
            return address(0);
        }
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

    function _registerTreasuryModules() internal {
        treasury.registerModule(ProtocolTreasury.Module.AMM, address(pool));
        treasury.registerModule(ProtocolTreasury.Module.Lending, address(lendingPool));
        treasury.registerModule(ProtocolTreasury.Module.Vault4626, address(vault));
        treasury.registerModule(ProtocolTreasury.Module.OracleAdapter, address(oracle));
        treasury.registerModule(ProtocolTreasury.Module.Governance, address(governor));
        treasury.registerModule(ProtocolTreasury.Module.Treasury, address(treasury));
    }

    function _writeDeploymentArtifact(uint256 chainId) internal {
        string memory objectKey = "deployment";
        vm.serializeUint(objectKey, "chainId", chainId);
        vm.serializeAddress(objectKey, "deployer", deployer);
        vm.serializeAddress(objectKey, "tokenA", address(tokenA));
        vm.serializeAddress(objectKey, "tokenB", address(tokenB));
        vm.serializeAddress(objectKey, "governanceToken", address(governanceToken));
        vm.serializeAddress(objectKey, "timelock", address(timelock));
        vm.serializeAddress(objectKey, "governor", address(governor));
        vm.serializeAddress(objectKey, "treasury", address(treasury));
        vm.serializeAddress(objectKey, "mockEthUsd", address(mockEthUsd));
        vm.serializeAddress(objectKey, "oracle", address(oracle));
        vm.serializeAddress(objectKey, "factory", address(factory));
        vm.serializeAddress(objectKey, "pool", address(pool));
        vm.serializeAddress(objectKey, "lpToken", address(pool.lpToken()));
        vm.serializeAddress(objectKey, "vault", address(vault));
        vm.serializeAddress(objectKey, "lendingPool", address(lendingPool));
        vm.serializeAddress(objectKey, "badge", address(badge));
        vm.serializeAddress(objectKey, "configImplementation", address(implementation));
        string memory json = vm.serializeAddress(objectKey, "configProxy", address(configProxy));

        string memory path = _deploymentArtifactPath(chainId);
        vm.writeFile(path, json);
        console2.log("Wrote deployment artifact", path);
    }

    function _deploymentArtifactPath(uint256 chainId) internal view returns (string memory path) {
        if (chainId == BASE_SEPOLIA_CHAIN_ID) {
            return "deployments/base-sepolia.json";
        }
        if (chainId == ARBITRUM_SEPOLIA_CHAIN_ID) {
            return "deployments/arbitrum-sepolia.json";
        }
        return string.concat("deployments/", vm.toString(chainId), ".json");
    }

    function _logAddresses() internal view {
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
