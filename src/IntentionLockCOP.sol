// SPDX-License-Identifier: COPYRIGHT 2023 - Sam Bacha
pragma solidity ^0.8.0;

contract IntentionLockCOP {
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

    function _canLockX(LockState state) internal pure returns (bool) {
        return state == LockState.Unlocked;
    }

    function _canLockS(LockState state) internal pure returns (bool) {
        return state == LockState.Unlocked || state == LockState.S;
    }

    function _canLockIX(LockState state) internal pure returns (bool) {
        return state == LockState.Unlocked || state == LockState.IX;
    }

    function _canLockIS(LockState state) internal pure returns (bool) {
        return state == LockState.Unlocked || state == LockState.IS || state == LockState.S;
    }

    function _isRootNodeExist() internal view returns (bool) {
        return tree.length > 0;
    }

    function _isValidParent(uint256 parentIndex) internal view returns (bool) {
        return parentIndex < tree.length;
    }
}
