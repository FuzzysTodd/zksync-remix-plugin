# Solidity API

## Owner

_Set & change owner_

### Contract
Owner : contracts/2_Owner.sol

Set & change owner

 --- 
### Modifiers:
### isOwner

```solidity
modifier isOwner()
```

 --- 
### Functions:
### constructor

```solidity
constructor() public
```

_Set contract deployer as owner_

### changeOwner

```solidity
function changeOwner(address newOwner) public
```

_Change owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOwner | address | address of new owner |

### getOwner

```solidity
function getOwner() external view returns (address)
```

_Return owner address_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address of owner |

 --- 
### Events:
### OwnerSet

```solidity
event OwnerSet(address oldOwner, address newOwner)
```

