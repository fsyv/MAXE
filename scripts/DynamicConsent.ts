

// // 数据库
// const dataBase: Record<string, any> = {};

// // 存储函数
// function storeRecord(key: string, value: any): void {
//   // 将数据存储到数据库中
//   dataBase[key] = value;
//   console.log(`成功将数据存储到数据库：Key: ${key}, Value: ${value}`);
// }

// // 查询函数
// function queryForResearcher(key: string): any {
//   // 从数据库中查询数据
//   const data = dataBase[key];
//   if (data) {
//     console.log(`查询到了与 ${key} 相关的数据：${data}`);
//     return data;
//   } else {
//     console.log(`未找到与 ${key} 相关的数据`);
//     return null;
//   }
// }

// // 查询函数
// function queryForPatient(key: string): any {
//     // 从数据库中查询数据
//     const data = dataBase[key];
//     if (data) {
//       console.log(`查询到了与 ${key} 相关的数据：${data}`);
//       return data;
//     } else {
//       console.log(`未找到与 ${key} 相关的数据`);
//       return null;
//     }
//   }


  type Consent = {
    recordTime: number;
    patientCategoryChoices: string[];
    patientElementChoices: string[];
  };
  
  const dataBase: Record<number, Record<number, Consent[]>> = {};
  
  function storeRecord(
    _patientID: number,
    _studyID: number,
    _recordTime: number,
    _patientCategoryChoices: string[],
    _patientElementChoices: string[]
  ): void {
    // const record: Record = {
    //   patientID: _patientID,
    //   studyID: _studyID,
    //   recordTime: _recordTime,
    //   patientCategoryChoices: _patientCategoryChoices,
    //   patientElementChoices: _patientElementChoices,
    // };

    const consent: Consent = {
        recordTime: _recordTime,
        patientCategoryChoices: _patientCategoryChoices,
        patientElementChoices: _patientElementChoices,
    }
  
    dataBase[_patientID][_studyID].push(consent)
  }
  
//   function queryForResearcher(
//     _studyID: number,
//     _endTime: number,
//     _requestedCategoryChoices: string[],
//     _requestedElementChoices: string[]
//   ): Record[] {
//     const filteredRecords = dataBase.filter((record) => {
//       return (
//         record.studyID === _studyID &&
//         record.recordTime <= _endTime &&
//         arraysContain(record.patientCategoryChoices, _requestedCategoryChoices) &&
//         arraysContain(record.patientElementChoices, _requestedElementChoices)
//       );
//     });
  
//     return filteredRecords;
//   }
  
//   function arraysContain(arr1: string[], arr2: string[]): boolean {
//     return arr2.every((item) => arr1.includes(item));
//   }