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
    mapping(uint256 => mapping(uint256 => Consent[] )) public dataBase;
    // Patient  patient;
    mapping(uint256 => patientsEncode) public patientsOfStudy;
    struct patientsEncode {
        bytes32[] patientIDs;
        uint256 flag; //flag为0到7，表示patientIDs[length-1]已编码进去的patientID的个数
    }
    struct Consent {
        uint256 recordTime;
        bytes32 categoryChoices;
        bytes32 elementChoices;
    }
    struct Patient {
        Consent[] consent;
        uint256 leastdata;
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
        Consent memory newConsent = Consent({
            recordTime: _recordTime,
            categoryChoices: handlecategorySharingChoices(
                _patientCategoryChoices
            ),
            elementChoices: handleelementSharingChoices(_patientElementChoices)
        });
        patient1.push(newConsent);
        
        dataBase[_studyID][_patientID] = patient1;
        // patient=dataBase[_studyID][_patientID];
        // 调用插入PatientID的函数
        insertPatientID(_patientID, _studyID);
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
        bytes32[] memory Categorysfromquery;
        bytes32[] memory categorysforElementFromquery;
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

    function getPatientIDs(
        uint256[] memory _patientIDs,
        uint256 _studyID,
        bytes32[] memory categorysfromquery,
        bytes32[] memory elementsfromquery,
        bytes32[] memory categorysforElementFromquery,
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
            if (_patientIDs[i] == 0) break;  //如果patientID为0，说明已经到了最后一个，直接跳出循环
            (index,empty)=findTheLatestOne(_patientIDs[i],_studyID,_endTime);
            if (empty==false){
                continue;
            }
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
    function checkConsent(uint256 _index,uint256 _patitentID,uint256 _studyID,  bytes32[] memory categorysfromquery, bytes32[] memory elementsfromquery,bytes32[] memory categorysforElementFromquery)public view returns(bool){
        Consent memory consent;
        bool categoryexist;
        uint256 counter0;
        uint256 counter1;
        consent=dataBase[_studyID][_patitentID][_index];
           
                categoryexist = verifyexistenceOFcategory(
                    categorysfromquery,
                    consent.categoryChoices
                );
                counter0=verifyexistenceOFcategoryForElement(categorysforElementFromquery, consent.categoryChoices);
                counter1 = verifyexistenceOFelement(
                    elementsfromquery,
                    consent.elementChoices
                );
                if (categoryexist&&((counter0+counter1)==elementsfromquery.length)) {
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
        }
        for(uint256 i=length-1;i>=0;i--){
            if(patient[i].recordTime<=uint256(_endTime)){
                return (i,true);
            }
        }
        return (0,false);
    }
    
    function decodePatientID(
        uint256 _studyID
    ) public view returns (uint256[] memory) {
        bytes32 chunk = bytes32(uint256(65535));
        bytes32[] memory patientIDsEncode = patientsOfStudy[_studyID]
            .patientIDs;
        uint256 length = patientIDsEncode.length;
        uint256 patientID;
        bool[2 ** 16 - 1] memory isPresent;
        uint256 counter;
        uint256[] memory patientIDs = new uint256[](
            16 * patientIDsEncode.length
        );
        for (uint i = 0; i < length; i++) {
            for (uint j = 0; j < 16; j++) {
                patientID = uint256(
                    (patientIDsEncode[i] >> (16 * j)) & (chunk)
                );
                if (!isPresent[patientID]) {
                    patientIDs[counter] = patientID;
                    isPresent[patientID] = true;
                    counter++;
                }
            }
        }
        return patientIDs;
    }

    function verifyexistenceOFcategory(
        bytes32[] memory categoryNeeded,
        bytes32 catogorysInDatabase
    ) public pure returns (bool yes) {
        bytes32 category0;
        bytes32 category1;
        bool exist=false;
        for (uint n = 0; n < categoryNeeded.length; n++) {
            for (uint k = 0; k < 32; k += 2) {
            category0 = bytes32(catogorysInDatabase[k]);
            category1 = (bytes32(catogorysInDatabase[k + 1]) >> 8) | category0;
                if (category1 == categoryNeeded[n]) {
                   exist=true;
                }
            }
            if (exist==false){
                return false;
            }
        }
        return true;
    }
    function verifyexistenceOFcategoryForElement(
        bytes32[] memory categoryNeeded,
        bytes32 catogorysInDatabase
    ) public pure returns (uint256) {
        bytes32 category0;
        bytes32 category1;
        uint256 counterOfSatisfied=0;
        for (uint n = 0; n < categoryNeeded.length; n++) {
            for (uint k = 0; k < 32; k += 2) {
            category0 = bytes32(catogorysInDatabase[k]);
            category1 = (bytes32(catogorysInDatabase[k + 1]) >> 8) | category0;
                if (category1 == categoryNeeded[n]) {
                   counterOfSatisfied+=1;
                }
            }
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
        for (uint h = 0; h < 32; h += 2) {
            element0 = bytes32(elementsInDatabase[h]);
            element1 = (bytes32(elementsInDatabase[h + 1]) >> 8) | element0;
            //element=getBytes32FromElements(elementsInDatabase,h*2);
            for (uint g = 0; g < categoryNeeded.length; g++) {
                if (element1 == categoryNeeded[g]) {
                     counterOfSatisfied+=1;
                }
            }
        }
        return counterOfSatisfied;
    }

    // //提取出输入的category choice
    // function extractchoicefromInputCategory(string[] memory inputCategory )public pure returns(bytes32[]memory){
    //     bytes32[] memory requiredCategorys=new bytes32[](inputCategory.length);
    //     for(uint i=0;i<inputCategory.length;i++){
    //         requiredCategorys[i]=getPrefixBytes32forCategory(inputCategory[i]);
    //         }
    //     return requiredCategorys;
    // }
    //提取出输入的element choice
    function extractChoicesFromInput(
        string[] memory inputelement,
        string[] memory inputCategory
    ) public pure returns (bytes32[] memory, bytes32[] memory,bytes32[] memory) {
        bytes32[] memory requiredElements = new bytes32[](inputelement.length);
        bytes32[] memory categorysforElementFromquery=new bytes32[](inputelement.length);
        bytes32[] memory categorysfromqueryout = new bytes32[]( inputCategory.length);
        uint256 length = inputCategory.length;
        for (uint j = 0; j < length; j++) {
            categorysfromqueryout[j] = getPrefixBytes32forCategory(
                inputCategory[j]
            );
        }
        for (uint i = 0; i < inputelement.length; i++) {
            categorysforElementFromquery[i] = getPrefixBytes32forCategory(
                inputelement[i]
            );
            requiredElements[i] = getPrefixBytes32forElement(inputelement[i]);
        }
        return (requiredElements, categorysfromqueryout,categorysforElementFromquery);
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
        string[] calldata categorySharingChoices
    ) public returns (bytes32) {
        bytes32 result;
        bytes32 shortnumber;
        bytes memory q;
        for (uint i = 0; i < categorySharingChoices.length; i++) {
            shortnumber = getPrefixBytes32forCategory(
                categorySharingChoices[i]
            );
            result |= shortnumber >> (i * 16);
            q = bytes(extendCategorys[shortnumber]);
            if (q.length == 0) {
                extendCategorys[shortnumber] = categorySharingChoices[i];
            }
        }
        return result;
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

    function getPrefixfor(bytes32 b) public pure returns (bytes32[] memory) {
        bytes32 b1 = 0;
        bytes32 b2 = 0;
        bytes32[] memory a = new bytes32[](16);
        for (uint i = 0; i < 16; i += 2) {
            // 取出第一个数字
            b1 = bytes32(b[i]);
            //取出第二个数字
            b2 = bytes32(b[i + 1]);
            a[i] = b1 | (b2 >> 8);
        }
        return a;
    }

    //注：uint256(0x01)<<2 | uint256(0x04) = 0x104 = 260  bytes32(260）=0x0000000000000000000000000000000000000000000000000000000000000104
    function getPrefixBytes32forCategory(
        string memory s
    ) public pure returns (bytes32) {
        bytes memory b = bytes(s);
        bytes32 b1 = 0;
        bytes32 b2 = 0;
        // 取出第一个数字
        b1 = bytes32(b[0]);
        b2 = bytes32(b[1]);
        return b1 | (b2 >> 8);
    }

    //插入patientID到patientsOfStudy中
    function insertPatientID(uint256 _patientID, uint256 _studyID) public {
        uint256 flag = patientsOfStudy[_studyID].flag;
        if (flag <= 15) {
            uint256 length = patientsOfStudy[_studyID].patientIDs.length;
            if (length == 0) {
                patientsOfStudy[_studyID].patientIDs.push(bytes32(_patientID));
            } else {
                bytes32 patientIDs = patientsOfStudy[_studyID].patientIDs[
                    length - 1
                ];
                patientsOfStudy[_studyID].patientIDs[length - 1] =
                    patientIDs |
                    (bytes32(_patientID) << (16 * flag));
            }
            patientsOfStudy[_studyID].flag = flag + 1;
        } else {
            patientsOfStudy[_studyID].patientIDs.push(bytes32(_patientID));
            patientsOfStudy[_studyID].flag = 0;
        }
    }

    function queryForPatient(
        uint256 _patientID,
        int256 _studyID,
        int256 _startTime,
        int256 _endTime
    ) public view returns (string memory output) {
        require(_patientID >= 0, "Invalid patientID");
        if (_startTime == -1) {
            _startTime = 0;
        }
        if (_endTime == -1) {
            _endTime = 9999999999;
        }

        bool foundConsent = false; // Flag to track if any consent was found

        require(_startTime <= _endTime, "Invalid time input");

        if (_studyID == -1) {
            for (uint256 i = 0; i <= 100; i++) {
                if (dataBase[i][_patientID].length > 0) {
                        Consent[] memory patient2 = dataBase[i][_patientID];

                    for (uint256 j = 0; j < patient2.length; j++) {
                        if (
                            uint256(_startTime) <=
                            patient2[j].recordTime &&
                            patient2[j].recordTime <= uint256(_endTime)
                        ) {
                            output = string(
                                abi.encodePacked(
                                    output,
                                    getConsentString(i, patient2[j])
                                )
                            );
                            foundConsent = true;
                        }
                    }
                }
            }
        } else {
            if (dataBase[uint256(_studyID)][_patientID].length > 0) {
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

    function getConsentString(
        uint256 _studyID,
        Consent storage c
    ) internal view returns (string memory) {
        string memory result;
        result = string(
            abi.encodePacked(
                uint2str(_studyID),
                ",",
                uint2str(c.recordTime),
                ",[",
                stringToFullCategoryChoices(c.categoryChoices),
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
        a = getPrefixfor(input);

        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == 0) {
                continue;
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
        a = getPrefixfor(input);

        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == 0) {
                continue;
            }
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

    function getBytes32FromElements(
        bytes32 b,
        uint start
    ) internal pure returns (bytes32) {
        bytes32 result = 0;
        for (uint i = start; i < start + 2; i++) {
            result |= bytes32(b[i]) >> ((i - start) * 8);
        }
        return result;
    }
}