// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/WorkshopFixed.sol";

contract WorkshopFixedTest is Test {
    Workshop workshop;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    event Mint(address indexed sender, address indexed to, uint256 amount);
    event Burn(address indexed sender, address indexed from, uint256 amount);

    function setUp() public {
        workshop = new Workshop();

        payable(alice).transfer(100e18);
        payable(bob).transfer(100e18);
    }

    function test_Mint() public {
        uint256 price = workshop.PRICE();

        uint256 amountAlice = 10e18;
        uint256 valueAlice = amountAlice * price / 1e18;

        vm.expectEmit(true, true, true, true);
        emit Mint(alice, alice, amountAlice);

        vm.prank(alice);
        workshop.mint{value: valueAlice}(alice, amountAlice);

        assertEq(workshop.balanceOf(alice), amountAlice, "test_Mint::1");
        assertEq(address(workshop).balance, valueAlice, "test_Mint::2");
        assertEq(address(alice).balance, 100e18 - valueAlice, "test_Mint::3");

        uint256 amountBob = 20e18;
        uint256 valueBob = amountBob * price / 1e18;

        vm.expectEmit(true, true, true, true);
        emit Mint(bob, bob, amountBob);

        vm.prank(bob);
        workshop.mint{value: valueBob}(bob, amountBob);

        assertEq(workshop.balanceOf(bob), amountBob, "test_Mint::4");
        assertEq(address(workshop).balance, valueAlice + valueBob, "test_Mint::5");
        assertEq(address(bob).balance, 100e18 - valueBob, "test_Mint::6");
    }

    function test_revert_Mint() public {
        uint256 maxSupply = workshop.MAX_SUPPLY();

        vm.expectRevert("Max supply exceeded");
        workshop.mint(alice, maxSupply + 1);

        uint256 price = workshop.PRICE();

        uint256 amountAlice = 10e18;
        uint256 valueAlice = amountAlice * price / 1e18;

        vm.expectRevert("Invalid amount");
        workshop.mint{value: valueAlice - 1}(alice, amountAlice);

        vm.expectRevert("Invalid amount");
        workshop.mint{value: valueAlice + 1}(alice, amountAlice);
    }

    function test_Burn() public {
        uint256 price = workshop.PRICE();

        uint256 amountAlice = 10e18;
        uint256 valueAlice = amountAlice * price / 1e18;
        uint256 amountBob = 20e18;
        uint256 valueBob = amountBob * price / 1e18;

        vm.prank(alice);
        workshop.mint{value: valueAlice}(alice, amountAlice);

        vm.prank(bob);
        workshop.mint{value: valueBob}(bob, amountBob);

        vm.expectEmit(true, true, true, true);
        emit Burn(alice, alice, amountAlice / 2);

        vm.prank(alice);
        workshop.burn(amountAlice / 2);

        assertEq(workshop.balanceOf(alice), amountAlice / 2, "test_Burn::1");
        assertEq(address(workshop).balance, valueAlice / 2 + valueBob, "test_Burn::2");
        assertEq(address(alice).balance, 100e18 - valueAlice / 2, "test_Burn::3");

        vm.expectEmit(true, true, true, true);
        emit Burn(bob, bob, amountBob);

        vm.prank(bob);
        workshop.burn(amountBob);

        assertEq(workshop.balanceOf(bob), 0, "test_Burn::4");
        assertEq(address(workshop).balance, valueAlice / 2, "test_Burn::5");
        assertEq(address(bob).balance, 100e18, "test_Burn::6");
    }

    function test_revert_Burn() public {
        uint256 price = workshop.PRICE();

        uint256 amountAlice = 10e18;
        uint256 valueAlice = amountAlice * price / 1e18;

        vm.prank(alice);
        workshop.mint{value: valueAlice}(alice, amountAlice);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, amountAlice, amountAlice + 1)
        );
        workshop.burn(amountAlice + 1);
    }

    function test_fuzz_Mint(uint256 mint0, uint256 mint1) public {
        uint256 maxAmount = workshop.MAX_SUPPLY();
        uint256 price = workshop.PRICE();

        mint0 = bound(mint0, 0, maxAmount);
        maxAmount -= mint0;

        uint256 value0 = (mint0 * price + 1e18 - 1) / 1e18;

        vm.prank(alice);
        workshop.mint{value: value0}(alice, mint0);

        mint1 = bound(mint1, 0, maxAmount);
        maxAmount -= mint1;

        uint256 value1 = (mint1 * price + 1e18 - 1) / 1e18;

        vm.prank(bob);
        workshop.mint{value: value1}(bob, mint1);

        uint256 minted = workshop.totalSupply();
        uint256 expectedValue = (minted * price + 1e18 - 1) / 1e18;

        assertGe(address(workshop).balance, expectedValue, "test_fuzz_Mint::1");
        assertEq(workshop.balanceOf(alice), mint0, "test_fuzz_Mint::2");
        assertEq(workshop.balanceOf(bob), mint1, "test_fuzz_Mint::3");
    }

    function test_fuzz_revert_Mint(uint256 amount) public {
        uint256 maxAmount = workshop.MAX_SUPPLY();
        uint256 price = workshop.PRICE();

        amount = bound(amount, 0, maxAmount);
        maxAmount -= amount;

        uint256 value0 = (amount * price + 1e18 - 1) / 1e18;

        vm.prank(alice);
        workshop.mint{value: value0}(alice, amount);

        vm.expectRevert("Max supply exceeded");
        vm.prank(bob);
        workshop.mint{value: value0}(bob, maxAmount + 1);
    }

    function test_fuzz_Burn(uint256 mint0, uint256 mint1, uint256 burn0, uint256 burn1) public {
        deal(address(workshop), 100e18);

        uint256 price = workshop.PRICE();

        mint0 = bound(mint0, 0, 100e18);
        mint1 = bound(mint1, 0, 100e18);

        uint256 value0 = (mint0 * price + 1e18 - 1) / 1e18;
        uint256 value1 = (mint1 * price + 1e18 - 1) / 1e18;

        vm.startPrank(alice);
        workshop.mint{value: value0}(alice, mint0);
        workshop.mint{value: value1}(alice, mint1);
        vm.stopPrank();

        uint256 aliceBalance = address(alice).balance;

        burn0 = bound(burn0, 0, mint0 + mint1);
        burn1 = bound(burn1, 0, mint0 + mint1 - burn0);

        vm.prank(alice);
        workshop.burn(burn0);

        vm.prank(alice);
        workshop.burn(burn1);

        assertGe(value0 + value1, address(alice).balance - aliceBalance, "test_fuzz_Burn::1");
        assertEq(workshop.balanceOf(alice), mint0 + mint1 - burn0 - burn1, "test_fuzz_Burn::2");
    }
}
