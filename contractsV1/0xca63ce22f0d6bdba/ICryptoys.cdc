import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract interface ICryptoys{ 
	access(all)
	struct interface Royalty{ 
		access(all)
		let name: String
		
		access(all)
		let address: Address
		
		access(all)
		let fee: UFix64
	}
	
	access(all)
	struct interface Display{ 
		access(all)
		let image: String
		
		access(all)
		let video: String
	}
	
	access(all)
	resource interface INFT{ 
		access(all)
		let id: UInt64
		
		access(account)
		let metadata:{ String: String}
		
		access(account)
		let royalties: [String]
		
		access(account)
		let bucket: @{String:{ UInt64:{ INFT}}}
		
		access(all)
		fun getMetadata():{ String: String}
		
		access(all)
		fun getDisplay():{ ICryptoys.Display}
		
		access(all)
		fun getRoyalties(): [{ICryptoys.Royalty}]
		
		access(account)
		fun withdrawBucketItem(_ key: String, _ itemUuid: UInt64): @{ICryptoys.INFT}{ 
			pre{ 
				self.owner != nil:
					"withdrawBucketItem() failed: nft resource must be in a collection"
			}
			post{ 
				result == nil || result.uuid == itemUuid:
					"Cannot withdraw bucket Cryptoy reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun addToBucket(_ key: String, _ nft: @{INFT}){ 
			pre{ 
				self.owner != nil:
					"addToBucket() failed: nft resource must be in a collection"
			}
		}
		
		access(all)
		fun getBucketKeys(): [String]
		
		access(all)
		fun getBucketResourceIdsByKey(_ key: String): [UInt64]
		
		access(all)
		fun borrowBucketResourcesByKey(_ key: String): &{UInt64:{ ICryptoys.INFT}}?
		
		access(all)
		fun borrowBucket(): &{String:{ UInt64:{ ICryptoys.INFT}}}
		
		access(all)
		fun borrowBucketItem(_ key: String, _ itemUuid: UInt64): &{INFT}{ 
			post{ 
				result == nil || result.uuid == itemUuid:
					"Cannot borrow bucket Cryptoy reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	access(all)
	resource interface CryptoysCollectionPublic{ 
		access(all)
		fun borrowCryptoy(id: UInt64): &{INFT}{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result.id == id:
					"Cannot borrow Cryptoy reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun borrowBucketItem(_ id: UInt64, _ key: String, _ itemUuid: UInt64): &{ICryptoys.INFT}{ 
			post{ 
				result == nil || result.uuid == itemUuid:
					"Cannot borrow bucket Cryptoy reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource interface Collection{ 
		access(all)
		fun withdrawBucketItem(parentId: UInt64, key: String, itemUuid: UInt64): @{ICryptoys.INFT}
	}
}
