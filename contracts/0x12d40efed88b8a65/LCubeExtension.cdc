pub contract LCubeExtension {

  pub fun clearSpaceLetter(text: String): String {
    var collectionName=""  
    var i = 0
    while i < text.length {    
        if text[i] != " " {
           collectionName=collectionName.concat(text[i].toString())
        }else{
            collectionName=collectionName.concat("_")
        }
      i = i + 1
    }
    return collectionName
  }
}