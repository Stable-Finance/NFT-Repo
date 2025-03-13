// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {WaifuRealty} from "../src/WaifuRealty.sol";

contract DeployScript is Script {
    WaifuRealty public realty;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivkey = vm.envUint("MONAD_PRIVKEY");
        vm.startBroadcast(deployerPrivkey);

        realty = new WaifuRealty(vm.envString("BASE_URI"));

        vm.stopBroadcast();
    }
}
