// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Workshop is ERC20 {
    uint256 public constant MAX_SUPPLY = 9_000e18;
    uint256 public constant PRICE = 0.001e18;
    uint256 public constant PRECISION = 1e18;

    event Mint(address indexed sender, address indexed to, uint256 amount);
    event Burn(address indexed sender, address indexed from, uint256 amount);

    constructor() ERC20("Workshop", "WORK") {}

    function mint(address to, uint256 amount) public payable {
        require(amount <= MAX_SUPPLY, "Max supply exceeded");
        require(amount * PRICE / PRECISION == msg.value, "Invalid amount");

        _mint(to, amount);

        emit Mint(msg.sender, to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);

        payable(msg.sender).transfer(amount * PRICE / PRECISION);

        emit Burn(msg.sender, msg.sender, amount);
    }
}
