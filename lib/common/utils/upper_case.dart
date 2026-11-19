extension UpperCase on String {
  String get toLowerToCapitalize=>toLowerCase().capitalizeFirstLetter;
  String get capitalizeFirstLetter {
    if (isEmpty) {
      return this;
    }
    final brokenString= split(" ");
    var finalString="";
    for(int i =0;i<brokenString.length;i++){
      var e = brokenString[i];
      if (e.trim().isNotEmpty) {
        e =
            e.substring(0, 1).toUpperCase() + e.substring(1).toLowerCase();
      }
      if(i==0){
        finalString=e;
      }else{
      finalString= "$finalString $e";
      }
    }
    return finalString;
  }
}
