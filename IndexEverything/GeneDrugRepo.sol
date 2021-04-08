pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

contract GeneDrugRepo {

    //state data
    mapping(address => uint) private numObservationsBySender;
    uint private numObservations;
    
    mapping(string => uint8) private geneIDs;
    //TODO: should this be an array?, b/c we'll be creating/indexing by an incrementer
    mapping(uint8 => string) private geneNames;
    uint8 numGenes;
    
    mapping(string => uint8) private drugIDs;
    //TODO: should this be an array?, b/c we'll be creating/indexing by an incrementer
    mapping(uint8 => string) private drugNames;
    uint8 numDrugs;
    
    mapping(string => uint8) private variantIDs;
    //TODO: should this be an array?, b/c we'll be creating/indexing by an incrementer
    mapping(uint8 => string) private variantNames;
    mapping(uint8 => uint) private variantNums;
    uint8 numVariants;
    
    mapping(uint24 => uint) private totalCount;
    uint totalUniqueCount;
    
    mapping(uint24 => uint) private improvedCount;
    mapping(uint24 => uint) private unchangedCount;
    mapping(uint24 => uint) private deterioratedCount;
    mapping(uint24 => uint) private suspectedRelationCount;
    mapping(uint24 => uint) private sideEffectCount;
    
    bytes32 wildcard = keccak256(abi.encodePacked("*"));
    bytes32 improved = keccak256(abi.encodePacked("IMPROVED"));
    bytes32 unchanged = keccak256(abi.encodePacked("UNCHANGED"));
    bytes32 deteriorated = keccak256(abi.encodePacked("DETERIORATED"));

    //adapted from from Oraclize -- https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strpercent(uint numerator, uint denominator) internal pure returns(string memory){
        if (numerator == denominator){
            return "100";
        } else {
            //uint precision = 8;
             //next few lines adapted from https://stackoverflow.com/questions/42738640/division-in-ethereum-solidity
             // caution, check safe-to-multiply here
            //uint _numerator  = numerator * 10 ** (precision+1);
            uint _numerator  = numerator * 10 ** (8+1);
            // with rounding of last digit
            uint quotient =  ((_numerator / denominator) + 5) / 10;
            if (quotient == 0) {
                return "0";
            }
            uint j = quotient;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            if (len >= 7){
                bytes memory bstr = new bytes(len+1);
                uint k = len;
                while (quotient != 0) {
                    if (k == (len-6)){
                        k--;
                    }
                    bstr[k--] = byte(uint8(48 + quotient % 10));
                    quotient /= 10;
                }
                bstr[len-6] = byte(uint8(46));
                //TODO, see if we can drop trailing zeros?
                return string(bstr);
            } else {
                //TODO, add the appropriate number of zeros after the decimal point
                return "smaller than 1%";
            }
        }
    }

    //from Oraclize -- https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    // This structure is how the data should be returned from the query function.
    // You do not have to store relations this way in your contract, only return them.
    // geneName and drugName must be in the same capitalization as it was entered. E.g. if the original entry was GyNx3 then GYNX3 would be considered incorrect.
    // Percentage values must be acurrate to 6 decimal places and will not include a % sign. E.g. "35.123456"
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

        if (geneIDs[geneName] == 0) {
            numGenes += 1;
            geneIDs[geneName] = numGenes;
            geneNames[numGenes] = geneName;
        }
        
        if (drugIDs[drugName] == 0) {
            numDrugs += 1;
            drugIDs[drugName] = numDrugs;
            drugNames[numDrugs] = drugName;
        }

        //next 18ish lines are uint2str from Oraclize -- https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
        string memory variantString;
        uint _i = variantNumber;
        if (_i == 0) {
            variantString = "0";
        } else {
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
            variantString = string(bstr);
        }
        
        if (variantIDs[variantString] == 0){
            numVariants += 1;
            variantIDs[variantString] = numVariants;
            variantNames[numVariants] = variantString;
            //TODO, here's where we would cache the variantNumber
            //in some sort of lookup, so that we don't have to convert back
            variantNums[numVariants] = variantNumber;
        }

        uint24 key = drugIDs[drugName];
        key += variantIDs[variantString] * 2**8;
        key += geneIDs[geneName] * 2**16;
        
        if (totalCount[key] == 0){
            totalUniqueCount += 1;
        }
        totalCount[key] += 1;

        bytes32 outcomeb = keccak256(abi.encodePacked(outcome));
        if (outcomeb == improved){
            improvedCount[key] += 1;
        } else if (outcomeb == unchanged) {
            unchangedCount[key] += 1;
        } else if (outcomeb == deteriorated){
            deterioratedCount[key] += 1;
        }

        if (suspectedRelation == true){
            suspectedRelationCount[key] += 1;
        } 
        if (seriousSideEffect == true){
            sideEffectCount[key] += 1;
        }

        numObservationsBySender[msg.sender] += 1;
        numObservations += 1;
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
        uint8 gh;
        uint8 gl;
        uint8 vh;
        uint8 vl;
        uint8 dh;
        uint8 dl;
        
        //TODO: something, somewhere, said that this is the way to do strcmp, gotta be a better way
        if (keccak256(abi.encodePacked(geneName)) == wildcard){
            gl = 1;
            gh = numGenes;
        } else {
            gl = gh = geneIDs[geneName];
        }
        
        if (keccak256(abi.encodePacked(variantNumber)) == wildcard){
            vl = 1;
            vh = numVariants;
        } else {
            vl = vh = variantIDs[variantNumber];
        }
        
        if (keccak256(abi.encodePacked(drug)) == wildcard){
            dl = 1;
            dh = numDrugs;
        } else {
            dl = dh = drugIDs[drug];
        }

        uint rvlen = 0;
        for (uint8 x = gl; x <= gh; x++){
            for (uint8 y = vl; y <= vh; y++){
                for(uint8 z = dl; z <= dh; z++){
                    uint24 key = z + (y * 2**8) + (x * 2**16);
                    if (totalCount[key] > 0) {
                        rvlen += 1;
                    }
                }
            }
        }

        GeneDrugRelation[] memory rv = new GeneDrugRelation[](rvlen);
        uint rvi = 0;

        for (uint8 x = gl; x <= gh; x++){
            for (uint8 y = vl; y <= vh; y++){
                for(uint8 z = dl; z <= dh; z++){
                    uint24 key = z + (y * 2**8) + (x * 2**16);
                    if (totalCount[key] > 0) {
                        //profile whether calling parseInt is better
                        //than storing both string and int reps of variant numbers
                        rv[rvi] = GeneDrugRelation(geneNames[x],variantNums[y],drugNames[z],totalCount[key],improvedCount[key],strpercent(improvedCount[key],totalCount[key]),unchangedCount[key],strpercent(unchangedCount[key],totalCount[key]),deterioratedCount[key],strpercent(deterioratedCount[key],totalCount[key]),suspectedRelationCount[key],strpercent(suspectedRelationCount[key],totalCount[key]),sideEffectCount[key],strpercent(sideEffectCount[key],totalCount[key]));
                        rvi += 1;
                    }
                }
            }
        }
        return rv;
    }

    /** Takes: geneName,-name, variant-number, and drug-name as strings. Accepts "*" as a wild card, same rules as query
        Returns: A boolean value. True if the relation exists, false if not. If a wild card was used, then true if any relation exists which meets the non-wildcard criteria.
     */
    function entryExists(
        string memory geneName,
        string memory variantNumber,
        string memory drug
    ) public view returns (bool){
        uint8 gh;
        uint8 gl;
        uint8 vh;
        uint8 vl;
        uint8 dh;
        uint8 dl;
        
        //TODO: something, somewhere, said that this is the way to do strcmp, gotta be a better way
        if (keccak256(abi.encodePacked(geneName)) == wildcard){
            gl = 1;
            gh = numGenes;
        } else {
            gl = gh = geneIDs[geneName];
        }
        
        if (keccak256(abi.encodePacked(variantNumber)) == wildcard){
            vl = 1;
            vh = numVariants;
        } else {
            vl = vh = variantIDs[variantNumber];
        }
        
        if (keccak256(abi.encodePacked(drug)) == wildcard){
            dl = 1;
            dh = numDrugs;
        } else {
            dl = dh = drugIDs[drug];
        }

        for (uint8 x = gl; x <= gh; x++){
            for (uint8 y = vl; y <= vh; y++){
                for(uint8 z = dl; z <= dh; z++){
                    uint24 key = z + (y * 2**8) + (x * 2**16);
                       if (totalCount[key] > 0) {
                           return true;
                       }
                }
            }
        }

        return false;
    }

    /** Return the total number of known relations, a.k.a. the number of unique geneName,-name, variant-number, drug-name pairs
     */
    function getNumRelations () public view returns(uint){
        return totalUniqueCount;
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
        return numObservationsBySender[sender];
    }
    
}

