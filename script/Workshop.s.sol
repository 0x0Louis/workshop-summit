// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "src/WorkshopFixed.sol";

contract WorkshopScript is Script {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("fuji"));
    }

    function run() public returns (Workshop workshop) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.broadcast(pk);
        workshop = new Workshop();
    }
}
