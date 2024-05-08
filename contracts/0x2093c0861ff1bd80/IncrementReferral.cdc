/**

# Contract for managing on-chain referral relationships.

# Author: Increment Labs

*/

import LendingInterfaces from "../0x2df970b6cdee5735/LendingInterfaces.cdc"

pub contract IncrementReferral {
    // Struct to hold referee information, including the referee's address and the timestamp when they were bound.
    access(all) struct RefereeInfo {
        access(all) let refereeAddr: Address
        access(all) let bindTimestamp: UFix64
        init(_ addr: Address, _ timestamp: UFix64) {
            self.refereeAddr = addr
            self.bindTimestamp = timestamp
        }
    }
    
    // A dictionary mapping referrers to an array of RefereeInfo, tracking all referees bound to each referrer.
    // {Referrer : {Referee: BindingTime} }
    access(self) let _referrerToReferees: {Address: [RefereeInfo]}

    // A dictionary mapping referees to their respective referrers, allowing for lookup of a referee's referrer.
    // {Referee: Referrer}
    access(self) let _refereeToReferrer: {Address: Address}

    /// Events
    access(all) event BindingReferrer(referrer: Address, referee: Address, indexer: Int)

    // Function to bind a referee to a referrer.
    // Requires the referrer's address and a capability to fetch the referee's address from an identity certificate.
    access(all) fun bind(referrer: Address, refereeCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>) {
        let referee: Address = refereeCertificateCap.borrow()!.owner!.address

        assert(self._refereeToReferrer.containsKey(referee) == false, message: "Referrer already bound")
        assert(referee != referrer, message: "Can't bind yourself")

        self._refereeToReferrer[referee] = referrer
        if self._referrerToReferees.containsKey(referrer) == false {
            self._referrerToReferees[referrer] = []
        }
        self._referrerToReferees[referrer]!.append(RefereeInfo(referee, getCurrentBlock().timestamp))

        // Prevent circular binding
        //assert(self.checkCirularBinding(referee: referee) == false, message: "Cirular Binding")
        
        emit BindingReferrer(referrer: referrer, referee: referee, indexer: self._referrerToReferees[referrer]!.length)
    }

    // Function to check for circular bindings in the referral structure.
    access(self) fun checkCirularBinding(referee: Address): Bool {
        let checkedAddrs: {Address: Bool} = {referee: true}
        var i = 0
        var addr = referee
        while i < 32 {
            if self._refereeToReferrer.containsKey(addr) == false {
                return false
            }
            let nextAddr = self._refereeToReferrer[addr]!
            if checkedAddrs.containsKey(nextAddr) == true {
                return true
            }
            checkedAddrs[nextAddr] = true
            addr = nextAddr
            i = i + 1
        }
        return false
    }

    access(all) fun getReferrerByReferee(referee: Address): Address? {
        if self._refereeToReferrer.containsKey(referee) == false {
            return nil
        }
        return self._refereeToReferrer[referee]!
    }

    access(all) view fun getReferrerCount(): Int {
        return self._referrerToReferees.length
    }

    access(all) view fun getSlicedReferrerList(from: Int, to: Int): [Address] {
        let len = self._referrerToReferees.length
        let upTo = to > len ? len : to
        return self._referrerToReferees.keys.slice(from: from, upTo: upTo)
    }

    access(all) view fun getRefereeCountByReferrer(referrer: Address): Int {
        return self._referrerToReferees.containsKey(referrer) ? self._referrerToReferees[referrer]!.length : 0
    }

    access(all) view fun getSlicedRefereesByReferrer(referrer: Address, from: Int, to: Int): [RefereeInfo] {
        if self._referrerToReferees.containsKey(referrer) == false {
            return []
        }
        let len = self._referrerToReferees[referrer]!.length
        let endIndex = to > len ? len : to
        return self._referrerToReferees[referrer]!.slice(from: from, upTo: endIndex)
    }

    /// Admin
    ///
    access(all) resource Admin {

    }

    init() {
        self._referrerToReferees = {}
        self._refereeToReferrer = {}

        destroy <-self.account.load<@AnyResource>(from: /storage/referralAdmin)
        self.account.save(<-create Admin(), to: /storage/referralAdmin)
    }
}
