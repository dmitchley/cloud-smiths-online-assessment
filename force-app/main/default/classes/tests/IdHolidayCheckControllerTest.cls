@IsTest
private class IdHolidayCheckControllerTest {
  private static final String VALID_ID = '8001015009087';

  private class CalendarificMock implements HttpCalloutMock {
    private Integer status;
    private String body;

    CalendarificMock(Integer status, String body) {
      this.status = status;
      this.body = body;
    }

    public HttpResponse respond(HttpRequest req) {
      Assert.isTrue(req.getEndpoint().contains('country=ZA'));
      Assert.isTrue(req.getEndpoint().contains('year=1980'));
      HttpResponse res = new HttpResponse();
      res.setStatusCode(status);
      res.setBody(body);
      return res;
    }
  }

  private static void useTestSettings() {
    CalendarificService.settings = new Calendarific_Setting__mdt(
      API_Key__c = 'test-key',
      Endpoint__c = 'https://calendarific.com/api/v2/holidays'
    );
  }

  @IsTest
  static void searchCreatesThenIncrementsRecord() {
    System.Test.startTest();
    IdHolidayCheckController.SearchResult first = IdHolidayCheckController.searchIdNumber(
      VALID_ID
    );
    IdHolidayCheckController.SearchResult second = IdHolidayCheckController.searchIdNumber(
      VALID_ID
    );
    System.Test.stopTest();

    Assert.areEqual(1, first.searchCount);
    Assert.areEqual(2, second.searchCount);
    Assert.areEqual(Date.newInstance(1980, 1, 1), second.dateOfBirth);
    Assert.areEqual('Male', second.gender);
    Assert.isTrue(second.saCitizen);

    List<SA_ID_Record__c> records = [
      SELECT Search_Count__c
      FROM SA_ID_Record__c
      WHERE ID_Number__c = :VALID_ID
    ];
    Assert.areEqual(1, records.size(), 'ID number should stay unique');
    Assert.areEqual(2, records[0].Search_Count__c);
  }

  @IsTest
  static void searchRejectsInvalidId() {
    try {
      IdHolidayCheckController.searchIdNumber('1234567890123');
      Assert.fail('Expected an AuraHandledException');
    } catch (AuraHandledException e) {
      Assert.areEqual(0, [SELECT COUNT() FROM SA_ID_Record__c]);
    }
  }

  @IsTest
  static void getHolidaysParsesResponse() {
    useTestSettings();
    System.Test.setMock(
      HttpCalloutMock.class,
      new CalendarificMock(
        200,
        '{"response":{"holidays":[{"name":"New Year\'s Day",' +
          '"description":"First day of the year","date":{"iso":"1980-01-01"},' +
          '"type":["National holiday"]}]}}'
      )
    );

    System.Test.startTest();
    List<CalendarificService.Holiday> holidays = IdHolidayCheckController.getHolidays(
      1980
    );
    System.Test.stopTest();

    Assert.areEqual(1, holidays.size());
    Assert.areEqual('New Year\'s Day', holidays[0].name);
    Assert.areEqual('1980-01-01', holidays[0].dateIso);
    Assert.areEqual('National holiday', holidays[0].type);
  }

  @IsTest
  static void getHolidaysHandlesEmptyResponse() {
    useTestSettings();
    System.Test.setMock(
      HttpCalloutMock.class,
      new CalendarificMock(200, '{"response":[]}')
    );

    System.Test.startTest();
    List<CalendarificService.Holiday> holidays = IdHolidayCheckController.getHolidays(
      1980
    );
    System.Test.stopTest();

    Assert.isTrue(holidays.isEmpty());
  }

  @IsTest
  static void getHolidaysWrapsApiErrors() {
    useTestSettings();
    System.Test.setMock(HttpCalloutMock.class, new CalendarificMock(500, ''));

    try {
      IdHolidayCheckController.getHolidays(1980);
      Assert.fail('Expected an AuraHandledException');
    } catch (AuraHandledException e) {
      // Expected: service errors are surfaced to the LWC as AuraHandledException
    }
  }

  @IsTest
  static void getHolidaysRejectsInvalidYear() {
    try {
      IdHolidayCheckController.getHolidays(1800);
      Assert.fail('Expected an AuraHandledException');
    } catch (AuraHandledException e) {
      // Expected
    }
  }
}
