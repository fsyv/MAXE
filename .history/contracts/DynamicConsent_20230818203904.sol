// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12;

/**
* Team Name:
*
*   Team Member 1:
*       { Name: , Email:  }
*   Team Member 2:
*       { Name: , Email:  }
*   Team Member 3:
*       { Name: , Email:  }
*	...
*   Team Member n:
*       { Name: , Email:  }
*
* Declaration of cross-team collaboration:
*	We DO/DO NOT collaborate with (list teams).
*
* REMINDER
*	No change to function declarations is allowed.
*/

contract DynamicConsent {
    /**
    *   If a WILDCARD (-1) is received as function parameter, it means any value is accepted.
    *   For example, if _studyID = -1 in queryForPatient,
    *	then we expected all consents made by the patient within the appropriate time frame
    *	regardless of studyID.
    */
    int256 private constant WILDCARD = -1;

    // studyID=> patientID  => Patient 数据
    mapping(uint256 => mapping(uint256 => Patient)) public dataBase; 
   // Patient  patient;
    mapping(uint256 => patientsEncode) public patientsOfStudy;
    struct patientsEncode{ 
        bytes32[] patientIDs;
        uint256     flag;      //flag为0到7，表示patientIDs[length-1]已编码进去的patientID的个数
    }
    struct Consent {
        uint256 recordTime; 
        bytes32 categoryChoices;
        bytes32[2] elementChoices;
    }
    struct Patient {
        Consent[] consent;
        uint256   leastdata;
    }

    mapping(bytes32 => string) public extendCategorys;
    mapping(bytes32 => string) public extendElements;
    
    /**
    *   Function Description:
    *	Given a patientID, studyID, recordTime, consented category choices, and consented element choices,
    *   store a patient's consent record on-chain.
    *   Parameters:
    *       _patientID: uint256
    *       _studyID: uint256
    *       _recordTime: uint256
    *       _patientCategoryChoices: string[] calldata
    *       _patientElementChoices: string[] calldata
    */
    function storeRecord(uint256 _patientID, uint256 _studyID, uint256 _recordTime, string[] calldata _patientCategoryChoices, string[] calldata _patientElementChoices) public {
    // 获取Patient对象的引用，避免重复的mapping查找操作
    Patient storage patient1 = dataBase[_studyID][_patientID];
    
    // 创建新的Consent对象并推入数组
    Consent memory newConsent = Consent({
        recordTime: _recordTime, 
        categoryChoices: handlecategorySharingChoices(_patientCategoryChoices),
        elementChoices: handleelementSharingChoices(_patientElementChoices)
    });
    patient1.consent.push(newConsent);
    
    // 检查并更新leastdata
    uint256 leastdata = patient1.leastdata;
    if (patient1.consent[leastdata].recordTime < _recordTime) {
        patient1.leastdata = patient1.consent.length - 1;
    }
    dataBase[_studyID][_patientID]=patient1;
   // patient=dataBase[_studyID][_patientID];
    // 调用插入PatientID的函数
    insertPatientID(_patientID,_studyID);
    }

    /**
    *   Function Description:
    *	Given a studyID, endTime, requested category choices, and requested element choices,
    *	return a list of patientIDs that have consented to share with the study
    *	at least the requested categories and elements,
    *	and such consent was timestamped at or before _endTime.
    *	If there are several consents from the same patient for the same studyID
    *	made within the indicated timeframe
    *	then only the most recent one should be considered.
    *   Parameters:
    *      _studyID: uint256
    *      _endTime: int256
    *      _requestedCategoryChoices: string[] calldata
    *      _requestedElementChoices: string[] calldata
    *   Return:
    *       Array of consenting patientIDs: uint256[] memory
    */
    function queryForResearcher(uint256 _studyID, int256 _endTime, string[] calldata _requestedCategoryChoices, string[] calldata _requestedElementChoices) public view  returns(uint256[] memory) {
        /*
            Your code here.
        */
        uint256[] memory patientIDs;
        uint256[] memory patientIDsforRequry;
        bytes32[] memory Elementsfromquery;
        bytes32[] memory Categorysfromquery;
       // Categorysfromquery=extractchoicefromInputCategory(_requestedCategoryChoices);
        (Elementsfromquery,Categorysfromquery)=extractChoicesFromInput(_requestedElementChoices,_requestedCategoryChoices);
        
        patientIDs=decodePatientID(_studyID);
        patientIDsforRequry=getPatientIDs(patientIDs,_studyID,Categorysfromquery,Elementsfromquery,_endTime);

        return patientIDsforRequry;
    }

function getPatientIDs(uint256[] memory patientIDs,uint256 _studyID,bytes32[] memory categorysfromquery,bytes32[] memory elementsfromquery, int256 _endTime )public view returns(uint256[] memory ){
   // uint256 patientID;
    //uint256 leastdata;
   // uint256 recordTime;
   // bytes32 categorys;
   // bytes32 elements; 
    Patient  memory patient; 
    uint256 length=patientIDs.length;
    uint256[] memory PatientIDs=new uint256[](length);
    uint256 counter=0;
    bool    categoryexist;
    bool    elementexist;
    for(uint i=0;i<length;i++)
        {  
           //patientID=patientIDs[i];
           patient=dataBase[_studyID][patientIDs[i]];
           if(patientIDs[i]==0)break;
           //leastdata=dataBase[_studyID][patientID].leastdata;
           if(_endTime==-1){
            //categorys=patient.consent[patient.leastdata].categoryChoices;
            categoryexist=verifyexistenceOFcategory(categorysfromquery,patient.consent[patient.leastdata].categoryChoices);
            if(categoryexist)
            {   
               PatientIDs[counter]=(patientIDs[i]);
               counter++;
               continue;
            }
           // elements=patient.consent[patient.leastdata].elementChoices;
            elementexist=verifyexistenceOFelement(elementsfromquery,patient.consent[patient.leastdata].elementChoices);
            if(elementexist)
            {   
               PatientIDs[counter]=(patientIDs[i]);
               counter++;
               continue;
            }
           }else {
          // leastdata=patient.leastdata;
          // recordTime=patient.consent[patient.leastdata].recordTime;
           if(patient.consent[patient.leastdata].recordTime<=uint256(_endTime)){
            //categorys=patient.consent[patient.leastdata].categoryChoices;
            categoryexist=verifyexistenceOFcategory(categorysfromquery,patient.consent[patient.leastdata].categoryChoices);
            if(elementexist)
            {   
               PatientIDs[counter]=(patientIDs[i]);
               counter++;
               continue;
            }

            //elements=patient.consent[patient.leastdata].elementChoices;
            elementexist=verifyexistenceOFelement(elementsfromquery,patient.consent[patient.leastdata].elementChoices);
            if(elementexist)
            {   
               PatientIDs[counter]=(patientIDs[i]);
               counter++;
               continue;
            }

          }
          }
        }       
    return PatientIDs;           
}
function decodePatientID(uint256 _studyID)public view returns(uint256[] memory){
      bytes32 chunk=bytes32(uint256(65535));
      bytes32[] memory patientIDsEncode = patientsOfStudy[_studyID].patientIDs;
      uint256 length=patientIDsEncode.length;
      uint256 patientID;
      bool[2**16-1] memory isPresent ;
      uint256 counter;
      uint256[] memory patientIDs=new uint256[](16*patientIDsEncode.length);
      for(uint i=0;i<length;i++){
        for(uint j=0;j<16;j++){
        patientID=uint256((patientIDsEncode[i]>>16*j)&(chunk));
        if(!isPresent[patientID]){
            patientIDs[counter]=patientID;
             isPresent[patientID]=true;
             counter++;
            }
        }
      }
      return patientIDs;
} 

function  verifyexistenceOFelement(bytes32[] memory categoryNeeded,bytes32 elementsInDatabase)public pure returns(bool yes){
           bytes32 element;
           for(uint h=0;h<8;h++){
                element=getBytes32FromElements(elementsInDatabase,h*4);
                for(uint g=0;g<categoryNeeded.length;g++){
                    if(element==categoryNeeded[g]){
                    return true;
                    }
                }
            }
            return false;

}

function  verifyexistenceOFcategory(bytes32[] memory categoryNeeded,bytes32 catogorysInDatabase)public pure returns(bool yes){
           bytes32 category0;
           bytes32 category1;
            for(uint k=0;k<16;k+=2){
                category0=catogorysInDatabase[k];
                category1=(catogorysInDatabase[k+1]>>8)|category0;
                for(uint n=0;n<categoryNeeded.length;n++){
                    if(category1==categoryNeeded[n]){
                    return true;
                    }
                }
            }
            return false;
}



//提取出输入的category choice
function extractchoicefromInputCategory(string[] memory inputCategory )public pure returns(bytes32[]memory){
    bytes32[] memory requiredCategorys=new bytes32[](inputCategory.length);
    for(uint i=0;i<inputCategory.length;i++){
        requiredCategorys[i]=getPrefixBytes32forCategory(inputCategory[i]);
        }
    return requiredCategorys;
}
//提取出输入的element choice
function extractChoicesFromInput(string[] memory inputelement,string[] memory inputCategory)public pure returns(bytes32[]memory,bytes32[]memory){
    bytes32[] memory requiredElements= new bytes32[](inputelement.length);
    bytes32[] memory categorysfromqueryout = new bytes32[](inputelement.length+inputCategory.length);
    uint256 length=inputCategory.length;
    for(uint j=0;j<length;j++){
        categorysfromqueryout[j]=getPrefixBytes32forCategory(inputCategory[j]);
        }
    for(uint i=0;i<inputelement.length;i++){
        categorysfromqueryout[length+i]=getPrefixBytes32forCategory(inputelement[i]);
        requiredElements[i]=getPrefixBytes32forElement(inputelement[i]);
        }
    return (requiredElements,categorysfromqueryout);
}
    /**
    *   Function Description:
    *	Given a patientID, studyID, search start time, and search end time,
    *	return a concatenated string of the patient's consent history.
    *	The expected format of the returned string:
    *		Within the same consent: fields separated by comma.
    *		More than one consent returned: consents separated by newline character.
    *   For e.g:
    *		"studyID1,timestamp1,categorySharingChoices1,elementSharingChoices1\nstudyID2,timestamp2,categorySharingChoices2,elementSharingChoices2\n"
    *   Parameters:
    *       _patientID: uint256
    *       _studyID: int256
    *       _startTime: int256
    *       _endTime: int256
    *   Return:
    *       String of concatenated consent history: string memory
    */
 
    //处理categorySharingChoices这个string数组，生成编码好的bytes32并返回
    function handlecategorySharingChoices(string[] calldata categorySharingChoices) public returns (bytes32) {
    bytes32 result;
    bytes32 shortnumber;
    for (uint i = 0; i < categorySharingChoices.length; i++) {
      shortnumber = getPrefixBytes32forCategory(categorySharingChoices[i]);
      result |= shortnumber >> i * 16;

      extendCategorys[shortnumber]=categorySharingChoices[i];
    }
    return result;
    }
    
    
     

    //处理elementSharingChoices这个string数组，生成编码好的bytes32并返回
    function handleelementSharingChoices(string[] calldata elementSharingChoices) public  returns (bytes32[2] memory) {
    bytes32[2] memory result;
    bytes32 shortnumber;
    for (uint i = 0; i < elementSharingChoices.length; i++) {
      if(i<8){
      shortnumber = getPrefixBytes32forElement(elementSharingChoices[i]);
      result[1] |= shortnumber >> (i * 32);
      extendElements[shortnumber]=elementSharingChoices[i];
      }else{
        shortnumber = getPrefixBytes32forElement(elementSharingChoices[i]);
        result[2] |= shortnumber >> ((i-8) * 32);
        extendElements[shortnumber]=elementSharingChoices[i];
      }
    }
    return result;
    }
    function getPrefixBytes32forElement(string memory s) public pure returns (bytes32) {
        
    bytes memory b = bytes(s);
    bytes32 b1 = 0;
    bytes32 b2 = 0;
    bytes32 b3 = 0;
    bytes32 b4 = 0;
    // 取出第一个数字
    b1 = bytes32(b[0]);
    //取出第二个数字
    b2 = bytes32(b[1]);
    b3 = bytes32(b[3]);
    b4=  bytes32(b[4]);
    return b1 |(b2>>8)|(b3>>16)|(b4>>24);
    }
    function getPrefixforElement(bytes32  b) public pure returns (bytes32[] memory) {
    bytes32 chunk3=bytes32(uint256(4294967295))<<224;
    bytes32[] memory a=new bytes32[](8);
    for(uint i=0;i<8;i++){
    a[i]= b |(chunk3>>32*i);
    }
    return a;
    }

   //注：uint256(0x01)<<2 | uint256(0x04) = 0x104 = 260  bytes32(260）=0x0000000000000000000000000000000000000000000000000000000000000104
   function getPrefixBytes32forCategory(string memory s) public pure returns (bytes32) {
    bytes memory b = bytes(s);
    bytes32 b1 = 0;
    bytes32 b2=0;
    // 取出第一个数字
    b1 = bytes32(b[0]);
    b2=  bytes32(b[1]);
    return b1|(b2>>8);
    }
    //插入patientID到patientsOfStudy中
    function insertPatientID(uint256 _patientID, uint256 _studyID) public {
        uint256   flag   = patientsOfStudy[_studyID].flag;
        if (flag<=15){
        uint256 length = patientsOfStudy[_studyID].patientIDs.length;
        if(length==0)
        {
        patientsOfStudy[_studyID].patientIDs.push(bytes32(_patientID));
        }else{
        bytes32 patientIDs = patientsOfStudy[_studyID].patientIDs[length-1];
        patientsOfStudy[_studyID].patientIDs[length-1]=patientIDs|(bytes32(_patientID)<<(16*flag));
        }
        patientsOfStudy[_studyID].flag=flag+1;
        }else{
        patientsOfStudy[_studyID].patientIDs.push(bytes32(_patientID));
        patientsOfStudy[_studyID].flag=0;
        }
    }


 function queryForPatient(uint256 _patientID, int256 _studyID, int256 _startTime, int256 _endTime) public view returns(string memory output) {
        require(_patientID>=0,"Invalid patientID");
        if(_startTime==-1){
            _startTime=0;
        }
        if(_endTime==-1){
            _endTime=9999999999;
        }

        bool foundConsent = false; // Flag to track if any consent was found

        require(_startTime<=_endTime,"Invalid time input");

        if (_studyID == -1) {
        for (uint256 i = 0; i <= 100; i++) {
            if(dataBase[i][_patientID].consent.length>0){
            Patient storage patient2 = dataBase[i][_patientID];

            for (uint256 j = 0; j < patient2.consent.length; j++) {
                if (uint256(_startTime) <= patient2.consent[j].recordTime && patient2.consent[j].recordTime <= uint256(_endTime)) {
                    output = string(abi.encodePacked(output, getConsentString(i, patient2.consent[j])));
                    foundConsent = true;
                }
            }
        }
        }
    } else {
        if (dataBase[uint256(_studyID)][_patientID].consent.length > 0) {
        Patient storage patient3 = dataBase[uint256(_studyID)][_patientID];
        for (uint256 j = 0; j < patient3.consent.length; j++) {
            if (uint256(_startTime) <= patient3.consent[j].recordTime && patient3.consent[j].recordTime <= uint256(_endTime)) {
                output = string(abi.encodePacked(output, getConsentString(uint256(_studyID), patient3.consent[j])));
                foundConsent = true;
            }
        }
    }
    }
     if (!foundConsent) {
        return "No matching consents found.";
    }
       return output;

    }

    function getConsentString(uint256 _studyID, Consent storage c) internal view returns(string memory) {
        string memory result;
        result = string(abi.encodePacked(uint2str(_studyID),",",uint2str(c.recordTime),",[",stringToFullCategoryChoices(c.categoryChoices),"],[", stringToFullElementChoices(c.elementChoices),"]\n"));
        return result;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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
                uint k = len;
                while (_i != 0) {
                    k = k-1;
                    uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                    bytes1 b1 = bytes1(temp);
                    bstr[k] = b1;
                    _i /= 10;}
                    return string(bstr);
    }
 
 


    function stringToFullCategoryChoices(bytes32 input) public view returns (string memory) {
        uint len = 0;
         while (len < 32 && input[len] != 0) {
        len++;
    }
        string memory result;
        string memory finallyresult;
        bytes memory bytesArray = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            bytesArray[i] = input[i];   
            result=extendCategorys[bytes32(bytesArray[i])];
            finallyresult=string(abi.encodePacked(finallyresult,result));
        }
        return finallyresult;
    }


    function stringToFullElementChoices(bytes32 input) public view returns (string memory) {
        bytes32[] memory a;
        string memory result;
        string memory finallyresult;
        a = getPrefixforElement(input);

        for (uint256 i = 0; i < a.length; i++) {
            if(a[i].length==0){
                continue;
            }
            result=extendElements[a[i]];
            finallyresult=string(abi.encodePacked(finallyresult,result));
        }
        return finallyresult;
    }

   
   function getBytes32FromElements(bytes32  b, uint start) internal pure returns (bytes32) {
    bytes32 result = 0;
    for (uint i = start; i < start + 4; i++) {
      result |= bytes32(b[i]) >> (i - start) * 8;
    }
    return result;
}
}
