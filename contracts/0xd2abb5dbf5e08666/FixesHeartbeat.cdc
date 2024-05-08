/**
> Author: FIXeS World <https://fixes.world/>

# FixesHeartbeat

TODO: Add description

*/

/// The `FixesHeartbeat` contract
///
access(all) contract FixesHeartbeat {
    /* --- Events --- */
    /// Event emitted when the contract is initialized
    access(all) event ContractInitialized()
    /// Event emitted when a hook is added
    access(all) event HookAdded(scope: String, hookAddr: Address, hookType: Type)
    /// Event emitted when a hook is removed
    access(all) event HookRemoved(scope: String, hookAddr: Address)
    /// Event emitted when the heartbeat time is updated
    access(all) event HeartbeatExecuted(scope: String, lastHeartbeatTime: UFix64, deltaTime: UFix64)

    /* --- Variable, Enums and Structs --- */

    access(all)
    let storagePath: StoragePath

    /// Record the last heartbeat time of each scope
    /// Scope => Last Heartbeat Time
    access(all)
    let lastHeartbeatTime: {String: UFix64}

    /// Record the hooks of each scope
    /// Scope => Hooks' Addresses
    access(all)
    let heartbeatScopes: {String: {Address: PublicPath}}

    /// The minimum interval between two heartbeats
    access(all)
    var heartbeatMinInterval: UFix64

    /* --- Interfaces & Resources --- */

    /// The interface that all the hooks must implement
    ///
    access(all) resource interface IHeartbeatHook {
        /// The methods that is invoked when the heartbeat is executed
        /// Before try-catch is deployed, please ensure that there will be no panic inside the method.
        ///
        access(account)
        fun onHeartbeat(_ deltaTime: UFix64)
    }

    /// Heartbeat resource, provides the heartbeat function
    /// The heartbeat function will invoke all the hooks that are bound to the specified scope
    /// The heartbeatTime is the time when the heartbeat function is invoked, it is stored in the contract storage
    /// The deltaTime is the time interval between the last heartbeat and the current heartbeat
    ///
    access(all) resource Heartbeat {
        /// The heartbeat function
        ///
        /// - Parameter scope: The scope of the heartbeat
        ///
        access(all)
        fun tick(scope: String) {
            pre {
                FixesHeartbeat.heartbeatScopes[scope] != nil: "The scope does not exist"
            }
            if let hooks = FixesHeartbeat.borrowHooksDictRef(scope: scope) {
                let now = getCurrentBlock().timestamp
                let lastHeartbeatTime = FixesHeartbeat.lastHeartbeatTime[scope] ?? (now - FixesHeartbeat.heartbeatMinInterval)
                let deltaTime = now - lastHeartbeatTime
                // Check if the interval is too short
                if deltaTime < FixesHeartbeat.heartbeatMinInterval {
                    return
                }

                // iterate all the hooks
                for hookAddr in hooks.keys {
                    if let hookRef = getAccount(hookAddr)
                        .getCapability<&AnyResource{IHeartbeatHook}>(hooks[hookAddr]!)
                        .borrow()
                    {
                        hookRef.onHeartbeat(deltaTime)
                    }
                }

                // Update the last heartbeat time
                FixesHeartbeat.lastHeartbeatTime[scope] = now

                // Emit the event
                emit HeartbeatExecuted(scope: scope, lastHeartbeatTime: now, deltaTime: deltaTime)
            }
        }
    }

    /// Borrow the hook dictionary reference
    ///
    access(contract)
    fun borrowHooksDictRef(scope: String): &{Address: PublicPath}? {
        return &self.heartbeatScopes[scope] as &{Address: PublicPath}?
    }

    /** --- Account Level Functions --- */

    /// Add a hook to the specified scope
    ///
    /// - Parameter scope: The scope of the hook
    /// - Parameter hook: The hook to be added
    ///
    access(account)
    fun addHook(scope: String, hookAddr: Address, hookPath: PublicPath) {
        // Check if the scope exists
        if self.heartbeatScopes[scope] == nil {
            self.heartbeatScopes[scope] = {}
        }
        let hookCap = getAccount(hookAddr)
            .getCapability<&{IHeartbeatHook}>(hookPath)
        if hookCap.check() {
            if let hookRef = hookCap.borrow() {
                let scopesRef = (self.borrowHooksDictRef(scope: scope))!
                // check if the hook is already added
                if scopesRef[hookAddr] != nil {
                    return
                }
                // Add the hook
                scopesRef[hookAddr] = hookPath
                // Emit the event
                emit HookAdded(scope: scope, hookAddr: hookAddr, hookType: hookRef.getType())
            }
        }
    }

    /// Remove a hook from the specified scope
    ///
    access(account)
    fun removeHook(scope: String, hookAddr: Address) {
        if let hooks = FixesHeartbeat.borrowHooksDictRef(scope: scope) {
            hooks.remove(key: hookAddr)

            // Emit the event
            emit HookRemoved(scope: scope, hookAddr: hookAddr)
        }
    }

    /* --- Public Functions --- */

    /// Create a new Heartbeat resource
    ///
    access(all)
    fun create(): @Heartbeat {
        return <-create Heartbeat()
    }

    /// Check if the hook is added to the specified scope
    ///
    access(all)
    fun hasHook(scope: String, hookAddr: Address): Bool {
        if let hooks = FixesHeartbeat.borrowHooksDictRef(scope: scope) {
            return hooks[hookAddr] != nil
        }
        return false
    }

    init() {
        let identifier = "FixesHeartbeat_".concat(self.account.address.toString())
        self.storagePath  = StoragePath(identifier: identifier)!

        self.lastHeartbeatTime = {}
        self.heartbeatScopes = {}

        // Set the default minimum interval between two heartbeats
        // 60 seconds
        self.heartbeatMinInterval = 60.0

        // Register the hooks

        emit ContractInitialized()
    }
}
