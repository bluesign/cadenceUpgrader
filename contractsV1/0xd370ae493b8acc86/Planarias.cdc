// This smart contract does not implement the NonFungibleToken interface.
// The planarias are just that, as they are.
access(all)
contract Planarias{ 
	access(all)
	var population: UInt64
	
	access(all)
	event Begin()
	
	access(all)
	event Born(
		name: UInt64,
		genes: Genes,
		generation: UInt256,
		motherName: UInt64?,
		fatherName: UInt64?,
		meiosisAlgorithm: Type
	)
	
	access(all)
	event In(name: UInt64, to: Address?)
	
	access(all)
	event Out(name: UInt64, from: Address?)
	
	access(all)
	event Die(name: UInt64)
	
	access(all)
	event End()
	
	// Planarias' meiosis algorithm is open to change. Anyone can evolve them.
	access(all)
	struct interface IMeiosisAlgorithm{ 
		access(all)
		fun divide(genes: Planarias.Genes): UInt256
	}
	
	access(all)
	struct MeiosisAlgorithm: IMeiosisAlgorithm{ 
		access(all)
		fun divide(genes: Planarias.Genes): UInt256{ 
			let randomChiasmaMask = fun (): UInt256{ 
					var mask: UInt256 = 0
					var val: UInt256 = revertibleRandom<UInt64>() % UInt64(2) == 0 ? 0 : 1
					var i = 0
					while i < 256{ 
						let length = Int(revertibleRandom<UInt64>() % UInt64(128))
						var j = 0
						while j < length{ 
							mask = (mask << 1) + UInt256(val)
							j = j + 1
							if i + j >= 256{ 
								break
							}
						}
						i = i + j
						val = (val + 1) % 2
					}
					return mask
				}
			let chiasma = randomChiasmaMask()
			let sequence = genes.primary & chiasma | genes.secondary & (chiasma ^ UInt256.max)
			let mutation = UInt256(1 << Int(revertibleRandom<UInt64>() % UInt64(256)))
			return sequence ^ mutation
		}
	}
	
	access(all)
	struct Genes{ 
		access(all)
		let primary: UInt256
		
		access(all)
		let secondary: UInt256
		
		init(primary: UInt256, secondary: UInt256){ 
			self.primary = primary
			self.secondary = secondary
		}
	}
	
	access(all)
	resource Planaria{ 
		access(all)
		let name: UInt64
		
		access(all)
		let genes: Genes
		
		access(all)
		let generation: UInt256
		
		access(all)
		let birthtime: UFix64
		
		access(all)
		let motherName: UInt64?
		
		access(all)
		let fatherName: UInt64?
		
		access(all)
		var copulatoryPouch:{ UInt64: UInt256}
		
		access(all)
		var meiosisAlgorithm:{ IMeiosisAlgorithm}
		
		init(
			genes: Genes,
			generation: UInt256,
			motherName: UInt64?,
			fatherName: UInt64?,
			meiosisAlgorithm:{ IMeiosisAlgorithm}
		){ 
			self.name = self.uuid
			self.genes = genes
			self.generation = generation
			self.birthtime = getCurrentBlock().timestamp
			self.motherName = motherName
			self.fatherName = fatherName
			self.copulatoryPouch ={} 
			self.meiosisAlgorithm = meiosisAlgorithm
			Planarias.population = Planarias.population + 1
			if Planarias.population == 1{ 
				emit Begin()
			}
			emit Born(
				name: self.name,
				genes: self.genes,
				generation: self.generation,
				motherName: self.motherName,
				fatherName: self.fatherName,
				meiosisAlgorithm: self.meiosisAlgorithm.getType()
			)
		}
		
		access(all)
		fun reproduceAsexually(): @Planaria{ 
			return <-create Planaria(
				genes: self.genes,
				generation: self.generation + 1,
				motherName: self.name,
				fatherName: nil,
				meiosisAlgorithm: self.meiosisAlgorithm
			)
		}
		
		access(all)
		fun reproduceSexually(): @Planaria{ 
			pre{ 
				self.copulatoryPouch.length > 0:
					"no father gene"
			}
			let fatherNames = self.copulatoryPouch.keys
			let fatherName =
				fatherNames[Int(revertibleRandom<UInt64>() % UInt64(fatherNames.length))]!
			let fatherGene = self.copulatoryPouch.remove(key: fatherName)!
			let motherGene = self.meiosisAlgorithm.divide(genes: self.genes)
			return <-create Planaria(
				genes: Genes(primary: fatherGene, secondary: motherGene),
				generation: self.generation + 1,
				motherName: self.name,
				fatherName: fatherName,
				meiosisAlgorithm: self.meiosisAlgorithm
			)
		}
		
		access(all)
		fun copulate(father: &Planaria){ 
			let fatherGene = father.meiosisAlgorithm.divide(genes: *father.genes)
			self.copulatoryPouch.insert(key: father.name, fatherGene)
		}
		
		access(all)
		fun inject(meiosisAlgorithm:{ IMeiosisAlgorithm}){ 
			self.meiosisAlgorithm = meiosisAlgorithm
		}
	}
	
	access(all)
	resource Habitat{ 
		access(all)
		var planarias: @{UInt64: Planaria}
		
		init(){ 
			self.planarias <-{} 
		}
		
		access(all)
		fun out(name: UInt64): @Planaria{ 
			let planaria <- self.planarias.remove(key: name) ?? panic("Missing Planaria")
			emit Out(name: planaria.name, from: self.owner?.address)
			return <-planaria
		}
		
		access(all)
		fun _in(planaria: @Planaria){ 
			let name: UInt64 = planaria.name
			self.planarias[name] <-! planaria
			emit In(name: name, to: self.owner?.address)
		}
		
		access(all)
		fun getNames(): [UInt64]{ 
			return self.planarias.keys
		}
		
		access(all)
		fun borrowPlanaria(name: UInt64): &Planaria?{ 
			return &self.planarias[name] as &Planaria?
		}
	}
	
	access(all)
	fun createHabitat(): @Habitat{ 
		return <-create Habitat()
	}
	
	access(all)
	fun generate(): @Planaria{ 
		let newGene = fun (): UInt256{ 
				return UInt256(revertibleRandom<UInt64>()) + (UInt256(revertibleRandom<UInt64>()) << 64) + (UInt256(revertibleRandom<UInt64>()) << 128) + (UInt256(revertibleRandom<UInt64>()) << 192)
			}
		return <-create Planaria(
			genes: Genes(primary: newGene(), secondary: newGene()),
			generation: 0,
			motherName: nil,
			fatherName: nil,
			meiosisAlgorithm: MeiosisAlgorithm()
		)
	}
	
	init(){ 
		self.population = 0
		self.account.storage.save(<-create Habitat(), to: /storage/PlanariasHabitat)
		var capability_1 =
			self.account.capabilities.storage.issue<&Planarias.Habitat>(/storage/PlanariasHabitat)
		self.account.capabilities.publish(capability_1, at: /public/PlanariasHabitat)
	}
}
