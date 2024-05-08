/*
	Provides access to a set of metadata views for contracts
	Works the same as MetadataViews.Resolver but for contracts 
 */

access(all)
contract interface CollectionResolver{ 
	access(all)
	fun getViews(): [Type]
	
	access(all)
	fun resolveView(_ view: Type): AnyStruct?
}
