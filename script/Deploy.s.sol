// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { WaifuRealty } from "../src/WaifuRealty.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DeployScript is Script {
    WaifuRealty public realty;
    string base = "https://storage.googleapis.com/waifu_realty_jpegs/";
    string base_blur = "https://storage.googleapis.com/waifu_realty_jpegs/blur_";
    IERC20Metadata usdx = IERC20Metadata(0xD875Ba8e2caD3c0f7e2973277C360C8d2f92B510);
    ERC721 mgr = ERC721(0x9d380F07463900767A8cB26A238CEf047A174D62);

    function setUp() public {}

    function run() public {
        uint256 deployerPrivkey = vm.envUint("MONAD_PRIVKEY");
        vm.startBroadcast(deployerPrivkey);

        realty = new WaifuRealty(base, base_blur, mgr, usdx);

        vm.stopBroadcast();
    }
}
