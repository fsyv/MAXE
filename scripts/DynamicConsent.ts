

type Consent = {
  recordTime: number;
  patientCategoryChoices: string[];
  patientElementChoices: string[];
  choices: number[];
};

// studyID : patientID  : Consent[]
const dataBase: Record<number, Record<number, Consent[]>> = {};
dataBase[-1] = {};

function preprocessing(
  _patientCategoryChoices: string[],
  _patientElementChoices: string[]
): number[] {

  let choices: number[] = [];

  for (let patientCategoryChoices of _patientCategoryChoices) {
    const numbers = patientCategoryChoices.split("_");
    if (numbers.length >= 2) {
      choices.push(Number(numbers[0]));
    }
  }

  for (let patientElementChoices of _patientElementChoices) {
    const numbers = patientElementChoices.split("_");
    if (numbers.length >= 3) {
      choices.push(Number(numbers[0]) * 100 + Number(numbers[1]));
    }
  }

  choices.sort();

  return choices;
}

export function storeRecord(
  _patientID: number,
  _studyID: number,
  _recordTime: number,
  _patientCategoryChoices: string[],
  _patientElementChoices: string[]
): void {
  const consent: Consent = {
    recordTime: _recordTime,
    patientCategoryChoices: _patientCategoryChoices,
    patientElementChoices: _patientElementChoices,
    choices: preprocessing(_patientCategoryChoices, _patientElementChoices)
  }

  if (!dataBase[_studyID]) {
    dataBase[_studyID] = {};
  }

  if (!dataBase[_studyID][_patientID]) {
    dataBase[_studyID][_patientID] = [];
  }

  dataBase[_studyID][_patientID].push(consent)
}

export function queryForResearcher(
  _studyID: number,
  _endTime: number,
  _requestedCategoryChoices: string[],
  _requestedElementChoices: string[]
): string[] {

  let patientIDs: string[] = [];
  const study = dataBase[_studyID];

  let requestedChoices: number[] = [];

  for (let requestedCategoryChoices of _requestedCategoryChoices) {
    const numbers = requestedCategoryChoices.split("_");
    if (numbers.length >= 2) {
      requestedChoices.push(Number(numbers[0]));
    }
  }

  for (let requestedElementChoices of _requestedElementChoices) {
    const numbers = requestedElementChoices.split("_");
    if (numbers.length >= 3) {
      requestedChoices.push(Number(numbers[0]) * 100 + Number(numbers[1]));
    }
  }

  for (const patientID in study) {

    if (study.hasOwnProperty(patientID)) {

      const consents = study[patientID];

      consents.sort((a: Consent, b: Consent) => b.recordTime - a.recordTime);

      for (let consent of consents) {
        if (_endTime != -1 && consent.recordTime > _endTime) {
          break;
        }

        //这后面的代码只用执行一次
        let contains = true;
        for (let requestedChoice of requestedChoices) {
          if (!consent.choices.includes(requestedChoice) && !consent.choices.includes(Math.floor(requestedChoice / 100))) {
            // 不包含
            contains = false;
            break;
          }
        }

        if (contains) {
          patientIDs.push(patientID);
        }
        break;
      }
    }
  }

  return [...new Set(patientIDs)];
}

export function queryForPatient(
  _patientID: number,
  _studyID: number,
  _startTimestamp: number,
  _endTimestamp: number
): string {


  if (_endTimestamp == -1) {
    _endTimestamp = Number.MAX_SAFE_INTEGER
  }

  let result: string = "";

  if (_studyID == -1) {

    for (const studyID in dataBase) {

      if (dataBase.hasOwnProperty(studyID) && dataBase[studyID][_patientID]) {

        const consents = dataBase[studyID][_patientID];
        consents.sort((a: Consent, b: Consent) => a.recordTime - b.recordTime);
        for (let consent of consents) {

          if (consent.recordTime >= _startTimestamp && consent.recordTime <= _endTimestamp) {
            result += `${studyID},${consent.recordTime},[${consent.patientCategoryChoices.join(",")}],[${consent.patientElementChoices.join(",")}]\n`;
          }
        }
      }
    }
  }

  if (!dataBase[_studyID] || !dataBase[_studyID][_patientID]) {
    return result;
  }

  const consents = dataBase[_studyID][_patientID];
  consents.sort((a: Consent, b: Consent) => a.recordTime - b.recordTime);
  for (let consent of consents) {

    if (consent.recordTime >= _startTimestamp && consent.recordTime <= _endTimestamp) {
      result += `${_studyID},${consent.recordTime},[${consent.patientCategoryChoices.join(",")}],[${consent.patientElementChoices.join(",")}]\n`;
    }
  }

  return result
}