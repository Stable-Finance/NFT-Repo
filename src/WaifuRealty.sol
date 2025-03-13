// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


// Waifu Realty Contract
// Simple NFT that allows for whitelisting and permissioned mint
contract WaifuRealty is ERC721, Ownable {
    constructor(string memory base) ERC721("Waifu Realty", "WAIFU") Ownable(msg.sender) {
        _base_uri = base;
    }

    mapping(address => uint256) private _mintCount;
    mapping(address => bool) private _whitelist;

    uint256 private _whitelistCost = 1e18 / 10;
    uint256 private _regularCost = 1e18 * 3 / 10;
    
    string private _base_uri;

    // Stage 0: only Admin can mint
    // Stage 1: only Whitelist can mint
    // Stage 2: anyone can mint
    uint256 private _stage = 0;
    uint256 private _nextTokenId = 0;
    
    function mint(address to) public payable {
        if (_stage == 0) {
            require(msg.sender == owner(), "Only Owner can Mint");
        } else if (_stage == 1) {
            require(_whitelist[msg.sender], "Only Whitelisted Can Mint");
        }
        
        if (_whitelist[msg.sender]) {
            require(msg.value >= _whitelistCost, "Not Enough MON Sent");
        } else {
            require(msg.value >= _regularCost, "Not Enough MON Sent");
        }

        if (msg.sender != owner()) {
            require(_mintCount[msg.sender] < 3, "Too Many Minted");
        }

        uint256 tokenId = _nextTokenId++;
        require(tokenId < 10_000, "Collection Minted Out");
        _mint(to, tokenId);
    }

    function setStage(uint256 stage) public onlyOwner {
        _stage = stage;
    }
    
    function whitelist(address user) public onlyOwner {
        _whitelist[user] = true;
    }

    function unWhitelist(address user) public onlyOwner {
        _whitelist[user] = false;
    }

    function setWhitelistCost(uint256 newCost) public onlyOwner {
        _whitelistCost = newCost;
    }

    function setRegularCost(uint256 newCost) public onlyOwner {
        _regularCost = newCost;
    }

    function setBaseURI(string calldata base_uri) public onlyOwner {
        _base_uri = base_uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _base_uri;
    }
}
