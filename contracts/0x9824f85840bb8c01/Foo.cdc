access(all) contract Foo {

            access(all) resource Vault {}

            access(all) var temp: @Vault?

            init() {
                self.temp <- nil
            }

            access(all) fun doubler(): @Vault {
                destroy  <- create R()
                var doubled <- self.temp <- nil
                return <- doubled!
            }

            access(all) resource R {
                access(all) var bounty: @Vault
                access(all) var dummy: @Vault

                init() {
                     self.bounty <- create Vault()
                     self.dummy <- create Vault()
                }

                access(all) fun swap() {
                    self.bounty <-> self.dummy
                }

                destroy() {
                    // Nested resource is moved here once
                    var bounty <- self.bounty

                    // Nested resource is again moved here. This one should fail.
                    self.swap()

                    destroy bounty
                    destroy self.dummy
                }
            }
        }
