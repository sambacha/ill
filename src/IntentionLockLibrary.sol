// SPDX-License-Identifier: COPYRIGHT 2023 - Sam Bacha

// @
pragma solidity 0.8.21;

contract IntentionLock {
    enum LockState {Unlocked, X, S, IX, IS}
    
    struct Node {
        LockState state;
        address owner;
        uint parentIndex;
    }

    Node[] public tree;

    // Conditions
    function _isOwner(uint nodeIndex, address user) private view returns (bool) {
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
        return currentState == LockState.Unlocked || currentState == LockState.S || currentState == LockState.IS || currentState == LockState.IX;
    }
    
    function _isRootNodeExist() private view returns (bool) {
        return tree.length > 0;
    }

    function _isValidParent(uint parentIndex) private view returns (bool) {
        return parentIndex < tree.length;
    }

    // Modifiers
    // ... [modifiers remain unchanged] ...

    // Transitions
    function _addRootNode() private {
        Node memory newNode = Node({
            state: LockState.Unlocked,
            owner: address(0),
            parentIndex: 0 
        });
        tree.push(newNode);
        emit NodeAdded(0, 0, msg.sender);

        // Assertion for invariant: Only one root node exists
        assert(tree[0].parentIndex == 0 && tree.length == 1);
    }

    function _addChildNode(uint parentIndex) private {
        Node memory newNode = Node({
            state: LockState.Unlocked,
            owner: address(0),
            parentIndex: parentIndex
        });
        tree.push(newNode);
        uint newNodeIndex = tree.length - 1;
        emit NodeAdded(newNodeIndex, parentIndex, msg.sender);

        // Assertion for invariant: Child node's parent index matches the provided parent index
        assert(tree[newNodeIndex].parentIndex == parentIndex);
    }

    function _lockNode(uint nodeIndex, LockState lockState) private {
        tree[nodeIndex].state = lockState;
        tree[nodeIndex].owner = msg.sender;
        emit NodeLocked(nodeIndex, lockState, msg.sender);

        // Assertion for invariant: Node's state and owner should match the recent change
        assert(tree[nodeIndex].state == lockState && tree[nodeIndex].owner == msg.sender);
    }

    function _unlockNode(uint nodeIndex) private {
        tree[nodeIndex].state = LockState.Unlocked;
        tree[nodeIndex].owner = address(0);
        emit NodeUnlocked(nodeIndex, msg.sender);

        // Assertion for invariant: Node should be unlocked and ownerless after unlock
        assert(tree[nodeIndex].state == LockState.Unlocked && tree[nodeIndex].owner == address(0));
    }

    // Combined Functions
    // ... [combined functions remain unchanged] ...
    
    event NodeAdded(uint nodeIndex, uint parentIndex, address createdBy);
    event NodeLocked(uint nodeIndex, LockState lockedState, address lockedBy);
    event NodeUnlocked(uint nodeIndex, address unlockedBy);
}
