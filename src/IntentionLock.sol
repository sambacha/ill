// SPDX-License-Identifier: COPYRIGHT 2023 - Sam Bacha
pragma solidity ^0.8.0;

contract IntentionLockMOD {
    enum LockState {Unlocked, X, S, IX, IS}
    
    struct Node {
        LockState state;
        address owner;
        uint parentIndex; 
    }

    Node[] public tree; 

    modifier onlyOwner(uint nodeIndex) {
        require(tree[nodeIndex].owner == msg.sender, "Not the owner");
        _;
    }

    modifier canLockX(uint nodeIndex) {
        require(_canLockX(tree[nodeIndex].state), "Cannot lock X");
        _;
    }

    modifier canLockS(uint nodeIndex) {
        require(_canLockS(tree[nodeIndex].state), "Cannot lock S");
        _;
    }

    modifier canLockIX(uint nodeIndex) {
        require(_canLockIX(tree[nodeIndex].state), "Cannot lock IX");
        _;
    }

    modifier canLockIS(uint nodeIndex) {
        require(_canLockIS(tree[nodeIndex].state), "Cannot lock IS");
        _;
    }

    modifier rootNodeDoesNotExist() {
        require(!_isRootNodeExist(), "Root node already exists");
        _;
    }

    modifier isValidParent(uint parentIndex) {
        require(_isValidParent(parentIndex), "Invalid parent index");
        _;
    }

    event NodeAdded(uint nodeIndex, uint parentIndex, address createdBy);
    event NodeLocked(uint nodeIndex, LockState lockedState, address lockedBy);
    event NodeUnlocked(uint nodeIndex, address unlockedBy);

    function addRootNode() public rootNodeDoesNotExist {
        _addRootNode();
    }

    function addChildNode(uint parentIndex) public isValidParent(parentIndex) {
        _addChildNode(parentIndex);
    }

    function lockX(uint nodeIndex) public canLockX(nodeIndex) {
        _lockNode(nodeIndex, LockState.X);
    }

    function lockS(uint nodeIndex) public canLockS(nodeIndex) {
        _lockNode(nodeIndex, LockState.S);
    }

    function lockIX(uint nodeIndex) public canLockIX(nodeIndex) {
        _lockNode(nodeIndex, LockState.IX);
    }

    function lockIS(uint nodeIndex) public canLockIS(nodeIndex) {
        _lockNode(nodeIndex, LockState.IS);
    }

    function unlock(uint nodeIndex) public onlyOwner(nodeIndex) {
        _unlockNode(nodeIndex);
    }
}
