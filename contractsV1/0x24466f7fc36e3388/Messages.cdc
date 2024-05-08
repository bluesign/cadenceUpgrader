access(all)
contract Messages{ 
	// Events
	access(all)
	event MessageCreated(user_id: UInt32, address: Address)
	
	// Paths
	access(all)
	let TicketsCommentVaultPublicPath: PublicPath
	
	// Variants
	access(self)
	var totalMessagesIds: UInt256
	
	// Objects
	access(all)
	let messages:{ Address: MessagesStruct}
	
	/*
	  ** [Struct] MessagesStruct
	  */
	
	access(all)
	struct MessagesStruct{ 
		access(all)
		var upvote_tickets: [Address]
		
		access(all)
		var commented_ids: [UInt256]
		
		access(all)
		var got_comments: [CommentsStruct]
		
		access(all)
		var got_upvote: Int256
		
		init(
			addr: Address,
			ticket_addr: Address?,
			comment: String,
			is_comment: Bool,
			message_id: UInt256?,
			is_organizer: Bool
		){ 
			if is_organizer == true{ 
				self.upvote_tickets = []
				self.commented_ids = []
			} else if is_comment == true{ 
				self.upvote_tickets = []
				self.commented_ids = [message_id!]
			} else{ 
				self.upvote_tickets = [ticket_addr!]
				self.commented_ids = []
			}
			self.got_comments = []
			self.got_upvote = 0
		}
	}
	
	/*
	  ** [Struct] CommentsStruct
	  */
	
	access(all)
	struct CommentsStruct{ 
		access(all)
		let comment: String
		
		access(all)
		let time: UFix64 // Time
		
		
		access(all)
		let message_id: UInt256
		
		init(comment: String, time: UFix64){ 
			self.message_id = Messages.totalMessagesIds + 1
			Messages.totalMessagesIds = Messages.totalMessagesIds + 1
			self.comment = comment
			self.time = time
		}
	}
	
	/*
	  ** [Interface] IMessagesPrivate
	  */
	
	access(all)
	resource interface IMessagesPrivate{ 
		access(all)
		fun addMessages(addr: Address, ticket_addr: Address, comment: String, is_comment: Bool)
		
		access(all)
		fun updateMessages(
			addr: Address,
			ticket_addr: Address,
			index: UInt32,
			comment: String,
			is_comment: Bool
		)
	}
	
	/*
	  ** [Resource] MessagesVault
	  */
	
	access(all)
	resource MessagesVault: IMessagesPrivate{ 
		
		// [private access]
		access(all)
		fun addMessages(addr: Address, ticket_addr: Address, comment: String, is_comment: Bool){ 
			let time = getCurrentBlock().timestamp
			var commentSt: CommentsStruct? = nil
			if let data = Messages.messages[addr]{ 
				// User
				if is_comment == true{ 
					commentSt = CommentsStruct(comment: comment, time: time)
					(Messages.messages[addr]!).commented_ids.append((commentSt!).message_id)
				} else{ 
					(Messages.messages[addr]!).upvote_tickets.append(ticket_addr)
				}
				
				// Organizer
				if let data = Messages.messages[ticket_addr]{ 
					if is_comment == true{ 
						data.got_comments.append(commentSt!)
					} else{ 
						data.got_upvote = data.got_upvote + 1
					}
					Messages.messages[ticket_addr] = data
				} else{ 
					let message = MessagesStruct(addr: ticket_addr, ticket_addr: nil, comment: comment, is_comment: is_comment, message_id: nil, is_organizer: false)
					if is_comment == true{ 
						message.got_comments.append(commentSt!)
					} else{ 
						message.got_upvote = 1
					}
					Messages.messages[ticket_addr] = message
				}
			}
		}
		
		// [private access]
		access(all)
		fun updateMessages(addr: Address, ticket_addr: Address, index: UInt32, comment: String, is_comment: Bool){ 
			if let data = Messages.messages[addr]{ 
				if is_comment == true{ 
					// Organizer
					let existComment = (Messages.messages[ticket_addr]!).got_comments.remove(at: index)
					let newComment = CommentsStruct(comment: comment, time: existComment.time)
					(Messages.messages[ticket_addr]!).got_comments.insert(at: index, newComment)
					(					 // User
					 Messages.messages[addr]!).commented_ids.append(newComment.message_id)
				} else{ 
					(					 // User
					 Messages.messages[addr]!).upvote_tickets.remove(at: index)
					// Organizer
					if let organizerData = Messages.messages[ticket_addr]{ 
						organizerData.got_upvote = organizerData.got_upvote - 1
						Messages.messages[ticket_addr] = organizerData
					}
				}
			}
		}
		
		init(addr: Address, ticket_addr: Address, comment: String, is_comment: Bool){ 
			pre{ 
				Messages.messages[addr] == nil:
					"This address already has vault"
			}
			let time = getCurrentBlock().timestamp
			var message: MessagesStruct? = nil
			var commentSt: CommentsStruct? = nil
			// User
			if is_comment == true{ 
				commentSt = CommentsStruct(comment: comment, time: time)
				message = MessagesStruct(addr: addr, ticket_addr: ticket_addr, comment: comment, is_comment: is_comment, message_id: (commentSt!).message_id, is_organizer: false)
			} else{ 
				message = MessagesStruct(addr: addr, ticket_addr: ticket_addr, comment: comment, is_comment: is_comment, message_id: nil, is_organizer: false)
			}
			Messages.messages[addr] = message!
			
			// Organizer
			if let data = Messages.messages[ticket_addr]{ 
				if is_comment == true{ 
					data.got_comments.append(commentSt!)
				} else{ 
					data.got_upvote = data.got_upvote + 1
				}
				Messages.messages[ticket_addr] = data
			} else{ 
				let messageOrganizer = MessagesStruct(addr: ticket_addr, ticket_addr: nil, comment: comment, is_comment: is_comment, message_id: nil, is_organizer: true)
				if is_comment == true{ 
					messageOrganizer.got_comments.append(commentSt!)
				} else{ 
					messageOrganizer.got_upvote = 1
				}
				Messages.messages[ticket_addr] = messageOrganizer
			}
		}
	}
	
	/*
	  ** [Resource] MessagesPublic
	  */
	
	access(all)
	resource MessagesPublic{} 
	
	/*
	  ** [create vault] createMessagesVault
	  */
	
	access(all)
	fun createMessagesVault(
		addr: Address,
		ticket_addr: Address,
		comment: String,
		is_comment: Bool
	): @MessagesVault{ 
		return <-create MessagesVault(
			addr: addr,
			ticket_addr: ticket_addr,
			comment: comment,
			is_comment: is_comment
		)
	}
	
	/*
	  ** [create MessagesPublic] createMessagesPublic
	  */
	
	access(all)
	fun createMessagesPublic(): @MessagesPublic{ 
		return <-create MessagesPublic()
	}
	
	/*
	  ** init
	  */
	
	init(){ 
		self.TicketsCommentVaultPublicPath = /public/TicketsCommentVault
		self.totalMessagesIds = 0
		self.messages ={} 
	}
}
