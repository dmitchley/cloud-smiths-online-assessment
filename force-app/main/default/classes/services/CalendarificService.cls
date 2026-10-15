public with sharing class CalendarificService {
  // Fetches South African national public holidays from the Calendarific API.

  public class Holiday {
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String dateIso;
    @AuraEnabled
    public String type;
  }

  public class CalendarificException extends Exception {
  }

  // Lets tests supply settings without depending on the org's metadata record
  @TestVisible
  private static Calendarific_Setting__mdt settings;

  public static List<Holiday> getHolidays(Integer year) {
    Calendarific_Setting__mdt config = settings != null
      ? settings
      : Calendarific_Setting__mdt.getInstance('Default');
    if (config == null || String.isBlank(config.API_Key__c)) {
      throw new CalendarificException('Holiday service is not configured.');
    }

    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      config.Endpoint__c +
        '?api_key=' +
        EncodingUtil.urlEncode(config.API_Key__c, 'UTF-8') +
        '&country=ZA&type=national&year=' +
        year
    );
    req.setMethod('GET');
    req.setTimeout(10000);

    HttpResponse res;
    try {
      res = new Http().send(req);
    } catch (CalloutException e) {
      throw new CalendarificException('Could not reach the holiday service.');
    }
    if (res.getStatusCode() != 200) {
      throw new CalendarificException(
        'Could not load public holidays right now.'
      );
    }
    return parseHolidays(res.getBody());
  }

  @TestVisible
  private static List<Holiday> parseHolidays(String json) {
    List<Holiday> holidays = new List<Holiday>();
    Map<String, Object> body = (Map<String, Object>) System.JSON.deserializeUntyped(
      json
    );
    // Calendarific returns "response": [] instead of an object when there's no data
    if (!(body.get('response') instanceof Map<String, Object>)) {
      return holidays;
    }
    Map<String, Object> response = (Map<String, Object>) body.get('response');
    List<Object> raw = (List<Object>) response.get('holidays');
    if (raw == null) {
      return holidays;
    }

    for (Object item : raw) {
      Map<String, Object> h = (Map<String, Object>) item;
      Map<String, Object> dateInfo = (Map<String, Object>) h.get('date');
      List<Object> types = (List<Object>) h.get('type');

      Holiday hol = new Holiday();
      hol.name = (String) h.get('name');
      hol.description = (String) h.get('description');
      hol.dateIso = ((String) dateInfo.get('iso')).left(10);
      hol.type = types == null || types.isEmpty()
        ? ''
        : String.join(types, ', ');
      holidays.add(hol);
    }
    return holidays;
  }
}
