/// Pausable
///
/// The interface that pausable contracts implement.
///
access(all)
contract interface Pausable{ 
	/// paused
	/// If current contract is paused
	///
	access(contract)
	var paused: Bool
	
	/// Paused
	///
	/// Emitted when the pause is triggered.
	access(all)
	event Paused()
	
	/// Unpaused
	///
	/// Emitted when the pause is lifted.
	access(all)
	event Unpaused()
	
	/// Pausable Checker
	/// 
	/// some methods to check if paused
	/// 
	access(all)
	resource interface Checker{ 
		/// Returns true if the contract is paused, and false otherwise.
		///
		access(all)
		view fun paused(): Bool
		
		/// a function callable only when the contract is not paused.
		/// 
		/// Requirements:
		/// - The contract must not be paused.
		///
		access(contract)
		fun whenNotPaused(){ 
			pre{ 
				!self.paused():
					"Pausable: paused"
			}
		}
		
		/// a function callable only when the contract is paused.
		/// 
		/// Requirements:
		/// - The contract must be paused.
		///
		access(contract)
		fun whenPaused(){ 
			pre{ 
				self.paused():
					"Pausable: not paused"
			}
		}
	}
	
	/// Puasable Pauser
	///
	access(all)
	resource interface Pauser{ 
		/// pause
		/// 
		access(all)
		fun pause()
		
		/// unpause
		///
		access(all)
		fun unpause()
	}
}
