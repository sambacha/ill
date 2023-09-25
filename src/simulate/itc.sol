// SPDX-License-Identifier: COPYRIGHT
// SPDX-License-Identifier: NOT FOR USE
pragma solidity ^0.8.0;

// draft contract for testing against ill
contract ITC {

    /**
     * @dev Represents a node in the interval tree.
     * @param begin The start of the interval.
     * @param end The end of the interval.
     * @param left Pointer to the left child node.
     * @param right Pointer to the right child node.
     */
    struct Node {
        uint256 begin;
        uint256 end;
        address left;
        address right;
    }

    // Mapping from address to Node, allowing us to access nodes using their address as an identifier.
    mapping(address => Node) public nodes;

    // Address of the root node.
    address public rootNode;

    /**
     * @dev Contract constructor that initializes the root node.
     */
    constructor() {
        rootNode = address(this); // Using contract's address as a unique identifier for the root node.
        nodes[rootNode] = Node(0, 1, address(0), address(0));
    }

    /**
     * @dev Splits a given node into two child nodes.
     * @param nodeAddress The address (identifier) of the node to be split.
     */
    function fork(address nodeAddress) public {
        Node storage node = nodes[nodeAddress];
        require(node.left == address(0) && node.right == address(0), "Node already forked");
    
        uint256 mid = (node.begin + node.end) / 2;

        address leftAddress = address(uint160(nodeAddress) + 1); // Create a new unique address for the left node.
        address rightAddress = address(uint160(nodeAddress) + 2); // Create a new unique address for the right node.

        nodes[leftAddress] = Node(node.begin, mid, address(0), address(0));
        nodes[rightAddress] = Node(mid, node.end, address(0), address(0));

        node.left = leftAddress;
        node.right = rightAddress;
    }

    /**
     * @dev Merges two child nodes into a single node.
     * @param parentNodeAddress The address (identifier) of the parent node whose children are to be merged.
     */
    function join(address parentNodeAddress) public {
        Node storage parentNode = nodes[parentNodeAddress];
        require(parentNode.left != address(0) && parentNode.right != address(0), "Node not forked");
    
        delete nodes[parentNode.left];
        delete nodes[parentNode.right];

        parentNode.left = address(0);
        parentNode.right = address(0);
    }

    /**
     * @dev Increments the end of a node's interval.
     * @param nodeAddress The address (identifier) of the node whose interval end is to be incremented.
     */
    function event(address nodeAddress) public {
        Node storage node = nodes[nodeAddress];
        require(node.end < type(uint256).max, "Max value reached");
        node.end += 1;
    }

    /**
     * @dev Retrieves the details of a node.
     * @param nodeAddress The address (identifier) of the node to be retrieved.
     * @return The details of the node.
     */
    function getNode(address nodeAddress) public view returns (Node memory) {
        return nodes[nodeAddress];
    }
}
