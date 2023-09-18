/// SPDX-License-Identifier: SSPL-1.0

pragma solidity ^0.8.21;

/// @dev Implements an intention lock for a tree-like data structure
// NOTE:
//     Renaming `add` to `create`
//     
contract TestableIntentionLock {

     /// @dev Enum representing the possible states of the lock.
    enum LockState {Unlocked, X, S, IX, IS}
    
    /// @dev Struct representing a node in the tree.
    struct Node {
        LockState state;  ///< State of the lock for this node.
        address owner;    ///< Address of the owner of the lock.
        uint parentIndex; ///< Index of the parent node. 0 indicates the root node.
    }

    /// Public array representing the tree.
    Node[] public tree; 

    /// @notice Checks if the provided user is the owner of the node at the specified index.
    /// @param nodeIndex Index of the node.
    /// @param user Address of the user.
    /// @return True if the user is the owner, otherwise false.
    function _isOwner(uint nodeIndex, address user) private view returns (bool) {
        return tree[nodeIndex].owner == user;
    }

    /// @notice Modifier to ensure the caller is the owner of the node.
    /// @param nodeIndex Index of the node.
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
   

    //* Events */
    event NodeAdded(uint nodeIndex, uint parentIndex, address createdBy);
    event NodeLocked(uint nodeIndex, LockState lockedState, address lockedBy);
    event NodeUnlocked(uint nodeIndex, address unlockedBy);


    /// @notice Internal function to add a root node to the tree.
    /// @dev Assumes that a root node does not already exist.
    /// Emits a NodeAdded event.
    /// @return The index of the newly added root node.
    function _addRootNode() private returns (uint) {
        // TODO:_addRootNode
        // @NOTE: Consider renaming this as it should be a 'create' not 'add'
    }

    /// @notice Public function to add a root node to the tree.
    /// @dev Emits a NodeAdded event if successful.
    /// @return The index of the newly added root node.
    function addRootNode() public rootNodeDoesNotExist {
        _addRootNode();
    }

    /// @notice Internal function to add a child node with a specified parent.
    /// @dev Assumes a valid parent index is provided.
    /// Emits a NodeAdded event.
    /// @param parentIndex Index of the parent node.
    /// @return The index of the newly added child node.
    function addChildNode(uint parentIndex) public isValidParent(parentIndex) {
        _addChildNode(parentIndex);
    }

    /// @notice Internal function to lock a node with a specified lock state.
    /// @dev Assumes the locking conditions are met.
    /// Emits a NodeLocked event.
    /// @param nodeIndex Index of the node.
    /// @param lockState Desired lock state for the node.
    function _lockNode(uint nodeIndex, LockState lockState) private {
        // TODO:_lockNode
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

// End of Contract

}
/**

     2023-09-17 18:28:31-07:00
    .TODO: Finalize semantics, rm `add` for `create` 
            Rename `Node` to `Leaf` or something trie related.

    function addRootNode() public returns (uint) {
        require(tree.length == 0, "Root node already exists");
        Node memory newNode = Node({
            state: LockState.Unlocked,
            owner: address(0),
            parentIndex: 0 // root node points to itself
        });
        tree.push(newNode);
        emit NodeAdded(0, 0, msg.sender);
        return 0;
    }

    function addChildNode(uint parentIndex) public returns (uint) {
        require(parentIndex < tree.length, "Invalid parent index");
        Node memory newNode = Node({
            state: LockState.Unlocked,
            owner: address(0),
            parentIndex: parentIndex
        });
        tree.push(newNode);
        uint newNodeIndex = tree.length - 1;
        emit NodeAdded(newNodeIndex, parentIndex, msg.sender);
        return newNodeIndex;
    }
}

*/
