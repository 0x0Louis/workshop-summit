// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "src/WorkshopFixed.sol";

contract WorkshopMintScript is Script {
    Workshop public constant workshop = Workshop(0xD8489F16279DeE1B11eB9b90315334836Aa6795C);

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("fuji"));
    }

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        uint256 price = workshop.PRICE();

        uint256 amount = 10e18;
        uint256 value = amount * price / 1e18;

        vm.broadcast(pk);
        workshop.mint{value: value}(deployer, amount);
    }
}
