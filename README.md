# cadenceUpgrader

PS: I wrote this in like 2-3 hours, not 100% but works pretty good. some samples in https://github.com/bluesign/cadenceUpgrader/tree/main/test

**NOTE: This doesn't add new entitlements, as is pretty unsecure for complex contracts. **

Upgrading NFT contracts to Cadence 1.0 

Applies few rules are applied: 

- LS suggestions 
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
  


