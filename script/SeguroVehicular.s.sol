// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SeguroVehicular} from "../src/SeguroVehicular.sol";

contract SeguroVehicularScript is Script {
    SeguroVehicular public seguroVehicular;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        seguroVehicular = new SeguroVehicular(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

        vm.stopBroadcast();
    }
}