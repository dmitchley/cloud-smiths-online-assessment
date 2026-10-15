# SA ID Holiday Checker

A Salesforce Experience Cloud page where a visitor enters a South African ID number, sees the details decoded from it, and gets the South African public holidays for the year they were born, with any holiday that falls on their birthday highlighted.

**Live demo:** https://orgfarm-dbf77137ab-dev-ed.develop.my.site.com/

## How the requirements are met

| User story                                                                   | Where it's handled                                             |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------- |
| **1.** Page with an info section, ID input and Search button                 | `lwc/idHolidayCheck`                                           |
| **2.** Search disabled until the ID is valid, with a message for invalid IDs | `lwc/saIdUtils` (client-side) and `SaIdDecoder` (server-side)  |
| **3.** Store decoded info and count searches per ID                          | `IdHolidayCheckController.searchIdNumber` → `SA_ID_Record__c`  |
| **4.** Call Calendarific after saving, and show the holidays                 | `IdHolidayCheckController.getHolidays` → `CalendarificService` |

## Notes

- The ID decoding guide linked in the brief ([westerncape.gov.za](https://www.westerncape.gov.za/general-publication/decoding-your-south-african-id-number-0)) is no longer available, so I based the validation on [this SA ID decoder guide](https://www.ourpower.co.za/tools/sa-id-decoder) instead.

## Design decisions

- **Save first, then fetch holidays:** Apex can't make a callout after DML in the same
  transaction, so the page makes two separate calls.
- **Validated in the browser and in Apex:** instant feedback for the user, plus a server-side
  check the client can't bypass.
- **ID number as a unique key:** `FOR UPDATE` stops two searches at the same moment from
  losing an increment.
- **API key in custom metadata:** not hard-coded and not committed to git.
