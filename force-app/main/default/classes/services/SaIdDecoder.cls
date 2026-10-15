public with sharing class SaIdDecoder {
  // Validates and decodes South African ID numbers (YYMMDD SSSS C A Z).

  public static String clean(String idNumber) {
    return idNumber == null ? '' : idNumber.replaceAll('[^0-9]', '');
  }

  public static Boolean isValid(String id) {
    if (id == null || !Pattern.matches('\\d{13}', id)) {
      return false;
    }
    if (parseDob(id) == null) {
      return false;
    }
    String citizenship = id.substring(10, 11);
    if (citizenship != '0' && citizenship != '1') {
      return false;
    }
    Integer sum = 0;
    for (Integer i = 0; i < 13; i++) {
      Integer d = Integer.valueOf(id.substring(i, i + 1));
      if (Math.mod(i, 2) == 1) {
        d *= 2;
        if (d > 9) {
          d -= 9;
        }
      }
      sum += d;
    }
    return Math.mod(sum, 10) == 0;
  }

  public static Date parseDob(String id) {
    Integer yy = Integer.valueOf(id.substring(0, 2));
    Integer mm = Integer.valueOf(id.substring(2, 4));
    Integer dd = Integer.valueOf(id.substring(4, 6));
    if (mm < 1 || mm > 12 || dd < 1) {
      return null;
    }
    // Assume 2000s unless that puts the birth date in the future
    Integer year = 2000 + yy;
    if (
      dd <= Date.daysInMonth(year, mm) &&
      Date.newInstance(year, mm, dd) > Date.today()
    ) {
      year -= 100;
    }
    if (dd > Date.daysInMonth(year, mm)) {
      return null;
    }
    return Date.newInstance(year, mm, dd);
  }

  public static String gender(String id) {
    return Integer.valueOf(id.substring(6, 10)) < 5000 ? 'Female' : 'Male';
  }

  public static Boolean isCitizen(String id) {
    return id.substring(10, 11) == '0';
  }
}
