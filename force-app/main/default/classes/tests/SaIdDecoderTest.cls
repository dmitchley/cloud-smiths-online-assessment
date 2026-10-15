@IsTest
private class SaIdDecoderTest {
  @IsTest
  static void decodesValidId() {
    String id = '8001015009087';

    Assert.isTrue(SaIdDecoder.isValid(id));
    Assert.areEqual(Date.newInstance(1980, 1, 1), SaIdDecoder.parseDob(id));
    Assert.areEqual('Male', SaIdDecoder.gender(id));
    Assert.isTrue(SaIdDecoder.isCitizen(id));
    Assert.areEqual('Female', SaIdDecoder.gender('9002150001086'));
  }

  @IsTest
  static void rejectsInvalidIds() {
    Assert.isFalse(SaIdDecoder.isValid(null), 'null');
    Assert.isFalse(SaIdDecoder.isValid('800101500908'), 'too short');
    Assert.isFalse(SaIdDecoder.isValid('8001015009088'), 'bad checksum');
    Assert.isFalse(SaIdDecoder.isValid('8002305009087'), '30 February');
    Assert.isFalse(SaIdDecoder.isValid('80010150090ab'), 'non-numeric');
  }

  @IsTest
  static void cleanStripsNonDigits() {
    Assert.areEqual('8001015009087', SaIdDecoder.clean(' 800101 5009 087 '));
    Assert.areEqual('', SaIdDecoder.clean(null));
  }

  @IsTest
  static void handlesCenturyAndCitizenship() {
    Assert.areEqual(
      Date.newInstance(2005, 1, 1),
      SaIdDecoder.parseDob('0501010000000')
    );
    // Later this year in the 2000s would be the future, so it must be the 1900s
    Date nextMonth = Date.today().addMonths(1);
    String yymmdd =
      String.valueOf(nextMonth.year()).right(2) +
      String.valueOf(nextMonth.month()).leftPad(2, '0') +
      '01';
    Assert.areEqual(
      1900 + Math.mod(nextMonth.year(), 100),
      SaIdDecoder.parseDob(yymmdd + '0000000').year()
    );
    Assert.isFalse(SaIdDecoder.isValid('8001015009280'), 'citizenship digit 2');
  }
}
