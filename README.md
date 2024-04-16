# cadenceUpgrader

UPDATE:

Ran on mainnet for ~3000 contracts.

## Remaining problems: ( needs manual fix )

- capabilities on private paths
- impure operation on view context 
- dereferencing structs ( metadata etc )
- array mutation


## Usage: 

- put your contracts in to `contracts` directory ( imports should be string imports, see examples )
- run
- upgraded contracts will be on `contractsV1` directory 

it should parse all dependencies and upgrade all needed 


PS: I wrote this in like 2-3 hours, not 100% but works pretty good. some samples in https://github.com/bluesign/cadenceUpgrader/tree/main/test

**NOTE: This doesn't add new entitlements, as is pretty unsecure for complex contracts. **

Upgrading NFT contracts to Cadence 1.0 

Applies few rules are applied: 

- Applies LS suggestions 
- External Interface entitlements
- Internal Interfaces changed to be compatible with external ones
- Metadataview / Resolver updates
- Fixes some castings
- Fixes some references ( auth reference needs etc ) 
- Removes legacy destructors
- Tries to fix function purity ( view )
- Fixes type restrictions
- Implements missing interface functions ( as stubs or preset for NFT etc )
- Fixes &Account references ( link, getCapability, borrow etc )
- Fixes missing labels
- Tries to fix nested references 
- Fixes some invocations
...
  


