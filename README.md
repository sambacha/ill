# [ill](https://github.com/sambacha/ill/edit/master/README.md)

> intention locking conditional state library


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

