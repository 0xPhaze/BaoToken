// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {MockERC721} from "solmate/test/utils/mocks/MockERC721.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import "../Marketplace.sol";

contract MockToken is ERC20("", "", 18) {
    function mint(address user, uint256 amount) public {
        _mint(user, amount);
    }

    function burnFrom(address owner, uint256 amount) public {
        _burn(owner, amount);
    }
}

contract TestMarketplace is Test {
    event MarketItemPurchased(address indexed user, bytes32 indexed id);

    /* ------------- Structs ------------- */

    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    Marketplace market;
    MockToken token;

    function setUp() public {
        token = new MockToken();
        market = new Marketplace(BaoToken(address(token)));

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(tester, "tester");

        vm.label(address(market), "market");
        vm.label(address(token), "token");
    }

    /* ------------- purchaseMarketItem() ------------- */

    function test_purchaseMarketItem() public {
        token.mint(alice, 500 ether);

        Marketplace.MarketItemData[] memory data = new Marketplace.MarketItemData[](1);
        data[0].start = block.timestamp;
        data[0].end = block.timestamp + 500;
        data[0].tokenPrice = 100 ether;
        data[0].ethPrice = 1 ether;
        data[0].maxEntries = 2;
        data[0].maxSupply = 2;
        data[0].dataHash = 0x0;

        bytes32 hash = keccak256(abi.encode(data[0]));

        vm.expectEmit(true, true, false, false);
        emit MarketItemPurchased(alice, hash);

        vm.prank(alice, alice);
        market.purchaseMarketItem(data, true);

        // check token balance
        assertEq(token.balanceOf(alice), 400 ether);

        // purchase another with eth
        vm.expectEmit(true, true, false, false);
        emit MarketItemPurchased(alice, hash);

        vm.deal(alice, 1 ether);

        vm.prank(alice, alice);
        market.purchaseMarketItem{value: 1 ether}(data, false);

        assertEq(alice.balance, 0 ether);

        assertEq(market.totalSupply(hash), 2);
        assertEq(market.numEntries(hash, alice), 2);
    }

    function test_purchaseMarketItemMultiple() public {
        token.mint(alice, 500 ether);

        Marketplace.MarketItemData[] memory data = new Marketplace.MarketItemData[](2);
        data[0].start = block.timestamp;
        data[0].end = block.timestamp + 500;
        data[0].tokenPrice = 100 ether;
        data[0].ethPrice = 1 ether;
        data[0].maxEntries = 2;
        data[0].maxSupply = 2;
        data[0].dataHash = 0x0;

        data[1].start = block.timestamp;
        data[1].end = block.timestamp + 500;
        data[1].tokenPrice = 100 ether;
        data[1].ethPrice = 1 ether;
        data[1].maxEntries = 2;
        data[1].maxSupply = 2;
        data[1].dataHash = bytes32(uint256(0x1));

        bytes32 hash0 = keccak256(abi.encode(data[0]));
        bytes32 hash1 = keccak256(abi.encode(data[1]));

        vm.expectEmit(true, true, false, false);
        emit MarketItemPurchased(alice, hash0);

        vm.expectEmit(true, true, false, false);
        emit MarketItemPurchased(alice, hash1);

        vm.prank(alice, alice);
        market.purchaseMarketItem(data, true);

        // check token balance
        assertEq(token.balanceOf(alice), 300 ether);

        assertEq(market.totalSupply(hash0), 1);
        assertEq(market.totalSupply(hash1), 1);
        assertEq(market.numEntries(hash0, alice), 1);
        assertEq(market.numEntries(hash1, alice), 1);
    }

    function test_purchaseMarketItem_fail_NoSupplyLeft() public {
        token.mint(alice, 500 ether);
        token.mint(bob, 500 ether);

        Marketplace.MarketItemData[] memory data = new Marketplace.MarketItemData[](1);
        data[0].start = block.timestamp;
        data[0].end = block.timestamp + 500;
        data[0].tokenPrice = 100 ether;
        data[0].ethPrice = 1 ether;
        data[0].maxEntries = 1;
        data[0].maxSupply = 1;
        data[0].dataHash = 0x0;

        vm.prank(alice, alice);
        market.purchaseMarketItem(data, true);

        vm.expectRevert(NoSupplyLeft.selector);
        vm.prank(bob, bob);
        market.purchaseMarketItem(data, true);
    }

    function test_purchaseMarketItem_fail_MaxEntriesReached() public {
        token.mint(alice, 500 ether);

        Marketplace.MarketItemData[] memory data = new Marketplace.MarketItemData[](1);
        data[0].start = block.timestamp;
        data[0].end = block.timestamp + 500;
        data[0].tokenPrice = 100 ether;
        data[0].ethPrice = 1 ether;
        data[0].maxEntries = 1;
        data[0].maxSupply = 2;
        data[0].dataHash = 0x0;

        vm.prank(alice, alice);
        market.purchaseMarketItem(data, true);

        vm.expectRevert(MaxEntriesReached.selector);
        vm.prank(alice, alice);
        market.purchaseMarketItem(data, true);
    }

    function test_purchaseMarketItem_fail_NotActive() public {
        token.mint(alice, 500 ether);

        Marketplace.MarketItemData[] memory data = new Marketplace.MarketItemData[](1);
        data[0].start = block.timestamp + 100;
        data[0].end = block.timestamp + 500;
        data[0].tokenPrice = 100 ether;
        data[0].ethPrice = 1 ether;
        data[0].maxEntries = 1;
        data[0].maxSupply = 2;
        data[0].dataHash = 0x0;

        vm.expectRevert(NotActive.selector);
        vm.prank(alice, alice);

        market.purchaseMarketItem(data, true);

        vm.warp(block.timestamp + 800);

        vm.expectRevert(NotActive.selector);
        vm.prank(alice, alice);
        market.purchaseMarketItem(data, true);
    }
}
