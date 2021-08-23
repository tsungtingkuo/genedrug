
pragma solidity ^0.5.0;

library LibString {
    
    using LibString for *;
    
        
        function concat(string memory _self, string  memory _str) internal pure returns (string memory _ret) {
        _ret = new string(bytes(_self).length + bytes(_str).length);

        uint selfptr;
        uint strptr;
        uint retptr;
        assembly {
            selfptr := add(_self, 0x20)
            strptr := add(_str, 0x20)
            retptr := add(_ret, 0x20)
        }
        
        memcpy(retptr, selfptr, bytes(_self).length);
        memcpy(retptr+bytes(_self).length, strptr, bytes(_str).length);
    }
    
    function concat(string memory _self, string memory _str1, string memory  _str2)
        internal pure returns (string memory _ret) {
        _ret = new string(bytes(_self).length + bytes(_str1).length + bytes(_str2).length);

        uint selfptr;
        uint str1ptr;
        uint str2ptr;
        uint retptr;
        assembly {
            selfptr := add(_self, 0x20)
            str1ptr := add(_str1, 0x20)
            str2ptr := add(_str2, 0x20)
            retptr := add(_ret, 0x20)
        }
        
        uint pos = 0;
        memcpy(retptr+pos, selfptr, bytes(_self).length);
        pos += bytes(_self).length;
        memcpy(retptr+pos, str1ptr, bytes(_str1).length);
        pos += bytes(_str1).length;
        memcpy(retptr+pos, str2ptr, bytes(_str2).length);
        pos += bytes(_str2).length;
    }
    
        function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    
        function equals(string memory _self, string memory _str) internal pure  returns (bool _ret) {
        if (bytes(_self).length != bytes(_str).length) {
            return false;
        }

        for (uint i=0; i<bytes(_self).length; ++i) {
            if (bytes(_self)[i] != bytes(_str)[i]) {
                return false;
            }
        }
        
        return true;
    }
    
        function toString(uint _self) internal view returns (string memory _ret) {
        if (_self == 0) {
            return "0";
        }

        uint8 len = 0;
        uint tmp = _self;
        while (tmp > 0) {
            tmp /= 10;
            len++;
        }
        
        _ret = new string(len);

        uint8 i = len-1;
        while (_self > 0) {
            bytes(_ret)[i--] =  byte(uint8(_self%10+0x30));
            _self /= 10;
        }
    }
   
   
   //实现小数和四舍五入
      function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0.000000";
        }
        
        uint j = _i;
        uint a = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
       if(len == 8){
             return "1.000000";
       }
        bytes memory bstr = new bytes(8);
        bstr[0]=byte("0");
        bstr[1]=byte(".");
        uint k = len;
        _i /= 10;
        uint ces=0;
        if(len==7){
            while (_i != 0 ) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            ces++;
            _i /= 10;
          }
         
        }

        if(len < 7){
        uint c=7-len;
        uint d=7;
        while (c != 0 ) {
                bstr[c+1] = byte("0");
                c--;
            }
        while (_i != 0 ) {
            bstr[d--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }

      }
        if(a % 10>4){
             a /=10;
             bstr[7] = byte(uint8(48 + a % 10)+1);
        }
        return string(bstr);
    } 
   

    
    
  }