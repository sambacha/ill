// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/IntentionLockLibrary.sol";

contract IntentionLockTest is Test {
    IntentionLock intentionLock;
    address owner = address(this);
    address addr1 = address(0x1);
    address addr2 = address(0x2);

    function setUp() public {
        intentionLock = new IntentionLock();
    }

    function testAddRootNode() public {
        intentionLock.addRootNode();
        (IntentionLock.LockState state, address nodeOwner, uint parentIndex) = intentionLock.tree(0);
        assertEq(parentIndex, 0);
        assertEq(uint(state), uint(IntentionLock.LockState.Unlocked));
    }

    function testCannotAddMultipleRootNodes() public {
        intentionLock.addRootNode();
        vm.expectRevert("Root node already exists");
        intentionLock.addRootNode();
    }

    function testAddChildNode() public {
        intentionLock.addRootNode();
        intentionLock.addChildNode(0);
        (, , uint parentIndex) = intentionLock.tree(1);
        assertEq(parentIndex, 0);
    }

    function testCannotAddChildNodeWithInvalidParent() public {
        vm.expectRevert("Invalid parent index");
        intentionLock.addChildNode(0);
    }

    function testLockX() public {
        intentionLock.addRootNode();
        intentionLock.addChildNode(0);
        intentionLock.lockX(1);
        (IntentionLock.LockState state, , ) = intentionLock.tree(1);
        assertEq(uint(state), uint(IntentionLock.LockState.X));
    }

    function testLockS() public {
        intentionLock.addRootNode();
        intentionLock.addChildNode(0);
        intentionLock.lockS(1);
        (IntentionLock.LockState state, , ) = intentionLock.tree(1);
        assertEq(uint(state), uint(IntentionLock.LockState.S));
    }

    function testLockIX() public {
        intentionLock.addRootNode();
        intentionLock.addChildNode(0);
        intentionLock.lockIX(1);
        (IntentionLock.LockState state, , ) = intentionLock.tree(1);
        assertEq(uint(state), uint(IntentionLock.LockState.IX));
    }

    function testLockIS() public {
        intentionLock.addRootNode();
        intentionLock.addChildNode(0);
        intentionLock.lockIS(1);
        (IntentionLock.LockState state, , ) = intentionLock.tree(1);
        assertEq(uint(state), uint(IntentionLock.LockState.IS));
    }

    function testUnlock() public {
        intentionLock.addRootNode();
        intentionLock.addChildNode(0);
        intentionLock.lockX(1);
        intentionLock.unlock(1);
        (IntentionLock.LockState state, , ) = intentionLock.tree(1);
        assertEq(uint(state), uint(IntentionLock.LockState.Unlocked));
    }

    function testCannotUnlockIfNotOwner() public {
        intentionLock.addRootNode();
        intentionLock.addChildNode(0);
        intentionLock.lockX(1);
        vm.prank(addr1);
        vm.expectRevert("Not the owner");
        intentionLock.unlock(1);
    }
}