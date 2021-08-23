
pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;
import "./LibString.sol";

contract GeneDrugRepo {
    using LibString for *;

   struct GeneDrugRelation { 
        string geneName;   //'Gn' as short 
        uint variantNumber; //'Vn' as short
        string drugName;  //'Dn' as short
        uint totalCount;  //count for inputs with same gn,vn and dn
        uint improvedCount; //count for improved inputs with same gn,vn and dn 
        string improvedPercent; 
        uint unchangedCount; //count for unchanged inputs with same gn,vn and dn 
        string unchangedPercent;
        uint deterioratedCount; //count for deteriorated inputs with same gn,vn and dn 
        string deterioratedPercent;
        uint suspectedRelationCount; //count for suspected inputs with same gn,vn and dn 
        string suspectedRelationPercent; 
        uint sideEffectCount;  //count for sideEffect inputs with same gn,vn and dn 
        string sideEffectPercent;
    }
	
	//定义存储所有数据的mapping
	mapping(string => GeneDrugRelation) private geneData;
	//定义一个数组存geneData的key,方便查询数据
	string[] geneDataKeyArr;
	//定义另外一个mapping存储对应的关系
	mapping(string => string[]) private keyMapping;

	//疑似基因相关
	string[] private relation;
	//交易总条数
	uint total;
	//钱包地址和观察
	mapping(address => uint) private addrMap;

    /** Insert an observation into your contract, following the format defined in the data readme. 
        This function has no return value. If it completes it will be assumed the observations was recorded successfully. 

        Note: case matters for geneName and drugName. GyNx3 and gynx3 are treated as different genes.
     */
    function insertObservation (
        string memory geneName,
        uint variantNumber,
        string memory drugName,
        string memory outcome,  // IMPROVED, UNCHANGED, DETERIORATED. This will always be capitalized, you don't have to worry about case. 
        bool suspectedRelation,
        bool seriousSideEffect
    ) public {
        uint  Percentage=0;
		//交易条数+1
		total+=1;
		//钱包地址观察数
		addrMap[msg.sender]+=1;
		//组合key
        string memory keyGnVnDn =geneName;
        string memory variantNumberStr=LibString.toString(variantNumber);
		keyGnVnDn=LibString.concat(keyGnVnDn,"+",variantNumberStr);
		keyGnVnDn=LibString.concat(keyGnVnDn,"+",drugName);
		//存ab-abc ac-abc
		if(geneData[keyGnVnDn].totalCount==0){
		 //存abc的key
		geneDataKeyArr.push(keyGnVnDn);
		//key:ab
		string  memory keyGnVn=LibString.concat(geneName,"+",variantNumberStr);
		//key:ac
		string memory  keyGnDn=LibString.concat(geneName,"+",drugName);
		//key:bc
		string memory  keyVnDn=LibString.concat(variantNumberStr,"+",drugName);
		//储数据
		geneData[keyGnVnDn]=GeneDrugRelation({
	     geneName:geneName,
         variantNumber:variantNumber,
         drugName:drugName,
         totalCount:0,
         improvedCount:0,
         improvedPercent:"0.0000000",
         unchangedCount:0,
         unchangedPercent:"0.0000000" ,
         deterioratedCount:0,
         deterioratedPercent:"0.0000000",
         suspectedRelationCount:0,
         suspectedRelationPercent:"0.0000000",
         sideEffectCount:0,
         sideEffectPercent:"0.0000000"
		});
		keyMapping[keyGnVn].push(keyGnVnDn);
		keyMapping[keyGnDn].push(keyGnVnDn);
		//bc
		keyMapping[keyVnDn].push(keyGnVnDn);
		//a
		keyMapping[geneName].push(keyGnVnDn);
		//b
		keyMapping[variantNumberStr].push(keyGnVnDn);
		//c
		keyMapping[drugName].push(keyGnVnDn);
		
		if(suspectedRelation==true){
		  relation.push(keyGnVnDn);
		}
		}
 		 //结构体里面别的数据加减
 		 geneData[keyGnVnDn].totalCount+=1;
 	
		if(suspectedRelation==true){
		  geneData[keyGnVnDn].suspectedRelationCount+=1;
		}
		
		 Percentage =  geneData[keyGnVnDn].suspectedRelationCount*10000000/geneData[keyGnVnDn].totalCount;
		  geneData[keyGnVnDn].suspectedRelationPercent=LibString.uint2str(Percentage);

		if(seriousSideEffect==true){
		    geneData[keyGnVnDn].sideEffectCount+=1;
		}
		 Percentage =  geneData[keyGnVnDn].sideEffectCount*10000000/geneData[keyGnVnDn].totalCount;
		  geneData[keyGnVnDn].sideEffectPercent=LibString.uint2str(Percentage);
		//效果IMPROVED, UNCHANGED, DETERIORATED
		if(LibString.equals(outcome, "IMPROVED")){
		geneData[keyGnVnDn].improvedCount+=1;	
		Percentage =  geneData[keyGnVnDn].improvedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].improvedPercent=LibString.uint2str(Percentage);
		//=======UNCHANGED
		Percentage =  geneData[keyGnVnDn].unchangedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].unchangedPercent=LibString.uint2str(Percentage);
		//=======DETERIORATED
		Percentage =  geneData[keyGnVnDn].deterioratedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].deterioratedPercent=LibString.uint2str(Percentage);
		 return;
		}

		if(LibString.equals(outcome, "UNCHANGED")){
		geneData[keyGnVnDn].unchangedCount+=1;	
		Percentage =  geneData[keyGnVnDn].improvedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].improvedPercent=LibString.uint2str(Percentage);
		//=======UNCHANGED
		Percentage =  geneData[keyGnVnDn].unchangedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].unchangedPercent=LibString.uint2str(Percentage);
		//=======DETERIORATED
		Percentage =  geneData[keyGnVnDn].deterioratedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].deterioratedPercent=LibString.uint2str(Percentage);
		 return;
		}
		if(LibString.equals(outcome, "DETERIORATED")){
		    
		geneData[keyGnVnDn].deterioratedCount+=1;	
		Percentage =  geneData[keyGnVnDn].improvedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].improvedPercent=LibString.uint2str(Percentage);
		//=======UNCHANGED
		Percentage =  geneData[keyGnVnDn].unchangedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].unchangedPercent=LibString.uint2str(Percentage);
		//=======DETERIORATED
		Percentage =  geneData[keyGnVnDn].deterioratedCount*10000000/geneData[keyGnVnDn].totalCount;
		geneData[keyGnVnDn].deterioratedPercent=LibString.uint2str(Percentage);
		 return;
		}
		
    }

    /** Takes geneName, variant-number, and drug-name as strings. A value of "*" for any name should be considered as a wildcard or alternatively as a null parameter.
        Returns: An array of GeneDrugRelation Structs which match the query parameters

        To clarify here are some example queries:
        query("CYP3A5", "52", "pegloticase") => An array of the one relation that matches all three parameters
        query("CYP3A5","52","*") => An array of all relations between geneName, CYP3A5, variant 52, and any drug
        query("CYP3A5","*","pegloticase") => An array of all relations between geneName, CYP3A5 and drug pegloticase, regardless of variant
        query("*","*","*") => An array of all known relations. 

        Note that capitalization matters. 
    */
    function query(
        string memory geneName,
        string memory variantNumber,
        string memory drug
    ) public view returns (GeneDrugRelation[] memory) {
      string memory  useCase="0";
      //geneName
      if(LibString.equals(geneName,"*")){
          useCase="1"; 
      }else{
          useCase="2"; 
      }
      //variantNumber
     if(LibString.equals(variantNumber,"*")){
         useCase=LibString.concat(useCase,"1");
      }else{
        useCase=LibString.concat(useCase,"2");
     }
     //drug
     if(LibString.equals(drug,"*")){
         useCase=LibString.concat(useCase,"1");
      }else{
        useCase=LibString.concat(useCase,"2");
     }
     //useCase
     //ABC 222
     if(LibString.equals(useCase,"222")){
        GeneDrugRelation[] memory arry=new GeneDrugRelation[](1);
		string memory keyGnVnDn=LibString.concat(geneName,"+",variantNumber);
		keyGnVnDn=LibString.concat(keyGnVnDn,"+",drug);
    	arry[0]=geneData[keyGnVnDn];
		return arry; 
     }
     
     //AB* 221
    if(LibString.equals(useCase,"221")){
		string memory keyGnVn=LibString.concat(geneName,"+",variantNumber);
		GeneDrugRelation[] memory arry=new GeneDrugRelation[](keyMapping[keyGnVn].length); 
		for (uint k = 0;k <keyMapping[keyGnVn].length ;k++) {
			 arry[k]=geneData[keyMapping[keyGnVn][k]];
		 }
		return arry;
     }
     //A*C 212
     if(LibString.equals(useCase,"212")){
		string memory keyGnDn=LibString.concat(geneName,"+",drug);
		GeneDrugRelation[] memory arry=new GeneDrugRelation[](keyMapping[keyGnDn].length); 
		for (uint k = 0;k <keyMapping[keyGnDn].length ;k++) {
				 arry[k]=geneData[keyMapping[keyGnDn][k]];
		}
		return arry;
     }
     //*BC 122
    if(LibString.equals(useCase,"122")){
		string memory keyVnDn=LibString.concat(variantNumber,"+",drug);
		GeneDrugRelation[] memory arry=new GeneDrugRelation[](keyMapping[keyVnDn].length); 
		for (uint k = 0;k <keyMapping[keyVnDn].length ;k++) {
				 arry[k]=geneData[keyMapping[keyVnDn][k]];
		}
		return arry;
     }
     //A** 211
    if(LibString.equals(useCase,"211")){
		GeneDrugRelation[] memory arry=new GeneDrugRelation[](keyMapping[geneName].length); 
		for (uint k = 0;k <keyMapping[geneName].length ;k++) {
				 arry[k]=geneData[keyMapping[geneName][k]];
		}
		return arry;
     }
     
     //*B* 121
     if(LibString.equals(useCase,"121")){
		GeneDrugRelation[] memory arry=new GeneDrugRelation[](keyMapping[variantNumber].length); 
		for (uint k = 0;k <keyMapping[variantNumber].length ;k++) {
				 arry[k]=geneData[keyMapping[variantNumber][k]];
		}
		return arry;
     }    
     
     //**C 112
     if(LibString.equals(useCase,"112")){
		GeneDrugRelation[] memory arry=new GeneDrugRelation[](keyMapping[drug].length); 
		for (uint k = 0;k <keyMapping[drug].length ;k++) {
				 arry[k]=geneData[keyMapping[drug][k]];
		}
		return arry;
     }  
     
     //*** 111
     	GeneDrugRelation[] memory arry=new GeneDrugRelation[](geneDataKeyArr.length);
			 for (uint i = 0;i <geneDataKeyArr.length ;i++) {
              arry[i]=geneData[geneDataKeyArr[i]];
			 }
		return arry;

    }

    /** Takes: geneName,-name, variant-number, and drug-name as strings. Accepts "*" as a wild card, same rules as query
        Returns: A boolean value. True if the relation exists, false if not. If a wild card was used, then true if any relation exists which meets the non-wildcard criteria.
     */
    function entryExists(
        string memory geneName,
        string memory variantNumber,
        string memory drug
    ) public view returns (bool){
        // Code here
     string memory  useCase="0";
      //geneName
      if(LibString.equals(geneName,"*")){
          useCase="1"; 
      }else{
          useCase="2"; 
      }
      //variantNumber
     if(LibString.equals(variantNumber,"*")){
         useCase=LibString.concat(useCase,"1");
      }else{
        useCase=LibString.concat(useCase,"2");
     }
     //drug
     if(LibString.equals(drug,"*")){
         useCase=LibString.concat(useCase,"1");
      }else{
        useCase=LibString.concat(useCase,"2");
     }
     //useCase
     //ABC 222
     if(LibString.equals(useCase,"222")){
 
		string memory keyGnVnDn=LibString.concat(geneName,"+",variantNumber);
		keyGnVnDn=LibString.concat(keyGnVnDn,"+",drug);
        if(geneData[keyGnVnDn].suspectedRelationCount!=0){
		       return true;
		}
     }
     
     //AB* 221
    if(LibString.equals(useCase,"221")){
		string memory keyGnVn=LibString.concat(geneName,"+",variantNumber);
	
		 for (uint k = 0;k <keyMapping[keyGnVn].length ;k++) {
			if(geneData[keyMapping[keyGnVn][k]].suspectedRelationCount!=0){
		       return true;
			 }
     }
     		return false;
    }
     //A*C 212
     if(LibString.equals(useCase,"212")){
		string memory keyGnDn=LibString.concat(geneName,"+",drug);
	
		for (uint k = 0;k <keyMapping[keyGnDn].length ;k++) {
			if(geneData[keyMapping[keyGnDn][k]].suspectedRelationCount!=0){
		       return true;
			 }
		}
		return false;

     }
     //*BC 122
    if(LibString.equals(useCase,"122")){
		string memory keyVnDn=LibString.concat(variantNumber,"+",drug);
	
		for (uint k = 0;k <keyMapping[keyVnDn].length ;k++) {
			if(geneData[keyMapping[keyVnDn][k]].suspectedRelationCount!=0){
		       return true;
			 }
		}
		return false;
     }
     //A** 211
    if(LibString.equals(useCase,"211")){
	
		for (uint k = 0;k <keyMapping[geneName].length ;k++) {
			if(geneData[keyMapping[geneName][k]].suspectedRelationCount!=0){
		       return true;
			 }
		}
		return false;
     }
     
     //*B* 121
     if(LibString.equals(useCase,"121")){
	
		for (uint k = 0;k <keyMapping[variantNumber].length ;k++) {
		if(geneData[keyMapping[variantNumber][k]].suspectedRelationCount!=0){
		       return true;
			 }
		}
		return false;
     }    
     
     //**C 112
     if(LibString.equals(useCase,"112")){
	 
		for (uint k = 0;k <keyMapping[drug].length ;k++) {
				
			if(geneData[keyMapping[drug][k]].suspectedRelationCount!=0){
		       return true;
			 }
		}
		return false;
     }  
     
     //*** 111
		for (uint i = 0;i <geneDataKeyArr.length ;i++) {
         if(geneData[geneDataKeyArr[i]].suspectedRelationCount!=0){
		      return true;
		}
     } 
     	return false;
    }
    /** Return the total number of known relations, a.k.a. the number of unique geneName,-name, variant-number, drug-name pairs
     */
    function getNumRelations () public view returns(uint){
        // Code here
	return relation.length;
    }
    
    /** Return the total number of recorded observations, regardless of sender.
     */
    function getNumObservations() public view returns (uint) {
        // Code here
		return total;
    }

    /** Takes: A wallet address.
        Returns: The number of observations recorded from the provided wallet address
     */
    function getNumObservationsFromSender(address sender) public view returns (uint) {
        // Code here
		return addrMap[sender];
    }
    
}








