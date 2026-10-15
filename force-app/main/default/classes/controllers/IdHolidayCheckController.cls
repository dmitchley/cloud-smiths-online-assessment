public without sharing class IdHolidayCheckController {
  // Saves the ID number and counts how many times each ID number is searched.

  public class SearchResult {
    @AuraEnabled
    public String idNumber;
    @AuraEnabled
    public Date dateOfBirth;
    @AuraEnabled
    public String gender;
    @AuraEnabled
    public Boolean saCitizen;
    @AuraEnabled
    public Integer searchCount;
  }

  @AuraEnabled
  public static SearchResult searchIdNumber(String idNumber) {
    String cleaned = SaIdDecoder.clean(idNumber);
    if (!SaIdDecoder.isValid(cleaned)) {
      throw new AuraHandledException(
        'Please enter a valid South African ID number.'
      );
    }

    List<SA_ID_Record__c> existing = [
      SELECT
        Id,
        Name,
        ID_Number__c,
        Date_of_Birth__c,
        Gender__c,
        SA_Citizen__c,
        Search_Count__c
      FROM SA_ID_Record__c
      WHERE ID_Number__c = :cleaned
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];

    SA_ID_Record__c rec;
    if (existing.isEmpty()) {
      rec = new SA_ID_Record__c(
        Name = cleaned,
        ID_Number__c = cleaned,
        Date_of_Birth__c = SaIdDecoder.parseDob(cleaned),
        Gender__c = SaIdDecoder.gender(cleaned),
        SA_Citizen__c = SaIdDecoder.isCitizen(cleaned),
        Search_Count__c = 1
      );
      insert as system rec;
    } else {
      rec = existing[0];
      rec.Search_Count__c =
        (rec.Search_Count__c == null ? 0 : rec.Search_Count__c) + 1;
      update as system rec;
    }

    SearchResult result = new SearchResult();
    result.idNumber = rec.ID_Number__c;
    result.dateOfBirth = rec.Date_of_Birth__c;
    result.gender = rec.Gender__c;
    result.saCitizen = rec.SA_Citizen__c;
    result.searchCount = rec.Search_Count__c == null
      ? 0
      : rec.Search_Count__c.intValue();
    return result;
  }

  @AuraEnabled(cacheable=true)
  public static List<CalendarificService.Holiday> getHolidays(Integer year) {
    if (year == null || year < 1900 || year > Date.today().year()) {
      throw new AuraHandledException('Invalid year.');
    }
    try {
      return CalendarificService.getHolidays(year);
    } catch (CalendarificService.CalendarificException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
