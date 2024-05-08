pub contract Bar {
	pub event Test(x: String)
	pub var X: String
	pub var Z: String

	pub init(x: String) {
		self.X = x
		self.Z = "ZZZZ"
	}

	pub fun hello() {
		emit Test(x: self.X)
	}
}