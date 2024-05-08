import Vevent from "./Vevent.cdc"
import Wearables from "../0xe81193c424cfd3fb/Wearables.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract VeventVerifiers {

    pub struct DoodlesSock: Vevent.Verifier {
        pub fun verify(user: Address): Bool {
            if let collection = getAccount(user).getCapability(Wearables.CollectionPublicPath).borrow<&Wearables.Collection{MetadataViews.ResolverCollection}>() {
                for id in collection.getIDs() {
                    let resolver = collection.borrowViewResolver(id: id)
                    let view = resolver.resolveView(Type<Wearables.Metadata>())! as! Wearables.Metadata
                    let template = Wearables.templates[view.templateId]!
                    let name = template.name
                    if name == "crew socks" {
                        return true
                    }
                }
            }
            return false
        }
    }

}