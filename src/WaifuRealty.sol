// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// Waifu Realty Contract
// Simple NFT that allows for whitelisting and permissioned mint
// Users will have to deposit a certain amount of USDX to unblur the image. 
contract WaifuRealty is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20Metadata;
    using Strings for uint256;

    constructor(
        string memory base,
        string memory base_blurred,
        ERC721 stable_manager,
        IERC20Metadata unblur_token
    ) ERC721("Waifu Realty", "WAIFU") ERC721Enumerable() Ownable(msg.sender) {
        _base_uri = base;
        _base_uri_blurred = base_blurred;
        _unblur_token = unblur_token;
        _stable_manager = stable_manager;
    }

    mapping(address => uint256) private _mintCount;
    mapping(address => bool) private _whitelist;
    mapping(uint256 => bool) private _unblurred;

    uint256 private _whitelistCost = 1e18 / 10;
    uint256 private _regularCost = 1e18 * 3 / 10;
    uint256 private _unblurCost = 1e6;

    IERC20Metadata private _unblur_token;
    ERC721 private _stable_manager;
    
    string private _base_uri;
    string private _base_uri_blurred;

    // Stage 0: only Owner can mint
    // Stage 1: only Whitelist can mint
    // Stage 2: anyone can mint
    uint256 private _stage = 0;
    uint256 private _nextTokenId = 1;
    
    function mint() public payable returns (uint256) {
        require(_stage != 0 || msg.sender == owner(), "Only Owner Can Mint");
        if (_stage == 1) {
            require(
                _whitelist[msg.sender] || msg.sender == owner(),
                "Only Whitelisted Can Mint"
            );
        }

        // Non-owner users have mint limits and required MON
        // also they need to own a stable_manager
        if (msg.sender != owner()) {
            require(_mintCount[msg.sender] < 3, "Too Many Minted");
            require(_stable_manager.balanceOf(msg.sender) > 0, "Minters must Deposit Property");

            if (_whitelist[msg.sender]) {
                require(msg.value >= _whitelistCost, "Not Enough MON Sent");
            } else {
                require(msg.value >= _regularCost, "Not Enough MON Sent");
            }
        }

        // get first tokenId that hasnt already been taken
        // token ids can be minted out of sequence using mintOwner
        bool found_token_id = false;
        uint256 tokenId;
        while (!found_token_id) {
            tokenId = _nextTokenId++;
            if (_ownerOf(tokenId) == address(0)) {
                found_token_id = true;
                break;
            }
        }

        require(tokenId <= 10_000, "Collection Minted Out");

        _mint(msg.sender, tokenId);
        _mintCount[msg.sender] += 1;
        
        return tokenId;
    }

    function unblur(uint256 tokenId) public {
        _unblur_token.safeTransferFrom(msg.sender, owner(), _unblurCost);
        _unblurred[tokenId] = true;
    }

    function mintOwner(uint256 tokenId) public onlyOwner {
        require(tokenId < 10_000, "Invalid tokenId");
        require(_ownerOf(tokenId) == address(0), "Token Already Minted");

        _mint(msg.sender, tokenId);
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

    function setUnblurCost(uint256 newCost) public onlyOwner {
        _unblurCost = newCost;
    }

    function setBaseURI(string calldata base_uri) public onlyOwner {
        _base_uri = base_uri;
    }

    function setBlurURI(string calldata base_uri_blurred) public onlyOwner {
        _base_uri_blurred = base_uri_blurred;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(
            _unblurred[tokenId] ? _base_uri : _base_uri_blurred,
            tokenId.toString(),
            ".json"
        ));
    }

    function isBlurred(uint256 tokenId) external view returns (bool) {
        return !_unblurred[tokenId];
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return _whitelist[addr];
    }
}
