import { LightningElement } from "lwc";
import { validateSaId } from "c/saIdUtils";
import searchIdNumber from "@salesforce/apex/IdHolidayCheckController.searchIdNumber";
import getHolidays from "@salesforce/apex/IdHolidayCheckController.getHolidays";

export default class IdHolidayCheck extends LightningElement {
  idNumber = "";
  validation = { isValid: false, error: null };
  result;
  holidays = [];
  isLoading = false;
  errorMessage;
  //

  handleChange(event) {
    const input = event.target;
    const cleaned = (input.value || "").replace(/\D/g, "");
    this.idNumber = cleaned;
    this.validation = validateSaId(cleaned);

    // Only complain once a full 13 digits are entered, so it doesn't nag while typing
    const showError = cleaned.length === 13 && !this.validation.isValid;
    input.setCustomValidity(showError ? this.validation.error : "");
    input.reportValidity();
  }

  get isSearchDisabled() {
    return !this.validation.isValid || this.isLoading;
  }

  get birthdayHolidays() {
    return this.holidays.filter((h) => h.isBirthday);
  }

  get hasBirthdayHolidays() {
    return this.birthdayHolidays.length > 0;
  }

  get hasHolidays() {
    return this.holidays.length > 0;
  }

  get birthYear() {
    return this.result?.dateOfBirth?.substring(0, 4);
  }

  get citizenshipLabel() {
    return this.result?.saCitizen ? "SA Citizen" : "Permanent Resident";
  }

  async handleSearch() {
    this.isLoading = true;
    this.errorMessage = undefined;
    this.result = undefined;
    this.holidays = [];

    try {
      // Save/update first, then call the API (callouts can't follow DML in one transaction)
      this.result = await searchIdNumber({ idNumber: this.idNumber });

      const year = Number(this.result.dateOfBirth.substring(0, 4));
      const birthMonthDay = this.result.dateOfBirth.substring(5);
      const list = await getHolidays({ year });

      this.holidays = list.map((h, index) => {
        const isBirthday = h.dateIso.substring(5) === birthMonthDay;
        return {
          ...h,
          key: `${h.dateIso}-${index}`,
          isBirthday,
          rowClass: isBirthday ? "holiday holiday-birthday" : "holiday"
        };
      });
    } catch (error) {
      const body = error?.body;
      this.errorMessage =
        body?.message ||
        body?.pageErrors?.[0]?.message ||
        Object.values(body?.fieldErrors || {})[0]?.[0]?.message ||
        "Something went wrong. Please try again.";
    } finally {
      this.isLoading = false;
    }
  }
}
