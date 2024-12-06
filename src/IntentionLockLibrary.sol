// SPDX-License-Identifier: GPL-3.0

/// @title Intention Locking Library
/// @author Sam Bacha

// TODO
//     explicit types (uint = unit256)
//     Diagram Locking Mechanics

pragma solidity ^0.8.21;

contract IntentionLock {
    enum LockState {
        Unlocked,
        X,
        S,
        IX,
        IS
    }

    struct Node {
        LockState state;
        address owner;
        uint256 parentIndex;
    }

    Node[] public tree;

    // Conditions
    function _isOwner(uint256 nodeIndex, address user) private view returns (bool) {
        return tree[nodeIndex].owner == user;
    }

    function _canLockX(LockState currentState) private pure returns (bool) {
        return currentState == LockState.Unlocked;
    }

    function _canLockS(LockState currentState) private pure returns (bool) {
        return currentState == LockState.Unlocked || currentState == LockState.S || currentState == LockState.IS;
    }

    function _canLockIX(LockState currentState) private pure returns (bool) {
        return currentState == LockState.Unlocked || currentState == LockState.IX || currentState == LockState.IS;
    }

    function _canLockIS(LockState currentState) private pure returns (bool) {
        return currentState == LockState.Unlocked || currentState == LockState.S || currentState == LockState.IS
            || currentState == LockState.IX;
    }

    function _isRootNodeExist() private view returns (bool) {
        return tree.length > 0;
    }

    function _isValidParent(uint256 parentIndex) private view returns (bool) {
        return parentIndex < tree.length;
    }

    // Modifiers
    // ... [function modifiers] ...

    modifier onlyOwner(uint256 nodeIndex) {
        require(tree[nodeIndex].owner == msg.sender, "Not the owner");
        _;
    }

    modifier canLockX(uint256 nodeIndex) {
        require(_canLockX(tree[nodeIndex].state), "Cannot lock X");
        _;
    }

    modifier canLockS(uint256 nodeIndex) {
        require(_canLockS(tree[nodeIndex].state), "Cannot lock S");
        _;
    }

    modifier canLockIX(uint256 nodeIndex) {
        require(_canLockIX(tree[nodeIndex].state), "Cannot lock IX");
        _;
    }

    modifier canLockIS(uint256 nodeIndex) {
        require(_canLockIS(tree[nodeIndex].state), "Cannot lock IS");
        _;
    }

    modifier rootNodeDoesNotExist() {
        require(!_isRootNodeExist(), "Root node already exists");
        _;
    }

    modifier isValidParent(uint256 parentIndex) {
        require(_isValidParent(parentIndex), "Invalid parent index");
        _;
    }

    // Transitions

    // _addRootNode
    function _addRootNode() private {
        Node memory newNode = Node({state: LockState.Unlocked, owner: address(0), parentIndex: 0});
        tree.push(newNode);
        emit NodeAdded(0, 0, msg.sender);

        // Assertion for invariant: Only one root node exists
        assert(tree[0].parentIndex == 0 && tree.length == 1);
    }

    function _addChildNode(uint256 parentIndex) private {
        Node memory newNode = Node({state: LockState.Unlocked, owner: address(0), parentIndex: parentIndex});
        tree.push(newNode);
        uint256 newNodeIndex = tree.length - 1;
        emit NodeAdded(newNodeIndex, parentIndex, msg.sender);

        // Assertion for invariant: Child node's parent index matches the provided parent index
        assert(tree[newNodeIndex].parentIndex == parentIndex);
    }

    function _lockNode(uint256 nodeIndex, LockState lockState) private {
        tree[nodeIndex].state = lockState;
        tree[nodeIndex].owner = msg.sender;
        emit NodeLocked(nodeIndex, lockState, msg.sender);

        // Assertion for invariant: Node's state and owner should match the recent change
        assert(tree[nodeIndex].state == lockState && tree[nodeIndex].owner == msg.sender);
    }

    function _unlockNode(uint256 nodeIndex) private {
        tree[nodeIndex].state = LockState.Unlocked;
        tree[nodeIndex].owner = address(0);
        emit NodeUnlocked(nodeIndex, msg.sender);

        // Assertion for invariant: Node should be unlocked and ownerless after unlock
        assert(tree[nodeIndex].state == LockState.Unlocked && tree[nodeIndex].owner == address(0));
    }

    // Event Emit
    event NodeAdded(uint256 nodeIndex, uint256 parentIndex, address createdBy);
    event NodeLocked(uint256 nodeIndex, LockState lockedState, address lockedBy);
    event NodeUnlocked(uint256 nodeIndex, address unlockedBy);

    // Combined Functions
    // ... [combined functions] ...

    function addRootNode() public rootNodeDoesNotExist {
        _addRootNode();
    }

    function addChildNode(uint256 parentIndex) public isValidParent(parentIndex) {
        _addChildNode(parentIndex);
    }

    function lockX(uint256 nodeIndex) public canLockX(nodeIndex) {
        _lockNode(nodeIndex, LockState.X);
    }

    function lockS(uint256 nodeIndex) public canLockS(nodeIndex) {
        _lockNode(nodeIndex, LockState.S);
    }

    function lockIX(uint256 nodeIndex) public canLockIX(nodeIndex) {
        _lockNode(nodeIndex, LockState.IX);
    }

    function lockIS(uint256 nodeIndex) public canLockIS(nodeIndex) {
        _lockNode(nodeIndex, LockState.IS);
    }

    function unlock(uint256 nodeIndex) public onlyOwner(nodeIndex) {
        _unlockNode(nodeIndex);
    }
}
