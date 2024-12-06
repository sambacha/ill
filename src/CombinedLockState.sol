// SPDX-License-Identifier: MIT

/// @title Intention Locking Library
/// @author Sam Bacha
/// @dev This contract is a library for "Intention Locking" where nodes can be added and locked in various states.

/*! NOTE
 * This is a partial implemenation of combining:
 *    `lockX`, `lockS`, `lockIX`, and `lockIS` 
 *  into a single `lock` function that takes the `LockState` as a parameter.
 *
 */

pragma solidity ^0.8.19;

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
    modifier onlyOwner(uint256 nodeIndex) {
        require(_isOwner(nodeIndex, msg.sender), "Not the owner");
        _;
    }

    modifier canLockX(uint256 nodeIndex) {
        require(_canLockX(tree[nodeIndex].state), "Node is not in a state that allows X locking");
        _;
    }

    modifier canLockS(uint256 nodeIndex) {
        require(_canLockS(tree[nodeIndex].state), "Node is not in a state that allows S locking");
        _;
    }

    modifier canLockIX(uint256 nodeIndex) {
        require(_canLockIX(tree[nodeIndex].state), "Node is not in a state that allows IX locking");
        _;
    }

    modifier canLockIS(uint256 nodeIndex) {
        require(_canLockIS(tree[nodeIndex].state), "Node is not in a state that allows IS locking");
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
    function _addRootNode() private {
        Node memory newNode = Node({state: LockState.Unlocked, owner: address(0), parentIndex: 0});
        tree.push(newNode);
        emit NodeAdded(0, 0);

        // Assertion for invariant: Only one root node exists
        assert(tree[0].parentIndex == 0 && tree.length == 1);
    }

    function _addChildNode(uint256 parentIndex) private {
        Node memory newNode = Node({state: LockState.Unlocked, owner: address(0), parentIndex: parentIndex});
        tree.push(newNode);
        uint256 newNodeIndex = tree.length - 1;
        emit NodeAdded(newNodeIndex, parentIndex);

        // Assertion for invariant: Child node's parent index matches the provided parent index
        assert(tree[newNodeIndex].parentIndex == parentIndex);
    }

    function _lockNode(uint256 nodeIndex, LockState lockState) private {
        tree[nodeIndex].state = lockState;
        tree[nodeIndex].owner = msg.sender;
        emit NodeLocked(nodeIndex, lockState);

        // Assertion for invariant: Node's state and owner should match the recent change
        assert(tree[nodeIndex].state == lockState && tree[nodeIndex].owner == msg.sender);
    }

    function _unlockNode(uint256 nodeIndex) private {
        tree[nodeIndex].state = LockState.Unlocked;
        tree[nodeIndex].owner = address(0);
        emit NodeUnlocked(nodeIndex);

        // Assertion for invariant: Node should be unlocked and ownerless after unlock
        assert(tree[nodeIndex].state == LockState.Unlocked && tree[nodeIndex].owner == address(0));
    }

    // Event Emit
    event NodeAdded(uint256 nodeIndex, uint256 parentIndex);
    event NodeLocked(uint256 nodeIndex, LockState lockedState);
    event NodeUnlocked(uint256 nodeIndex);

    // Combined Functions
    function addRootNode() public rootNodeDoesNotExist {
        _addRootNode();
    }

    function addChildNode(uint256 parentIndex) public isValidParent(parentIndex) {
        _addChildNode(parentIndex);
    }

    function lock(uint256 nodeIndex, LockState lockState) public {
        if (lockState == LockState.X) {
            require(_canLockX(tree[nodeIndex].state), "Node is not in a state that allows X locking");
        } else if (lockState == LockState.S) {
            require(_canLockS(tree[nodeIndex].state), "Node is not in a state that allows S locking");
        } else if (lockState == LockState.IX) {
            require(_canLockIX(tree[nodeIndex].state), "Node is not in a state that allows IX locking");
        } else if (lockState == LockState.IS) {
            require(_canLockIS(tree[nodeIndex].state), "Node is not in a state that allows IS locking");
        }
        _lockNode(nodeIndex, lockState);
    }

    function unlock(uint256 nodeIndex) public onlyOwner(nodeIndex) {
        _unlockNode(nodeIndex);
    }
}
