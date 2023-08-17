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
    bytes32 chunk = bytes32(uint256(65535));
    // studyID=> patientID  => Patient 数据
    mapping(uint256 => mapping(uint256 => Patient)) public dataBase;
    bytes32[] Categorysfromquery;
    bytes32[] Elementsfromquery;
    Patient patient;
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
        Patient storage patient1 = dataBase[_studyID][_patientID];

        // 创建新的Consent对象并推入数组
        Consent memory newConsent = Consent({
            recordTime: _recordTime,
            categoryChoices: handlecategorySharingChoices(
                _patientCategoryChoices
            ),
            elementChoices: handleelementSharingChoices(_patientElementChoices)
        });
        patient1.consent.push(newConsent);

        // 检查并更新leastdata
        uint256 leastdata = patient1.leastdata;
        if (patient1.consent[leastdata].recordTime < _recordTime) {
            patient1.leastdata = patient1.consent.length - 1;
        }
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
    ) public returns (uint256[] memory patientIDsforRequry) {
        /*
            Your code here.
        */
        uint256[] memory patientIDs;
        Categorysfromquery = extractchoicefromInputCategory(
            _requestedCategoryChoices
        );
        (Elementsfromquery, Categorysfromquery) = extractchoicefromInputElement(
            _requestedElementChoices,
            Categorysfromquery
        );

        patientIDs = decodePatientID(_studyID);
        patientIDsforRequry = getPatientIDs(
            patientIDs,
            _studyID,
            Categorysfromquery,
            Elementsfromquery,
            _endTime
        );
        return patientIDsforRequry;
    }

    function getPatientIDs(
        uint256[] memory patientIDs,
        uint256 _studyID,
        bytes32[] memory categorysfromquery,
        bytes32[] memory elementsfromquery,
        int256 _endTime
    ) public view returns (uint256[] memory PatientIDs) {
        uint256 patientID;
        uint256 leastdata;
        uint256 recordTime;
        bytes32 categorys;
        bytes32 elements;
        for (uint i = 0; i < patientIDs.length; i++) {
            patientID = patientIDs[i];
            if (patientID == 0) break;
            //patient=dataBase[_studyID][patientID];
            leastdata = dataBase[_studyID][patientID].leastdata;
            if (_endTime == -1) {
                categorys = dataBase[_studyID][patientID]
                    .consent[leastdata]
                    .categoryChoices;
                bool exist = verifyexistenceOFcategory(
                    categorysfromquery,
                    categorys
                );
                if (exist) {
                    PatientIDs[PatientIDs.length] = patientID;
                }

                elements = dataBase[_studyID][patientID]
                    .consent[leastdata]
                    .elementChoices;
                exist = verifyexistenceOFcategory(elementsfromquery, elements);
                if (exist) {
                    PatientIDs[PatientIDs.length] = patientID;
                }
                exist = false;
            } else {
                leastdata = patient.leastdata;
                recordTime = patient.consent[leastdata].recordTime;
                if (recordTime <= uint256(_endTime)) {
                    categorys = dataBase[_studyID][patientID]
                        .consent[leastdata]
                        .categoryChoices;
                    bool exist = verifyexistenceOFcategory(
                        categorysfromquery,
                        categorys
                    );
                    if (exist) {
                        PatientIDs[PatientIDs.length] = patientID;
                    }
                    elements = dataBase[_studyID][patientID]
                        .consent[leastdata]
                        .elementChoices;
                    exist = verifyexistenceOFelement(
                        elementsfromquery,
                        elements
                    );
                    if (exist) {
                        PatientIDs[PatientIDs.length] = patientID;
                    }
                    exist = false;
                }
            }
        }
        return PatientIDs;
    }

    function decodePatientID(
        uint256 _studyID
    ) public view returns (uint256[] memory patientIDs) {
        bytes32[] memory patientIDsEncode = patientsOfStudy[_studyID]
            .patientIDs;
        uint256 length = patientIDsEncode.length;
        uint256 patientID;
        bool[2 ** 16 - 1] memory isPresent;
        for (uint i = 0; i < length; i++) {
            for (uint j = 0; j < 16; j++) {
                patientID = uint256(
                    (patientIDsEncode[i] >> (16 * j)) & (chunk)
                );
                if (!isPresent[patientID]) {
                    patientIDs[patientIDs.length] = patientID;
                    isPresent[patientID] = true;
                }
            }
        }
    }

    function verifyexistenceOFelement(
        bytes32[] memory categoryNeeded,
        bytes32 elementsInDatabase
    ) public pure returns (bool yes) {
        bytes32 element;
        for (uint h = 0; h < 8; h++) {
            element = getBytes32FromElements(elementsInDatabase, h * 2);
            for (uint g = 0; g < categoryNeeded.length; g++) {
                if (element == categoryNeeded[g]) {
                    return true;
                }
            }
        }
        return false;
    }

    function verifyexistenceOFcategory(
        bytes32[] memory categoryNeeded,
        bytes32 catogorysInDatabase
    ) public pure returns (bool yes) {
        bytes32 category;
        for (uint k = 0; k < 16; k++) {
            category = catogorysInDatabase[k];
            for (uint n = 0; n < categoryNeeded.length; n++) {
                if (category == categoryNeeded[n]) {
                    return true;
                }
            }
        }
        return false;
    }

    // 解析患者ID
    // function parsePatientID(bytes32 encoded) internal pure returns (uint256) {
    //   // 位运算解析
    //   patientID=uint256((encoded[i]>>16*j)&(chunk));
    // }

    //提取出输入的category choice
    function extractchoicefromInputCategory(
        string[] memory inputCategory
    ) public pure returns (bytes32[] memory) {
        bytes32[] memory requiredCategorys;
        for (uint i = 0; i < inputCategory.length; i++) {
            requiredCategorys[i] = getPrefixBytes32forCategory(
                inputCategory[i]
            );
        }
        return requiredCategorys;
    }

    //提取出输入的element choice
    function extractchoicefromInputElement(
        string[] memory inputelement,
        bytes32[] memory categorysfromquery
    ) public pure returns (bytes32[] memory, bytes32[] memory) {
        bytes32[] memory requiredElements;
        uint256 length = categorysfromquery.length;
        for (uint i = 0; i < inputelement.length; i++) {
            categorysfromquery[length + i] = getPrefixBytes32forCategory(
                inputelement[i]
            );
            requiredElements[i] = getPrefixBytes32forCategory(inputelement[i]);
        }
        return (requiredElements, categorysfromquery);
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
    function queryForPatient(
        uint256 _patientID,
        int256 _studyID,
        int256 _startTime,
        int256 _endTime
    ) public view returns (string memory) {
        /*
            Your code here.
        */
    }

    //处理categorySharingChoices这个string数组，生成编码好的bytes32并返回
    function handlecategorySharingChoices(
        string[] calldata categorySharingChoices
    ) public pure returns (bytes32) {
        bytes32 result;
        for (uint i = 0; i < categorySharingChoices.length; i++) {
            result |=
                getPrefixBytes32forCategory(categorySharingChoices[i]) >>
                (i * 8);
        }
        return result;
    }

    //处理elementSharingChoices这个string数组，生成编码好的bytes32并返回
    function handleelementSharingChoices(
        string[] calldata elementSharingChoices
    ) public pure returns (bytes32) {
        bytes32 result;
        for (uint i = 0; i < elementSharingChoices.length; i++) {
            result |=
                getPrefixBytes32forElement(elementSharingChoices[i]) >>
                (i * 16);
        }
        return result;
    }

    function getPrefixBytes32forElement(
        string memory s
    ) public pure returns (bytes32) {
        bytes memory b = bytes(s);
        bytes32 b1 = 0;
        bytes32 b2 = 0;
        // 取出第一个数字
        b1 = bytes32(b[1]);
        //取出第二个数字
        b2 = bytes32(b[4]);
        return b1 | (b2 >> 8);
    }

    //注：uint256(0x01)<<2 | uint256(0x04) = 0x104 = 260  bytes32(260）=0x0000000000000000000000000000000000000000000000000000000000000104
    function getPrefixBytes32forCategory(
        string memory s
    ) public pure returns (bytes32) {
        bytes memory b = bytes(s);
        bytes32 b1 = 0;
        // 取出第一个数字
        b1 = bytes32(b[1]);
        return b1;
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

    //从bytes中取出指定位置的bytes32

    function findCharIndex(
        bytes memory b,
        bytes1 c
    ) internal pure returns (uint) {
        for (uint i = 0; i < b.length; i++) {
            if (b[i] == c) {
                return i;
            }
        }
        return 0;
    }

    function getBytes32FromCategorys(
        bytes32 b,
        uint start
    ) internal pure returns (bytes32) {
        bytes32 result = 0;
        result = b[start];
        return result;
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
