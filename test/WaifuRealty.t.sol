// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { WaifuRealty } from "../src/WaifuRealty.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WaifuTest is Test {
    WaifuRealty public nft;

    string base = "https://storage.googleapis.com/waifu_realty_jpegs/";
    string base_blur = "https://storage.googleapis.com/waifu_realty_jpegs/blur_";
    IERC20Metadata usdx = IERC20Metadata(0xD875Ba8e2caD3c0f7e2973277C360C8d2f92B510);
    ERC721 mgr = ERC721(0x9d380F07463900767A8cB26A238CEf047A174D62);

    address owner   = 0x00b10AD612DC42AAb9968d3bAe57d55fe349DfBD;
    address minter1 = 0x011945a4AadBE36c339F66fd89D233268CDf5668;
    address minter2 = 0x029312b2A3aAc8C6abB7F59Af62a20B134857da3;

    uint256 private _whitelistCost = 1e18 / 10;
    uint256 private _regularCost = 1e18 * 3 / 10;
    uint256 private _unblurCost = 1e6;

    function setUp() public {
        vm.prank(owner);
        nft = new WaifuRealty(base, base_blur, mgr, usdx);
        
        vm.prank(owner);
        nft.whitelist(minter1);

        vm.deal(owner, 1 ether);
        vm.deal(minter1, 1 ether);
        vm.deal(minter2, 1 ether);
    }

    function test_mint() public {
        // Only owner should be able to mint at the start
        vm.prank(owner);
        uint256 id0 = nft.mint();
        assertEq(id0, 0);
        
        // any other user should fail to mint, even whitelist
        vm.prank(minter1);
        vm.expectRevert();
        nft.mint{value:_regularCost}();
        
        // open up mints to whitelist
        vm.prank(owner);
        nft.setStage(1);

        //  Owner should still be able to mint
        vm.prank(owner);
        uint256 id1 = nft.mint();
        assertEq(id1, 1);

        // whitelisted users should be able to mint
        vm.prank(minter1);
        uint256 id2 = nft.mint{value:_whitelistCost}();
        assertEq(id2, 2);

        // regular user still shouldn't be able to mint
        vm.prank(minter2);
        vm.expectRevert();
        nft.mint{value:_regularCost}();

        // open up mints to anyone
        vm.prank(owner);
        nft.setStage(2);

        //  Owner should still be able to mint
        vm.prank(owner);
        uint256 id3 = nft.mint();
        assertEq(id3, 3);

        // whitelisted users should still be able to mint
        vm.prank(minter1);
        uint256 id4 = nft.mint{value:_whitelistCost}();
        assertEq(id4, 4);

        // whitelisted users should still be able to mint
        vm.prank(minter2);
        uint256 id5 = nft.mint{value:_regularCost}();
        assertEq(id5, 5);
        
        // whitelisted users need to send whitelist amount
        vm.prank(minter1);
        vm.expectRevert();
        nft.mint{value:0}();

        // whitelisted users need to send regular amount
        vm.prank(minter2);
        vm.expectRevert();
        nft.mint{value:_whitelistCost}();
    }

    function test_mintOwner() public {
        // only owner can call
        vm.prank(minter1);
        vm.expectRevert();
        nft.mintOwner(100);

        // owner can mint out of sequence
        vm.prank(owner);
        nft.mintOwner(100);
        assertEq(nft.ownerOf(100), owner);

        // initialize at stage 2
        vm.prank(owner);
        nft.setStage(2);
        
        // mint id 0 to non-whitelist user
        vm.prank(minter2);
        uint256 id0 = nft.mint{value:_regularCost}();
        assertEq(id0, 0);

        // owner should not be able to mint token that is already minted
        vm.prank(owner);
        vm.expectRevert();
        nft.mintOwner(id0);

        // if owner mints in sequence regular minting will skip that
        vm.prank(owner);
        nft.mintOwner(1);
        vm.prank(owner);
        nft.mintOwner(2);

        vm.prank(minter1);
        assertEq(nft.mint{value:_whitelistCost}(), 3);
    }
}
