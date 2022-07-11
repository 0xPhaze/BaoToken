// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./ERC721AX.sol";
import {MockERC721A} from "./ERC721A.mock.sol";

import "../BaoToken.sol";
import "./ArrayUtils.sol";

contract TestBaoToken is Test {
    using ArrayUtils for *;

    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    MockERC721A baoSociety;
    BaoToken token;

    function setUp() public {
        baoSociety = new MockERC721A();
        token = new BaoToken(IERC721(address(baoSociety)));

        vm.label(bob, "bob");
        vm.label(alice, "alice");
        vm.label(tester, "tester");

        vm.label(address(baoSociety), "BAO SOCIETY");
        vm.label(address(token), "BAO TOKEN");

        // vm.roll(block.number + 10);
    }

    function assertEq(uint256[] memory a, uint256[] memory b) internal {
        assertEq(a.length, b.length);
        for (uint256 i; i < a.length; i++) assertEq(a[i], b[i]);
    }

    /* ------------- claimReward() ------------- */

    function test_claimReward() public {
        baoSociety.mint(20);

        uint256[] memory ids = [2, 3, 6, 7].toMemory();

        assertEq(token.dailyReward(ids), 4 * 105 ether);
        assertEq(token.pendingReward(ids), 0);

        skip(1 days);

        assertEq(token.pendingReward(ids), 4 * 105 ether);

        token.claimReward(ids);

        assertEq(token.balanceOf(tester), 4 * 105 ether);

        token.claimReward(ids);

        assertEq(token.balanceOf(tester), 4 * 105 ether);
    }

    // make sure it's protected against duplicate claims
    function test_claimReward2() public {
        baoSociety.mint(20);

        skip(1 days);

        token.claimReward([2, 2].toMemory());

        assertEq(token.balanceOf(tester), 1 * 105 ether);
    }

    // make sure only claimable for emission duration
    function test_claimReward3() public {
        baoSociety.mint(20);

        skip(100000 days);

        token.claimReward([2].toMemory());

        assertEq(token.balanceOf(tester), 5 * 365 * 105 ether);
    }

    function test_claimReward_bonus() public {
        baoSociety.mint(20);

        token.claimReward([5].toMemory());

        assertEq(token.balanceOf(tester), 1500 ether);

        // cover double claims
        token.claimReward([5].toMemory());

        assertEq(token.balanceOf(tester), 1500 ether);
    }

    function test_claimReward_IncorrectOwner() public {
        baoSociety.mint(20);

        vm.prank(alice);
        vm.expectRevert(IncorrectOwner.selector);

        token.claimReward([1].toMemory());
    }

    /* ------------- claimRewardStaked() ------------- */

    function test_claimRewardStaked() public {
        baoSociety.mint(20);
        baoSociety.setApprovalForAll(address(token), true);

        uint256[] memory ids = [2, 3, 6, 7].toMemory();

        token.stake(ids);

        assertEq(token.numStaked(tester), 4);
        assertEq(token.stakedTokenIdsOf(tester), ids);

        assertEq(token.dailyRewardStaked(tester), 4 * 155 ether);
        assertEq(token.pendingRewardStaked(tester), 0);

        skip(1 days);

        assertEq(token.pendingRewardStaked(tester), 4 * 155 ether);

        token.claimRewardStaked();

        assertEq(token.pendingRewardStaked(tester), 0);
        assertEq(token.balanceOf(tester), 4 * 155 ether);

        token.claimRewardStaked();

        assertEq(token.balanceOf(tester), 4 * 155 ether);
    }

    function test_claimRewardStaked2() public {
        baoSociety.mint(20);
        baoSociety.setApprovalForAll(address(token), true);

        uint256[] memory ids = [2, 3, 6, 7].toMemory();

        token.stake(ids);

        skip(1 days);

        token.unstake(ids);

        assertEq(token.balanceOf(tester), 4 * 155 ether);

        // cover double claims for the individual claim
        token.claimReward(ids);

        assertEq(token.balanceOf(tester), 4 * 155 ether);
    }

    // only claim for max duration
    function test_claimRewardStaked3() public {
        baoSociety.mint(20);
        baoSociety.setApprovalForAll(address(token), true);

        uint256[] memory ids = [2, 3, 6, 7].toMemory();

        token.stake(ids);

        skip(100000 days);

        token.unstake(ids);

        assertEq(token.balanceOf(tester), 4 * 365 * 5 * 155 ether);

        // cover double claims
        token.claimReward(ids);

        assertEq(token.balanceOf(tester), 4 * 365 * 5 * 155 ether);
    }

    /* ------------- unstake() ------------- */

    function test_unstake() public {
        baoSociety.mint(20);
        baoSociety.setApprovalForAll(address(token), true);

        uint256[] memory ids = [2, 3, 6, 7].toMemory();

        token.stake(ids);
        token.unstake(ids);

        assertEq(baoSociety.ownerOf(2), tester);
        assertEq(baoSociety.ownerOf(3), tester);
        assertEq(baoSociety.ownerOf(6), tester);
        assertEq(baoSociety.ownerOf(7), tester);
    }

    function test_unstake_IncorrectOwner() public {
        baoSociety.mint(20);
        baoSociety.setApprovalForAll(address(token), true);

        uint256[] memory ids = [2, 3, 6, 7].toMemory();

        token.stake(ids);

        vm.prank(alice);
        vm.expectRevert(IncorrectOwner.selector);

        token.unstake(ids);

        vm.expectRevert(TransferFromIncorrectOwner.selector);
        token.unstake([2, 2].toMemory());
    }

    /* ------------- setRarities() ------------- */

    function test_claimReward_rarities() public {
        uint256[] memory ids = [2, 3, 6, 7].toMemory();

        token.setRarities(ids, [50, 300, 0, 100].toMemory());

        baoSociety.mint(20);

        uint256 rarityBonus = 50 + 300 + 5 + 100;

        assertEq(token.dailyReward(ids), (400 + rarityBonus) * 1 ether);

        skip(1 days);

        token.claimReward(ids);

        assertEq(token.balanceOf(tester), (400 + rarityBonus) * 1 ether);
    }

    function test_claimRewardStaked_rarities() public {
        uint256[] memory ids = [2, 3, 6, 7].toMemory();

        token.setRarities(ids, [50, 300, 0, 100].toMemory());

        baoSociety.mint(20);
        baoSociety.setApprovalForAll(address(token), true);

        token.stake(ids);

        uint256 rarityBonus = 50 + 300 + 5 + 100;

        assertEq(token.dailyRewardStaked(tester), (4 * 150 + rarityBonus) * 1 ether);

        skip(1 days);

        token.claimRewardStaked();

        assertEq(token.balanceOf(tester), (4 * 150 + rarityBonus) * 1 ether);
    }
}
