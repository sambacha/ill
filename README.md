# [ill](https://github.com/sambacha/ill/edit/master/README.md)

> inductive (intention) locking conditional state library


`ill` implements a concurrent tree-like data structure, specifically a trie, where intermediary nodes represent prefixes of larger strings. The system aims to allow concurrent read and write access to strings in the trie. There's a need for locking not just the leaves (entire strings) but also intermediary nodes (prefixes of strings). 

### Invariants

The main challenge is to ensure concurrent access without violating two invariants:

1. The owning thread can access any part of a node's subtree without additional locks.
2. Other threads shouldn't be blocked from independent operations on different parts of the tree.

A global reader-writer lock would easily ensure the first invariant but not the second. The solution proposed is to use _intention locks_ while traversing the prefix tree. 

**ill Locks:**

- Intention locks are similar to reader-writer locks with multiple states.
- States `S` (Shared) and `X` (Exclusive) are the primary states. A node in `S` or `X` implies all its descendants are similarly set.
- Provisional intention states: `IS` (Intention to Share) and `IX` (Intention for Exclusive access) are introduced.
  - `IS` allows a thread to continue traversing and set subsequent nodes to `IS` or `S`.
  - `IX` allows a thread to continue traversing and set subsequent nodes to `IX` or `X`.
  - `SIX` (Intention to Share and upgrade to IX) is mentioned but not implemented in this context.
  
To lock a node in shared mode, all its ancestors are set to `IS` and the node itself to `S`. For exclusive mode, all ancestors are set to `IX` and the node to `X`.

**Transition Matrix for Lock States:**

| Request/Holding | Unlocked | Holding X | Holding S | Holding IX | Holding IS |
|-----------------|----------|-----------|-----------|------------|------------|
| Request X       | Yes      | No        | No        | No         | No         |
| Request S       | Yes      | No        | Yes       | No         | Yes        |
| Request IX      | Yes      | No        | No        | Yes        | Yes        |
| Request IS      | Yes      | No        | Yes       | Yes        | Yes        |

>**Note**
> This matrix shows the allowed transitions between lock states. If a transition is not allowed, the caller MUST block.

### Design

<!-- NOTES:

- Potential bugs hide when the programmer believes a conditional (and thus the state it projects onto) means one thing when in fact it means something subtly different.

State-transitions which allow interesting operational dynamics. To achieve it, we try to split all conditions apart from the state-transitions that they guard. We name each independently and combine to form real functions.
The problem with such conditional paths within transition logic is that they add conceptual non-linearity over state semantics. 
- Function bodies should have no conditional paths.   
- Never mix transitions with conditions.   
-->

Abstract the condition and create a function modifier for this condition.      

Explicitly enumerate all such conditionals.   

Logic becomes flattened into non-conditional state-transactions.     

#### Base case
We show that there exists some state that is locked.       

#### Inductive case
Given an arbitrary locked starting state (our inductive hypothesis), we show that the state remains locked after transition.    

#### Assumptions
We assume that the user is not the contract itself.     

### Specification

We must precisely model reentrancy (i.e. interprocedural control flow) so that we can then formalize each of these state transitions as a guarded transition rule. 

Each rule takes the form:
  
$$ (state, parameters) | condition → new_state $$


where 

`state` and `new_state` are state tuples     

`parameters` is a tuple of arguments for the transition     and 
`condition` is a predicate required for the transition to be valid.

These rules should hold for the following functions: `lockX`, `lockS`, `lockIX`, `lockIS`

### Modifiers

| Name                 | Description                       |
|----------------------|-----------------------------------|
| onlyOwner            | Checks caller is owner of node    |
| canLockX             | Checks if X lock can be acquired  |
| canLockS             | Checks if S lock can be acquired  |
| canLockIX            | Checks if IX lock can be acquired |
| canLockIS            | Checks if IS lock can be acquired |
| rootNodeDoesNotExist | Checks root node does not exist   |
| isValidParent        | Checks parent node index is valid |

### Events

| Name         | Description                     |
|--------------|---------------------------------|
| NodeAdded    | Emitted when a node is added    |
| NodeLocked   | Emitted when a node is locked   |
| NodeUnlocked | Emitted when a node is unlocked |


## External Functions

| Name         | Description      |
|--------------|------------------|
| addRootNode  | Adds root node   |
| addChildNode | Adds child node  |
| lockX        | Acquires X lock  |
| lockS        | Acquires S lock  |
| lockIX       | Acquires IX lock |
| lockIS       | Acquires IS lock |
| unlock       | Unlocks a node   |

## Internal Functions

| Name          | Description                                    |
|---------------|------------------------------------------------|
| _addRootNode  | Adds the root node                             |
| _addChildNode | Adds a child node                              |
| _lockNode     | Transitions a node to the specified lock state |
| _unlockNode   | Unlocks a node                                 |


## Data Model


#### Enum: `LockState`

This enum represents the possible states of the lock for a node.

| Value    | Description                                       |
|----------|---------------------------------------------------|
| Unlocked | The node is not locked by any user.               |
| X        | The node is exclusively locked by a user.         |
| S        | The node is shared, allowing concurrent reads.    |
| IX       | Intention for exclusive access.                   |
| IS       | Intention to share.                               |



####  Struct: `Node`

This struct represents a node in the tree-like data structure.

| Field        | Type     | Description                                        |
|--------------|----------|----------------------------------------------------|
| `state`      | LockState | The current state of the lock for this node.        |
| `owner`      | address  | The Ethereum address of the owner of the lock.      |
| `parentIndex`| uint     | The index of the parent node. 0 indicates root node.|


#### Array: `tree`

This dynamic array represents the tree-like structure, where each element is a `Node`. The index of an element in this array serves as its unique identifier.

| Index | Value |
|-------|-------|
| 0     | Root node of the tree (if it exists). |
| 1...n | Other nodes in the tree. The order of addition determines the index. |

