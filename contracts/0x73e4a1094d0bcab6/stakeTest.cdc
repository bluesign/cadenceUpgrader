pub contract stakeTest{
  pub var stakers: [Address]
  pub fun append(_ x: Address){
    self.stakers.append(x)
  }
  init(){
    self.stakers =[]
  }
  
   
}













