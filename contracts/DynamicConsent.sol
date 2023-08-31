// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12;
/**
 * Team Name:  Maxe
 *
 *   Team Member 1:
 *       { Name:  , Email:  }
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

contract DynamicConsent{

    // studyID=> patientID  => Patient 数据
    mapping(uint256 => mapping(uint256 => Consent[] )) public dataBase;
    // Patient  patient;
    mapping(uint256 => patientsEncode) public patientsOfStudy;
    mapping(uint256=>mapping(uint256 => bool)) patientIDinstudy;
    struct patientsEncode {
        bytes32[] patientIDs;
        uint256 flag; //flag为0到7，表示patientIDs[length-1]已编码进去的patientID的个数
    }
    struct Consent {
        uint256 recordTime;
        bytes32 categoryChoices;
        bytes32 categoryChoicesNum;
        bytes32 elementChoices;
    }

    mapping(bytes32 => string) public extendCategorys;
    mapping(bytes32 => string) public extendElements;
    mapping(uint256=>uint256[]) public studyIDofPatient;
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
    function storeRecord(
        uint256 _patientID,
        uint256 _studyID,
        uint256 _recordTime,
        string[] calldata _patientCategoryChoices,
        string[] calldata _patientElementChoices
    ) public {
        // 获取Patient对象的引用，避免重复的mapping查找操作
        Consent[] storage patient1 = dataBase[_studyID][_patientID];
        // 创建新的Consent对象并推入数组
        bytes32 categoryChoices0;
        bytes32 categoryChoices1;
        (categoryChoices0,categoryChoices1)=handlecategorySharingChoices(
                _patientCategoryChoices
            );
        Consent memory newConsent = Consent({
            recordTime: _recordTime,
            categoryChoices: categoryChoices0,
            categoryChoicesNum: categoryChoices1,
            elementChoices: handleelementSharingChoices(_patientElementChoices)
        });
        patient1.push(newConsent);
        
        dataBase[_studyID][_patientID] = patient1;
        // patient=dataBase[_studyID][_patientID];
        // 调用插入PatientID的函数
        if(!patientIDinstudy[_studyID][_patientID]){
            insertPatientID(_patientID, _studyID);
            studyIDofPatient[_patientID].push(_studyID);
            patientIDinstudy[_studyID][_patientID]=true;
        }
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
    function queryForResearcher(
        uint256 _studyID,
        int256 _endTime,
        string[] calldata _requestedCategoryChoices,
        string[] calldata _requestedElementChoices
    ) public view returns (uint256[] memory) {
        /*
            Your code here.
        */
        uint256[] memory patientIDs;
        //uint256[] memory patientIDsforRequry;
        bytes32[] memory Elementsfromquery;
        bytes32 Categorysfromquery;
        uint256[] memory categorysforElementFromquery;
        // Categorysfromquery=extractchoicefromInputCategory(_requestedCategoryChoices);
        (Elementsfromquery, Categorysfromquery, categorysforElementFromquery) = extractChoicesFromInput(
            _requestedElementChoices,
            _requestedCategoryChoices
        );

        patientIDs = decodePatientID(_studyID);
        patientIDs = getPatientIDs(
            patientIDs,
            _studyID,
            Categorysfromquery,
            Elementsfromquery,
            categorysforElementFromquery,
            _endTime
        );

        return patientIDs;
    }
    
    function extractChoicesFromInput(
        string[] memory inputelement,
        string[] memory inputCategory
    ) public pure returns (bytes32[] memory, bytes32,uint256[] memory) {
        bytes32[] memory requiredElements = new bytes32[](inputelement.length);
        uint256[] memory categoryQueryofElement=new uint256[](inputelement.length);
        bytes32 categoryQuery;
        uint256 lengthElement =  inputelement.length;
        categoryQuery=extractcategory(inputCategory);
        for (uint i = 0; i < lengthElement; i++) {
                categoryQueryofElement[i] = getPrefixBytes32forCategoryForelement(
                inputelement[i]
            );
            requiredElements[i] = getPrefixBytes32forElement(inputelement[i]);
        }
        return (requiredElements, categoryQuery,categoryQueryofElement);
    }
    function extractcategory(string[] memory inputCategory)public pure returns(bytes32){
       
        bytes32 allff=0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        uint256 number;
        bytes32 zero=0xff00000000000000000000000000000000000000000000000000000000000000;
        uint256 length=inputCategory.length;
        for (uint i = 0; i < length; i++) {
            number = getPrefixBytes32forCategoryToinput(
                inputCategory[i]
            );
            allff ^= zero >> (number * 8); 
        }
        return allff;
    }

    function getPatientIDs(
        uint256[] memory _patientIDs,
        uint256 _studyID,
        bytes32  categorysfromquery,
        bytes32[] memory elementsfromquery,
        uint256[] memory categorysforElementFromquery,
        int256 _endTime
    ) public view returns (uint256[] memory) {
       // Patient memory patient;
        uint256 length = _patientIDs.length;
        uint256[] memory PatientIDs = new uint256[](length);
        uint256 counter = 0;
        bool satisfied;
        bool empty;
        uint256 index;
        for (uint i = 0; i < length; i++) {
            //if (_patientIDs[i] == 0) break;  //如果patientID为0，说明已经到了最后一个，直接跳出循环
            (index,empty)=findTheLatestOne(_patientIDs[i],_studyID,_endTime);
            if (empty==false){
                continue;
            }
            satisfied=false;
            satisfied=checkConsent(index,_patientIDs[i],_studyID,categorysfromquery,elementsfromquery,categorysforElementFromquery);
            if(satisfied){
                PatientIDs[counter]=(_patientIDs[i]);
                counter++;
            }
            
        }        
        assembly {
            // 获取原数组的长度位置
            let oldLengthPtr := PatientIDs
            // 修改长度值
            mstore(oldLengthPtr, counter)
        }
        return PatientIDs;
    }
    //判断该档案dataBase[_studyID][_patientIDs[i]].consent[index];是否满足条件
    function checkConsent(uint256 _index,uint256 _patitentID,uint256 _studyID,  bytes32 categorysfromquery, bytes32[] memory elementsfromquery,uint256[] memory categorysforElementFromquery)public view returns(bool){
        Consent memory consent;
        bool categoryexist;
        uint256 counter0;
        uint256 counter1;
        bytes32 result;
        consent=dataBase[_studyID][_patitentID][_index];
           
        result=categorysfromquery|consent.categoryChoices;
        if(result==0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)categoryexist=true;
        if(elementsfromquery.length!=0){
        counter0=verifyexistenceOFcategoryForElement(categorysforElementFromquery, consent.categoryChoices);
        counter1 = verifyexistenceOFelement(
                    elementsfromquery,
                    consent.elementChoices
                );
        }
         if (categoryexist&&((counter0+counter1)>=elementsfromquery.length)) {
                    return true;
                }else{
                    return false;
                }
        
                
    }
    //bool用于判断patient是否为空
    function findTheLatestOne(uint256 _patientID,uint256 _studyID,int256 _endTime) public view returns(uint256,bool ){
        Consent[] memory patient;
        patient=dataBase[_studyID][_patientID];
        uint256 length=patient.length;
        //uint256 index=0;
       
        if (length==0){
            return (0,false);
        }
        if(_endTime<0){
            return (length-1,true);
        }else{
        for(uint256 i=length;i>0;i--){
            if(patient[i-1].recordTime<=uint256(_endTime)){
                return (i-1,true);
            }
        }
        }
        return (0,false);
    }
    
    function decodePatientID(
        uint256 _studyID
    ) public view returns (uint256[] memory) {
        bytes32 chunk = bytes32(uint256(4294967295));
        bytes32[] memory patientIDsEncode = patientsOfStudy[_studyID]
            .patientIDs;
        uint256 length = patientIDsEncode.length;
        uint256 patientID; 
        uint256 counter;
        uint256[] memory patientIDs = new uint256[](
            8 * patientIDsEncode.length
        );
        for (uint i = 0; i < length; i++) {
            for (uint j = 0; j < 8; j++) {
                patientID = uint256(
                    (patientIDsEncode[i] >> (32 * j)) & (chunk)
                );
                if(patientID==0)break;
                patientIDs[counter] = patientID;
                counter++;
            }
            if(patientID==0)break;
        }
        assembly {
            // 获取原数组的长度位置
            let oldLengthPtr := patientIDs
            // 修改长度值
            mstore(oldLengthPtr, counter)
        }
        return patientIDs;
    }


    function verifyexistenceOFcategoryForElement(
        uint256[] memory categoryNeeded,
        bytes32 catogorysInDatabase
    ) public pure returns (uint256) {
        uint256 length=categoryNeeded.length;
        uint256 counterOfSatisfied=0;
        for (uint n = 0; n < length; n++) {
            if(catogorysInDatabase[categoryNeeded[n]]!=0)counterOfSatisfied++;
        }
        return counterOfSatisfied;
    }
    function verifyexistenceOFelement(
        bytes32[] memory categoryNeeded,
        bytes32 elementsInDatabase
    ) public pure returns (uint256) {
        bytes32 element0;
        bytes32 element1;
        uint256 counterOfSatisfied=0;
        bytes32 zero;
        for (uint h = 0; h < categoryNeeded.length; h ++) {
            for (uint g = 0; g < 32; g+=2) {
                element0 = bytes32(elementsInDatabase[g]);
                element1 = (bytes32(elementsInDatabase[g + 1]) >> 8) | element0;
                if(element1==zero)break;
                if (element1 == categoryNeeded[h]) {
                     counterOfSatisfied+=1;
                     break;
                }
            }
        }
        return counterOfSatisfied;
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
    function handlecategorySharingChoices(
        string[] memory categorySharingChoices
    ) public returns (bytes32,bytes32) {
       
        bytes32 shortnumber;
        bytes memory q;
        uint256 number;
        bytes32 result;
        bytes32 resultForNum;
        bytes32 chunk=0xff00000000000000000000000000000000000000000000000000000000000000;

        for (uint i = 0; i < categorySharingChoices.length; i++) {
            (shortnumber,number) = getPrefixBytes32forCategory(
                categorySharingChoices[i]
            );
            result |= chunk >> (number * 8);
            resultForNum|=shortnumber>> (i * 8);
            q = bytes(extendCategorys[shortnumber]);
            if (q.length == 0) {
                extendCategorys[shortnumber] = categorySharingChoices[i];
            }
        }
        return (result,resultForNum);
    }

    //处理elementSharingChoices这个string数组，生成编码好的bytes32并返回
    function handleelementSharingChoices(
        string[] calldata elementSharingChoices
    ) public returns (bytes32) {
        bytes32 result;
        bytes32 shortnumber;
        bytes memory q;
        for (uint i = 0; i < elementSharingChoices.length; i++) {
            shortnumber = getPrefixBytes32forElement(elementSharingChoices[i]);
            result |= shortnumber >> (i * 16);
            q = bytes(extendElements[shortnumber]);
            if (q.length == 0) {
                extendElements[shortnumber] = elementSharingChoices[i];
            }
        }
        return result;
    }

    function getPrefixBytes32forElement(
        string memory s
    ) public pure returns (bytes32) {
        bytes memory b = bytes(s);

        uint b1 = 0;
        uint b2 = 0;
        uint b3 = 0;
        uint b4 = 0;
        // 取出第一个数字
        b1 = uint8(b[0]) - 48;
        //取出第二个数字
        b2 = uint8(b[1]) - 48;
        b3 = uint8(b[3]) - 48;
        b4 = uint8(b[4]) - 48;
        b1 = b1 * 10 + b2;
        b3 = b3 * 10 + b4;
        return bytes32((b1 << 248) | (b3 << 240));
    }



    //注：uint256(0x01)<<2 | uint256(0x04) = 0x104 = 260  bytes32(260）=0x0000000000000000000000000000000000000000000000000000000000000104
    function getPrefixBytes32forCategory(
        string memory s
    ) public pure returns (bytes32,uint256) {
        bytes memory b = bytes(s);
        uint b1 = 0;
        uint b2 = 0;
        // 取出第一个数字
        b1 = uint8(b[0])-48;
        b2 = uint8(b[1])-48;
        b1 = b1*10+b2;
        return (bytes32((b1 << 248)),b1);
    }
 function getPrefixBytes32forCategoryToinput(
        string memory s
    ) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint b1 = 0;
        uint b2 = 0;
        // 取出第一个数字
        b1 = uint8(b[0])-48;
        b2 = uint8(b[1])-48;
        b1 = b1*10+b2;
        return b1;
    }
       //注：uint256(0x01)<<2 | uint256(0x04) = 0x104 = 260  bytes32(260）=0x0000000000000000000000000000000000000000000000000000000000000104
    function getPrefixBytes32forCategoryForelement(
        string memory s
    ) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 b1 = 0;
        uint256 b2 = 0;
        // 取出第一个数字
        b1 = uint8(b[0])-48;
        b2 = uint8(b[1])-48;
        b1 = b1*10+b2;
        return b1;
    }

    //插入patientID到patientsOfStudy中
    function insertPatientID(uint256 _patientID, uint256 _studyID) public {
        uint256 flag = patientsOfStudy[_studyID].flag;

        if (flag <= 7) {
            uint256 length = patientsOfStudy[_studyID].patientIDs.length;
            if (length == 0) {
                patientsOfStudy[_studyID].patientIDs.push(bytes32(_patientID));
            } else {
                bytes32 patientIDs = patientsOfStudy[_studyID].patientIDs[
                    length - 1
                ];
                patientsOfStudy[_studyID].patientIDs[length - 1] =
                    patientIDs |
                    (bytes32(_patientID) << (32 * flag));
            }
            patientsOfStudy[_studyID].flag = flag + 1;
        } else {
            patientsOfStudy[_studyID].patientIDs.push(bytes32(_patientID));
            patientsOfStudy[_studyID].flag = 1;
        }
    }

    function queryForPatient(
        uint256 _patientID,
        int256 _studyID,
        int256 _startTime,
        int256 _endTime
    ) public view returns (string memory output) {
        uint256[] memory studyIDs;
        Consent[] memory patient2;
        if (_startTime == -1) {
            _startTime = 0;
        }
        if (_endTime == -1) {
            _endTime = 99999999999;
        }
        if (_studyID == -1) {
            studyIDs=studyIDofPatient[_patientID];
            uint256 lengthOfStudy=studyIDs.length;
            for (uint256 i = 0; i <lengthOfStudy; i++) {
                patient2 = dataBase[studyIDs[i]][_patientID];
                for (uint256 j = 0; j < patient2.length; j++) {
                        if (
                            uint256(_startTime) <=
                            patient2[j].recordTime &&
                            patient2[j].recordTime <= uint256(_endTime)
                        ) {
                            output = string(
                                abi.encodePacked(
                                    output,
                                    getConsentString(studyIDs[i], patient2[j])
                                )
                            );
                       
                        }
                    }
            }

        } else {
            Consent[] memory patient3 = dataBase[uint256(_studyID)][
                    _patientID
                ];
                for (uint256 j = 0; j < patient3.length; j++) {
                    if (
                        uint256(_startTime) <= patient3[j].recordTime &&
                        patient3[j].recordTime <= uint256(_endTime)
                    ) {
                        output = string(
                            abi.encodePacked(
                                output,
                                getConsentString(
                                    uint256(_studyID),
                                    patient3[j]
                                )
                            )
                        );
                    }
                }
        }
        return output;
    }

    function getConsentString(
        uint256 _studyID,
        Consent memory c
    ) internal view returns (string memory) {
        string memory result;
        result = string(
            abi.encodePacked(
                uint2str(_studyID),
                ",",
                uint2str(c.recordTime),
                ",[",
                stringToFullCategoryChoices(c.categoryChoicesNum),
                "],[",
                stringToFullElementChoices(c.elementChoices),
                "]\n"
            )
        );
        return result;
    }

    function uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
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
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function stringToFullCategoryChoices(
        bytes32 input
    ) public view returns (string memory) {
        bytes32[] memory a;
        string memory result;
        string memory finallyresult;
        bytes32 zero;
        a = getPrefixforCategory(input);

        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == zero) {
                break;
            }
            result = extendCategorys[a[i]];
            if (i == 0) {
                finallyresult = result;
            } else {
                finallyresult = string(
                    abi.encodePacked(finallyresult, ",", result)
                );
            }
        }
        return finallyresult;
    }

    function stringToFullElementChoices(
        bytes32 input
    ) public view returns (string memory) {
        bytes32[] memory a;
        string memory result;
        string memory finallyresult;
        a = getPrefixforElement(input);

        for (uint256 i = 0; i < a.length; i++) {
            result = extendElements[a[i]];
            if (i == 0) {
                finallyresult = result;
            } else {
                finallyresult = string(
                    abi.encodePacked(finallyresult, ",", result)
                );
            }
        }
        return finallyresult;
    }
    function getPrefixforElement(bytes32 b) public pure returns (bytes32[] memory) {
        bytes32 b1 = 0;
        bytes32 b2 = 0;
        uint256 counter;
        bytes32 zero;
        uint256 j;
        bytes32[] memory a = new bytes32[](16);
        for (uint i = 0; i < 32; i += 2) {
            // 取出第一个数字
            b1 = bytes32(b[i]);
            //取出第二个数字
            b2 = bytes32(b[i + 1]);
            j=i/2;
            a[j] = b1 | (b2 >> 8);
            if(a[j]==zero){
                counter=j;
                break;
            }
        }
        assembly {
            // 获取原数组的长度位置
            let oldLengthPtr := a
            // 修改长度值
            mstore(oldLengthPtr, counter)
        }
        return a;
    }

    function getPrefixforCategory(bytes32 b) public pure returns (bytes32[] memory) {
        bytes32[] memory a = new bytes32[](32);
        uint256 counter;
        bytes32 zero;
        for (uint i = 0; i < 32; i ++) {
            // 取出第一个数字
            a[i] = bytes32(b[i]) ;
            if(a[i]==zero){
                counter=i;
                break;
            }
        }
        assembly {
            // 获取原数组的长度位置
            let oldLengthPtr := a
            // 修改长度值
            mstore(oldLengthPtr, counter)
        }
        return a;
    }
}
