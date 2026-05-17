// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title ProtocolAccessNFT
/// @notice ERC-721 membership badge for users that participate in the DeFiHub protocol.
contract ProtocolAccessNFT is ERC721, Ownable {
    uint256 public nextTokenId = 1;

    event BadgeMinted(address indexed recipient, uint256 indexed tokenId);

    constructor(address initialOwner) ERC721("DeFiHub Protocol Badge", "DFHB") Ownable(initialOwner) {}

    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        emit BadgeMinted(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return "ipfs://defihub-protocol-badge";
    }
}
