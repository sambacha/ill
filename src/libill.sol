/// SPDX-License-Identifier: GPL-2.0-Only

pragma solidity ^0.8.17;

/**
 * @title IntentionLockingLibrary
 * @dev Intention locking for concurrent operations in smart contracts
 */


library IntentionLockingLibrary {
    // ======== Events ========
    event NodeAdded(uint indexed nodeIndex, uint indexed parentIndex);
    event NodeLocked(uint indexed nodeIndex, LockState state, address owner);
    event NodeUnlocked(uint indexed nodeIndex);

    // ======== Enums ========
    enum LockState {
        Unlocked,
        X,      // Exclusive
        S,      // Shared
        IX,     // Intention Exclusive
        IS      // Intention Shared
    }

    // ======== Structs ========
    struct Node {
        LockState state;
        address owner;
        uint parentIndex;
    }

    struct Tree {
        Node[] nodes;
        mapping(bytes32 => uint) pathToIndex;
    }

    // ======== Error Messages ========
    string private constant ERR_NODE_ALREADY_EXISTS = "Node already exists";
    string private constant ERR_NODE_DOES_NOT_EXIST = "Node does not exist";
    string private constant ERR_INVALID_PARENT = "Invalid parent node";
    string private constant ERR_NOT_OWNER = "Caller is not the owner";
    string private constant ERR_CANNOT_LOCK = "Cannot acquire lock";
    string private constant ERR_NODE_LOCKED = "Node is locked";

    // ======== Internal Functions ========

    /**
     * @dev Checks if the node at the given index exists
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     * @return True if the node exists, false otherwise
     */
    function _nodeExists(Tree storage tree, uint nodeIndex) internal view returns (bool) {
        return nodeIndex < tree.nodes.length;
    }

    /**
     * @dev Checks if the node is owned by the given address
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     * @param owner The address to check against
     * @return True if the node is owned by the address, false otherwise
     */
    function _isOwner(Tree storage tree, uint nodeIndex, address owner) internal view returns (bool) {
        return tree.nodes[nodeIndex].owner == owner;
    }

    /**
     * @dev Checks if the node can be locked in X state
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     * @return True if the node can be locked in X state, false otherwise
     */
    function _canLockX(Tree storage tree, uint nodeIndex) internal view returns (bool) {
        LockState currentState = tree.nodes[nodeIndex].state;
        return currentState == LockState.Unlocked;
    }

    /**
     * @dev Checks if the node can be locked in S state
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     * @return True if the node can be locked in S state, false otherwise
     */
    function _canLockS(Tree storage tree, uint nodeIndex) internal view returns (bool) {
        LockState currentState = tree.nodes[nodeIndex].state;
        return currentState == LockState.Unlocked || 
               currentState == LockState.S || 
               currentState == LockState.IS;
    }

    /**
     * @dev Checks if the node can be locked in IX state
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     * @return True if the node can be locked in IX state, false otherwise
     */
    function _canLockIX(Tree storage tree, uint nodeIndex) internal view returns (bool) {
        LockState currentState = tree.nodes[nodeIndex].state;
        return currentState == LockState.Unlocked || 
               currentState == LockState.IX || 
               currentState == LockState.IS;
    }

    /**
     * @dev Checks if the node can be locked in IS state
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     * @return True if the node can be locked in IS state, false otherwise
     */
    function _canLockIS(Tree storage tree, uint nodeIndex) internal view returns (bool) {
        LockState currentState = tree.nodes[nodeIndex].state;
        return currentState == LockState.Unlocked || 
               currentState == LockState.S || 
               currentState == LockState.IS || 
               currentState == LockState.IX;
    }

    /**
     * @dev Validates that a node exists
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     */
    function _requireNodeExists(Tree storage tree, uint nodeIndex) internal view {
        require(_nodeExists(tree, nodeIndex), ERR_NODE_DOES_NOT_EXIST);
    }

    /**
     * @dev Validates that a node doesn't exist
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     */
    function _requireNodeDoesNotExist(Tree storage tree, uint nodeIndex) internal view {
        require(!_nodeExists(tree, nodeIndex), ERR_NODE_ALREADY_EXISTS);
    }

    /**
     * @dev Validates that a node is owned by a specific address
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     * @param owner The address to check against
     */
    function _requireIsOwner(Tree storage tree, uint nodeIndex, address owner) internal view {
        require(_isOwner(tree, nodeIndex, owner), ERR_NOT_OWNER);
    }

    /**
     * @dev Validates that a parent node exists
     * @param tree The tree structure
     * @param parentIndex The index of the parent node
     */
    function _requireValidParent(Tree storage tree, uint parentIndex) internal view {
        if (parentIndex != 0) { // 0 is allowed for root nodes
            _requireNodeExists(tree, parentIndex);
        }
    }

    /**
     * @dev Validates that a node can be locked in X state
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     */
    function _requireCanLockX(Tree storage tree, uint nodeIndex) internal view {
        require(_canLockX(tree, nodeIndex), ERR_CANNOT_LOCK);
    }

    /**
     * @dev Validates that a node can be locked in S state
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     */
    function _requireCanLockS(Tree storage tree, uint nodeIndex) internal view {
        require(_canLockS(tree, nodeIndex), ERR_CANNOT_LOCK);
    }

    /**
     * @dev Validates that a node can be locked in IX state
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     */
    function _requireCanLockIX(Tree storage tree, uint nodeIndex) internal view {
        require(_canLockIX(tree, nodeIndex), ERR_CANNOT_LOCK);
    }

    /**
     * @dev Validates that a node can be locked in IS state
     * @param tree The tree structure
     * @param nodeIndex The index of the node to check
     */
    function _requireCanLockIS(Tree storage tree, uint nodeIndex) internal view {
        require(_canLockIS(tree, nodeIndex), ERR_CANNOT_LOCK);
    }

    /**
     * @dev Performs the actual locking of a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node to lock
     * @param state The lock state to apply
     * @param owner The address of the lock owner
     */
    function _performLock(
        Tree storage tree, 
        uint nodeIndex, 
        LockState state, 
        address owner
    ) internal {
        tree.nodes[nodeIndex].state = state;
        tree.nodes[nodeIndex].owner = owner;
        emit NodeLocked(nodeIndex, state, owner);
    }

    /**
     * @dev Performs the actual unlocking of a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node to unlock
     */
    function _performUnlock(Tree storage tree, uint nodeIndex) internal {
        tree.nodes[nodeIndex].state = LockState.Unlocked;
        tree.nodes[nodeIndex].owner = address(0);
        emit NodeUnlocked(nodeIndex);
    }

    /**
     * @dev Adds a node to the tree
     * @param tree The tree structure
     * @param parentIndex The index of the parent node
     * @param path The unique path to identify the node
     * @return The index of the newly added node
     */
    function _addNode(
        Tree storage tree, 
        uint parentIndex, 
        bytes32 path
    ) internal returns (uint) {
        uint nodeIndex = tree.nodes.length;
        tree.nodes.push(Node({
            state: LockState.Unlocked,
            owner: address(0),
            parentIndex: parentIndex
        }));
        tree.pathToIndex[path] = nodeIndex;
        emit NodeAdded(nodeIndex, parentIndex);
        return nodeIndex;
    }

    /**
     * @dev Gets the ancestors of a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node
     * @return An array of node indices representing the ancestors
     */
    function _getAncestors(
        Tree storage tree, 
        uint nodeIndex
    ) internal view returns (uint[] memory) {
        // Count ancestors first
        uint count = 0;
        uint current = nodeIndex;
        
        while (current != 0) {
            current = tree.nodes[current].parentIndex;
            count++;
        }
        
        // Populate ancestors array
        uint[] memory ancestors = new uint[](count);
        current = nodeIndex;
        uint index = 0;
        
        while (current != 0) {
            current = tree.nodes[current].parentIndex;
            ancestors[index] = current;
            index++;
        }
        
        return ancestors;
    }

    // ======== Public Functions ========

    /**
     * @dev Adds a root node to the tree
     * @param tree The tree structure
     * @param path The unique path to identify the node
     * @return The index of the newly added node
     */
    function addRootNode(
        Tree storage tree,
        bytes32 path
    ) public returns (uint) {
        // Check if a node with this path already exists
        require(tree.pathToIndex[path] == 0, ERR_NODE_ALREADY_EXISTS);
        
        return _addNode(tree, 0, path);
    }

    /**
     * @dev Adds a child node to the tree
     * @param tree The tree structure
     * @param parentIndex The index of the parent node
     * @param path The unique path to identify the node
     * @return The index of the newly added node
     */
    function addChildNode(
        Tree storage tree,
        uint parentIndex,
        bytes32 path
    ) public returns (uint) {
        // Check if a node with this path already exists
        require(tree.pathToIndex[path] == 0, ERR_NODE_ALREADY_EXISTS);
        
        // Ensure parent exists
        _requireNodeExists(tree, parentIndex);
        
        return _addNode(tree, parentIndex, path);
    }

    /**
     * @dev Acquires an X (exclusive) lock on a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node to lock
     */
    function lockX(
        Tree storage tree,
        uint nodeIndex
    ) public {
        _requireNodeExists(tree, nodeIndex);
        _requireCanLockX(tree, nodeIndex);
        
        // Lock ancestors with IX
        uint[] memory ancestors = _getAncestors(tree, nodeIndex);
        for (uint i = 0; i < ancestors.length; i++) {
            _requireCanLockIX(tree, ancestors[i]);
            _performLock(tree, ancestors[i], LockState.IX, msg.sender);
        }
        
        // Lock the node with X
        _performLock(tree, nodeIndex, LockState.X, msg.sender);
    }

    /**
     * @dev Acquires an S (shared) lock on a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node to lock
     */
    function lockS(
        Tree storage tree,
        uint nodeIndex
    ) public {
        _requireNodeExists(tree, nodeIndex);
        _requireCanLockS(tree, nodeIndex);
        
        // Lock ancestors with IS
        uint[] memory ancestors = _getAncestors(tree, nodeIndex);
        for (uint i = 0; i < ancestors.length; i++) {
            _requireCanLockIS(tree, ancestors[i]);
            _performLock(tree, ancestors[i], LockState.IS, msg.sender);
        }
        
        // Lock the node with S
        _performLock(tree, nodeIndex, LockState.S, msg.sender);
    }

    /**
     * @dev Acquires an IX (intention exclusive) lock on a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node to lock
     */
    function lockIX(
        Tree storage tree,
        uint nodeIndex
    ) public {
        _requireNodeExists(tree, nodeIndex);
        _requireCanLockIX(tree, nodeIndex);
        
        // Lock ancestors with IX
        uint[] memory ancestors = _getAncestors(tree, nodeIndex);
        for (uint i = 0; i < ancestors.length; i++) {
            _requireCanLockIX(tree, ancestors[i]);
            _performLock(tree, ancestors[i], LockState.IX, msg.sender);
        }
        
        // Lock the node with IX
        _performLock(tree, nodeIndex, LockState.IX, msg.sender);
    }

    /**
     * @dev Acquires an IS (intention shared) lock on a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node to lock
     */
    function lockIS(
        Tree storage tree,
        uint nodeIndex
    ) public {
        _requireNodeExists(tree, nodeIndex);
        _requireCanLockIS(tree, nodeIndex);
        
        // Lock ancestors with IS
        uint[] memory ancestors = _getAncestors(tree, nodeIndex);
        for (uint i = 0; i < ancestors.length; i++) {
            _requireCanLockIS(tree, ancestors[i]);
            _performLock(tree, ancestors[i], LockState.IS, msg.sender);
        }
        
        // Lock the node with IS
        _performLock(tree, nodeIndex, LockState.IS, msg.sender);
    }

    /**
     * @dev Unlocks a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node to unlock
     */
    function unlock(
        Tree storage tree,
        uint nodeIndex
    ) public {
        _requireNodeExists(tree, nodeIndex);
        _requireIsOwner(tree, nodeIndex, msg.sender);
        
        _performUnlock(tree, nodeIndex);
    }

    /**
     * @dev Get the lock state of a node
     * @param tree The tree structure
     * @param nodeIndex The index of the node
     * @return The current lock state
     */
    function getLockState(
        Tree storage tree,
        uint nodeIndex
    ) public view returns (LockState) {
        _requireNodeExists(tree, nodeIndex);
        return tree.nodes[nodeIndex].state;
    }

    /**
     * @dev Get the owner of a node's lock
     * @param tree The tree structure
     * @param nodeIndex The index of the node
     * @return The current owner
     */
    function getLockOwner(
        Tree storage tree,
        uint nodeIndex
    ) public view returns (address) {
        _requireNodeExists(tree, nodeIndex);
        return tree.nodes[nodeIndex].owner;
    }

    /**
     * @dev Gets the node index for a given path
     * @param tree The tree structure
     * @param path The path to lookup
     * @return The index of the node
     */
    function getNodeIndex(
        Tree storage tree,
        bytes32 path
    ) public view returns (uint) {
        uint nodeIndex = tree.pathToIndex[path];
        _requireNodeExists(tree, nodeIndex);
        return nodeIndex;
    }

    /**
     * @dev Checks if a path exists in the tree
     * @param tree The tree structure
     * @param path The path to check
     * @return True if the path exists, false otherwise
     */
    function pathExists(
        Tree storage tree,
        bytes32 path
    ) public view returns (bool) {
        uint nodeIndex = tree.pathToIndex[path];
        return _nodeExists(tree, nodeIndex);
    }
}
