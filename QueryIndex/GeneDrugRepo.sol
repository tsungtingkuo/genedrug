// Author: Emory Team
// Date: 08/23/2019

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

contract GeneDrugRepo {
    uint numObservations;
    mapping (address => uint) numObservationsFromSenders;
    mapping (bytes => uint[]) relations;
    Stat[] statStorage;

    uint constant IMPROVED = 8;
    uint constant UNCHANGED = 9;
    uint constant DETERIORATED = 12;
    uint constant precision = 6;
    uint constant multiplier = 10**precision;


    struct GeneDrugRelation {
        string geneName;
        uint variantNumber;
        string drugName;
        uint totalCount;
        uint improvedCount;
        string improvedPercent;
        uint unchangedCount;
        string unchangedPercent;
        uint deterioratedCount;
        string deterioratedPercent;
        uint suspectedRelationCount;
        string suspectedRelationPercent;
        uint sideEffectCount;
        string sideEffectPercent;
    }

    struct Stat {
	string geneName;
        uint variantNumber;
        string drugName;
        uint totalCount;
        uint improvedCount;
        uint unchangedCount;
        uint suspectedRelationCount;
        uint sideEffectCount;
    }
        
    function insertObservation (
                                string memory geneName,
                                uint variantNumber,
                                string memory drugName,
                                string memory outcome, 
                                bool suspectedRelation,
                                bool seriousSideEffect
                                ) public {

        uint index = 0;
	string memory variantNumber_str = uintToStr(variantNumber);
	bytes memory key = encodeKey(geneName, variantNumber_str, drugName);

	if (entryExists(geneName,variantNumber_str,drugName) == false) {
	    Stat memory r = buildStat(geneName,variantNumber,drugName, outcome, suspectedRelation, seriousSideEffect);
	    statStorage.push(r);
	    index = statStorage.length -1;
	    bytes[8] memory keys = possibeKeys(geneName, variantNumber_str, drugName);
	    for (uint i=0;i<8;i++){
		relations[keys[i]].push(index);
	    }
	    // numRelations++;
	} else {
	    index = relations[key][0];
            updateStat(statStorage[index], outcome,suspectedRelation,seriousSideEffect);
	}
	
        numObservations++;
        numObservationsFromSenders[msg.sender]++;
        
    }

    function buildStat(string memory geneName,
			   uint variantNumber,
                           string memory drugName,
                           string memory outcome, 
                           bool suspectedRelation,
                           bool seriousSideEffect) private pure returns(Stat memory){
	uint improvedCount = equals(outcome, IMPROVED) ? 1 : 0;
        uint unchangedCount = equals(outcome, UNCHANGED) ? 1 : 0;
        uint suspectedRelationCount = suspectedRelation ? 1 : 0;
        uint sideEffectCount = seriousSideEffect ? 1 : 0;
        return Stat(geneName,variantNumber,drugName,1,improvedCount,unchangedCount,suspectedRelationCount,sideEffectCount);
    }
	

    function updateStat(Stat storage old,
			    string memory outcome, 
			    bool suspectedRelation,
			    bool seriousSideEffect) private{
	old.totalCount += 1;
	if (equals(outcome, IMPROVED)){
	    old.improvedCount += 1;
	} else if (equals(outcome, UNCHANGED)) {
	    old.unchangedCount += 1;
	}
	if (suspectedRelation) {
	    old.suspectedRelationCount += 1;
	}
	if (seriousSideEffect) {
	    old.sideEffectCount += 1;
	}				
    }

    function toGeneDrugRelation(Stat memory s) private pure returns(GeneDrugRelation memory) {
	uint deterioratedCount = s.totalCount - s.improvedCount - s.unchangedCount;
        return GeneDrugRelation(s.geneName, s.variantNumber, s.drugName, s.totalCount,
                                s.improvedCount, div(s.improvedCount, s.totalCount),
                                s.unchangedCount, div(s.unchangedCount, s.totalCount),
                                deterioratedCount, div(deterioratedCount, s.totalCount),
                                s.suspectedRelationCount, div(s.suspectedRelationCount, s.totalCount),
                                s.sideEffectCount, div(s.sideEffectCount, s.totalCount));
    }
    
    function possibeKeys(string memory geneName, string memory variantNumber, string memory drugName)
	private pure returns(bytes[8] memory){
	return [encodeKey("*","*",drugName), encodeKey("*",variantNumber,"*"),
		encodeKey("*",variantNumber,drugName), encodeKey(geneName,"*","*"),
		encodeKey(geneName,"*",drugName), encodeKey(geneName,variantNumber,"*"),
		encodeKey(geneName,variantNumber,drugName),encodeKey("*","*","*")];
    }

    function encodeKey(string memory geneName, string memory variantNumber, string memory drugName)
	private pure returns(bytes memory) {
	return abi.encodePacked(geneName,variantNumber,drugName);
    }    
   
    function query(
        string memory geneName,
        string memory variantNumber,
        string memory drug
    ) public view returns (GeneDrugRelation[] memory) {
	uint[] memory indexList = relations[encodeKey(geneName,variantNumber,drug)];
	GeneDrugRelation[] memory result = new GeneDrugRelation[](indexList.length);
	for (uint i=0;i<indexList.length;i++){
	    result[i] = toGeneDrugRelation(statStorage[indexList[i]]);
	}
	return result;
    }

    function entryExists(
                         string memory geneName,
                         string memory variantNumber,
                         string memory drugName
                         ) public view returns (bool){
	return relations[encodeKey(geneName,variantNumber,drugName)].length != 0;
    }

    /** Return the total number of known relations, a.k.a. the number of unique geneName,-name, variant-number, drug-name pairs
     */
    function getNumRelations () public view returns(uint){
	return statStorage.length;
    }
    
    /** Return the total number of recorded observations, regardless of sender.
     */
    function getNumObservations() public view returns (uint) {
        return numObservations;
    }

    /** Takes: A wallet address.
        Returns: The number of observations recorded from the provided wallet address
     */
    function getNumObservationsFromSender(address sender) public view returns (uint) {
        return numObservationsFromSenders[sender];
    }    
    
    function div(uint a, uint b) private pure returns(string memory){
        // assert(a <= b);
        if (a == b) {
            return "1.000000";
        } else if (a == 0) {
            return "0.000000";
        }
        return round_up(a,b);
    }

    function round_up(uint a, uint b) private pure returns(string memory) {
        uint long_num = a * multiplier * 10 / b;
        long_num = (long_num+5) / 10 * 10 /10;
        bytes memory long_num_bytes = uintToBytes(long_num);
        return string(abi.encodePacked("0.",long_num_bytes));
    }

    
    function uintToStr(uint v) private pure returns (string memory){
        return string(uintToBytes(v));
    }
    
    function uintToBytes(uint _i) private pure returns (bytes memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return bstr;
    }

    function equals(string memory a, uint length) private pure returns (bool) {
	return bytes(a).length == length;
    }

    
    function isStar(string memory str) private pure returns(bool) {
        bytes memory tmp = bytes(str);
        if (tmp.length > 1){
            return false;
        }
        bytes1 star = "*";
        return tmp[0] == star;
    }
}
