// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Governor} from "openzeppelin-contracts/contracts/governance/Governor.sol";
import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import {
    GovernorCountingSimple
} from "openzeppelin-contracts/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorSettings} from "openzeppelin-contracts/contracts/governance/extensions/GovernorSettings.sol";
import {
    GovernorTimelockControl
} from "openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovernorVotes} from "openzeppelin-contracts/contracts/governance/extensions/GovernorVotes.sol";
import {
    GovernorVotesQuorumFraction
} from "openzeppelin-contracts/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {IVotes} from "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

/// @title ProtocolGovernor
/// @notice OpenZeppelin Governor stack for the DeFiHub DAO.
contract ProtocolGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    uint48 public constant VOTING_DELAY_BLOCKS = 7_200; // about 1 day at 12s/block
    uint32 public constant VOTING_PERIOD_BLOCKS = 50_400; // about 1 week at 12s/block
    uint256 public constant QUORUM_PERCENT = 4;
    uint256 public constant PROPOSAL_THRESHOLD_PERCENT = 1;

    constructor(IVotes token, TimelockController timelock)
        Governor("DeFiHub Governor")
        GovernorSettings(VOTING_DELAY_BLOCKS, VOTING_PERIOD_BLOCKS, 0)
        GovernorVotes(token)
        GovernorVotesQuorumFraction(QUORUM_PERCENT)
        GovernorTimelockControl(timelock)
    {}

    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 timepoint) public view override(Governor, GovernorVotesQuorumFraction) returns (uint256) {
        return super.quorum(timepoint);
    }

    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        uint48 currentTimepoint = clock();
        if (currentTimepoint == 0) return 0;
        return token().getPastTotalSupply(currentTimepoint - 1) * PROPOSAL_THRESHOLD_PERCENT / 100;
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }
}
