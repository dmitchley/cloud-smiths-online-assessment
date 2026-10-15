const CITIZENSHIP = { '0': 'SA Citizen', '1': 'Permanent Resident' };

// https://www.westerncape.gov.za/general-publication/decoding-your-south-african-id-number-0
// the above link doesnt work so i had to use this guide instead https://www.ourpower.co.za/tools/sa-id-decoder

function parseDateOfBirth(id) {
    const yy = Number(id.slice(0, 2));
    const mm = Number(id.slice(2, 4));
    const dd = Number(id.slice(4, 6));

    let year = 2000 + yy;
    let dob = new Date(year, mm - 1, dd);
    if (dob > new Date()) {
        // A birth date can't be in the future, so it must be the 1900s
        year -= 100;
        dob = new Date(year, mm - 1, dd);
    }

    // Reject rolled-over dates like 31 Feb
    if (dob.getFullYear() !== year || dob.getMonth() !== mm - 1 || dob.getDate() !== dd) {
        return null;
    }
    const pad = (n) => String(n).padStart(2, '0');
    return `${year}-${pad(mm)}-${pad(dd)}`;
}

export function passesLuhn(id) {
    let sum = 0;
    for (let i = 0; i < id.length; i++) {
        let digit = Number(id[id.length - 1 - i]);
        if (i % 2 === 1) {
            digit *= 2;
            if (digit > 9) digit -= 9;
        }
        sum += digit;
    }
    return sum % 10 === 0;
}

export function validateSaId(id) {
    if (!/^\d{13}$/.test(id)) {
        return { isValid: false, error: 'ID number must be exactly 13 digits.' };
    }
    const dateOfBirth = parseDateOfBirth(id);
    if (!dateOfBirth) {
        return { isValid: false, error: 'The first 6 digits are not a valid date of birth (YYMMDD).' };
    }
    if (!(id[10] in CITIZENSHIP)) {
        return { isValid: false, error: 'Citizenship digit (11th) must be 0 or 1.' };
    }
    if (!passesLuhn(id)) {
        return { isValid: false, error: 'This is not a valid South African ID number (checksum failed).' };
    }
    return {
        isValid: true,
        error: null,
        decoded: {
            idNumber: id,
            dateOfBirth,
            gender: Number(id.slice(6, 10)) < 5000 ? 'Female' : 'Male',
            citizenship: CITIZENSHIP[id[10]]
        }
    };
}