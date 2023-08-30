

type Consent = {
  recordTime: number;
  patientCategoryChoices: string[];
  patientElementChoices: string[];
};

// studyID : patientID  : Consent[]
const dataBase: Record<number, Record<number, Consent[]>> = {};

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
  }

  if(!dataBase[_studyID])
  {
    dataBase[_studyID] = {};
  }

  if(!dataBase[_studyID][_patientID])
  {
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

  for (const patientID in study) {

    if (study.hasOwnProperty(patientID)) {

      const consents = study[patientID];
      for (let consent of consents) {
        if(_endTime != -1 && consent.recordTime > _endTime)
        {
          break;
        }

        let categoryChoicesCount = 0;
        for(let categoryChoices of consent.patientCategoryChoices)
        {
          if(!_requestedCategoryChoices.includes(categoryChoices))
          {
            break;
          }

          categoryChoicesCount++;
        }

        if(categoryChoicesCount != _requestedCategoryChoices.length)
        {
          break;
        }

        let elementSharingChoicesCount = 0;
        for(let elementChoices of consent.patientElementChoices)
        {
          if(!_requestedElementChoices.includes(elementChoices))
          {
            break;
          }

          elementSharingChoicesCount++;
        }
        if(elementSharingChoicesCount != _requestedElementChoices.length)
        {
          break;
        }

        patientIDs.push(patientID)
      }
    }
  }

  return [...new Set(patientIDs)];
}
