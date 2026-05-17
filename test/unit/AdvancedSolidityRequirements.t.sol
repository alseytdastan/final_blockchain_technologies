// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {UpgradeableProtocolConfig} from "../../contracts/upgradeable/UpgradeableProtocolConfig.sol";
import {UpgradeableProtocolConfigV2} from "../../contracts/upgradeable/UpgradeableProtocolConfigV2.sol";
import {PoolFactory} from "../../contracts/amm/PoolFactory.sol";
import {AMMPool} from "../../contracts/amm/AMMPool.sol";
import {MathUtils} from "../../contracts/utils/MathUtils.sol";

contract AdvancedSolidityRequirementsTest is Test {
    address internal owner = address(0xA11CE);

    function testUUPSUpgradePathV1ToV2() external {
        UpgradeableProtocolConfig v1Implementation = new UpgradeableProtocolConfig();
        bytes memory initData = abi.encodeCall(UpgradeableProtocolConfig.initialize, (owner, 30, "Option A Config"));
        ERC1967Proxy proxy = new ERC1967Proxy(address(v1Implementation), initData);

        UpgradeableProtocolConfig proxiedV1 = UpgradeableProtocolConfig(address(proxy));
        assertEq(proxiedV1.feeBps(), 30);
        assertEq(proxiedV1.protocolName(), "Option A Config");

        vm.prank(owner);
        proxiedV1.setFeeBps(25);
        assertEq(proxiedV1.feeBps(), 25);

        UpgradeableProtocolConfigV2 v2Implementation = new UpgradeableProtocolConfigV2();
        vm.prank(owner);
        proxiedV1.upgradeToAndCall(address(v2Implementation), "");

        UpgradeableProtocolConfigV2 proxiedV2 = UpgradeableProtocolConfigV2(address(proxy));
        assertEq(proxiedV2.feeBps(), 25);
        assertEq(proxiedV2.protocolName(), "Option A Config");
        assertEq(proxiedV2.version(), "V2");

        vm.prank(owner);
        proxiedV2.setMaxLtvBps(7500);
        assertEq(proxiedV2.maxLtvBps(), 7500);
    }

    function testFactoryCreateAndCreate2() external {
        PoolFactory factory = new PoolFactory();
        address tokenA = address(0x1111);
        address tokenB = address(0x2222);

        address poolCreate = factory.createPool(tokenA, tokenB);
        assertEq(AMMPool(poolCreate).tokenA(), tokenA);
        assertEq(AMMPool(poolCreate).tokenB(), tokenB);
        assertEq(AMMPool(poolCreate).creator(), address(this));

        bytes32 salt = keccak256("OPTION_A_POOL_SALT");
        address predicted = factory.predictDeterministicAddress(tokenA, tokenB, address(this), salt);
        address poolCreate2 = factory.createPoolDeterministic(tokenA, tokenB, salt);

        assertEq(poolCreate2, predicted);
        assertEq(AMMPool(poolCreate2).creator(), address(this));
    }

    function testYulMatchesSolidityAndBenchmarkedGas() external {
        MathUtils bench = new MathUtils();
        uint256 a = 123_456;
        uint256 b = 654_321;

        uint256 gasStartSolidity = gasleft();
        uint256 resultSolidity = bench.maxSolidity(a, b);
        uint256 gasUsedSolidity = gasStartSolidity - gasleft();

        uint256 gasStartYul = gasleft();
        uint256 resultYul = bench.maxYul(a, b);
        uint256 gasUsedYul = gasStartYul - gasleft();

        assertEq(resultSolidity, resultYul);
        emit log_named_uint("gas maxSolidity", gasUsedSolidity);
        emit log_named_uint("gas maxYul", gasUsedYul);
    }
}
