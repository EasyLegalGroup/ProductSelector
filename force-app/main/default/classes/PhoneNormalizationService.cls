/**
 * Centralized service for normalizing phone numbers to E.164 format.
 * Handles Lead, Contact, and Account phone normalization.
 * 
 * STRICT NORMALIZATION RULES:
 * - Denmark: +45
 * - Sweden: +46
 * - Ireland: +353
 * - Strip all non-standard characters (parentheses, spaces, hyphens, etc.)
 * - Remove leading zeros after country code
 * - Format: +[CountryCode][Number] (no spaces or separators)
 * 
 * @throws PhoneNormalizationException when normalization fails
 */
public class PhoneNormalizationService {
    
    // Country codes
    private static final String DENMARK_CODE = '45';
    private static final String SWEDEN_CODE = '46';
    private static final String IRELAND_CODE = '353';
    
    // Market Unit values
    private static final String MARKET_DK = 'DFJ_DK';
    private static final String MARKET_SE = 'FA_SE';
    private static final String MARKET_IE = 'Ireland';
    
    /**
     * Custom exception for phone normalization errors
     */
    public class PhoneNormalizationException extends Exception {}
    
    /**
     * Main public method to normalize a phone number
     * @param phoneNumber - Raw phone number input
     * @param marketUnit - Market_Unit__c value for country fallback
     * @return Normalized phone in E.164 format (+CountryCodeNumber)
     * @throws PhoneNormalizationException if normalization fails
     */
    public static String normalize(String phoneNumber, String marketUnit) {
        if (String.isBlank(phoneNumber)) {
            return phoneNumber;
        }
        
        try {
            String sanitized = stripNonStandardCharacters(phoneNumber);
            if (String.isBlank(sanitized) || sanitized == '+') {
                throw new PhoneNormalizationException('Phone number contains no digits: ' + phoneNumber);
            }
            
            Boolean hasPlus = sanitized.startsWith('+');
            String digits = hasPlus ? sanitized.substring(1) : sanitized;
            
            while (!hasPlus && digits.startsWith('00')) {
                digits = digits.substring(2);
                hasPlus = true;
            }
            
            if (String.isBlank(digits)) {
                throw new PhoneNormalizationException('Phone number contains no digits: ' + phoneNumber);
            }
            
            if (hasPlus) {
                String normalizedInternational = normalizeWithCountryCode(digits);
                if (normalizedInternational != null) {
                    if (!isValidE164Format(normalizedInternational)) {
                        throw new PhoneNormalizationException(
                            'Failed to normalize phone number to valid E.164 format: ' + phoneNumber
                        );
                    }
                    return normalizedInternational;
                }
                hasPlus = false;
            }
            
            String normalizedLocal = normalizeLocalNumber(digits, marketUnit);
            if (!isValidE164Format(normalizedLocal)) {
                throw new PhoneNormalizationException(
                    'Failed to normalize phone number to valid E.164 format: ' + phoneNumber
                );
            }
            return normalizedLocal;
            
        } catch (Exception e) {
            throw new PhoneNormalizationException(
                'Phone normalization failed for: ' + phoneNumber + '. Error: ' + e.getMessage()
            );
        }
    }
    
    /**
     * Strip all non-standard characters, keeping only digits and leading +
     */
    private static String stripNonStandardCharacters(String raw) {
        if (raw == null) {
            return '';
        }
        String trimmed = raw.trim();
        String cleaned = '';
        for (Integer i = 0; i < trimmed.length(); i++) {
            String ch = trimmed.substring(i, i + 1);
            if (ch >= '0' && ch <= '9') {
                cleaned += ch;
            } else if (ch == '+' && String.isEmpty(cleaned)) {
                cleaned = '+';
            }
        }
        return cleaned;
    }
    
    /**
     * Process numbers that include a country code
     */
    private static String normalizeWithCountryCode(String digits) {
        String countryCode = getCountryCode(digits);
        if (countryCode == null) {
            return null;
        }
        String nationalDigits = digits.substring(countryCode.length());
        nationalDigits = removeLeadingZeros(nationalDigits);
        if (String.isBlank(nationalDigits)) {
            throw new PhoneNormalizationException('Missing national phone number digits');
        }
        return '+' + countryCode + nationalDigits;
    }
    
    /**
     * Process numbers without a country code (local numbers)
     */
    private static String normalizeLocalNumber(String digits, String marketUnit) {
        String trimmedDigits = digits;
        if (String.isBlank(trimmedDigits)) {
            throw new PhoneNormalizationException('Phone number contains no digits');
        }
        
        String detected = detectCountryCodeFromPattern(trimmedDigits);
        if (detected != null) {
            return detected;
        }
        
        String inferredMarket = inferMarketFromDigits(trimmedDigits);
        if (inferredMarket != null) {
            return buildLocalNumber(trimmedDigits, inferredMarket);
        }
        
        if (String.isBlank(marketUnit)) {
            throw new PhoneNormalizationException(
                'Cannot normalize local number without Market_Unit__c: ' + trimmedDigits
            );
        }
        
        return buildLocalNumber(trimmedDigits, marketUnit);
    }
    
    private static String detectCountryCodeFromPattern(String digits) {
        if (digits.startsWith(DENMARK_CODE) && digits.length() == 10) {
            return '+' + digits;
        }
        if (digits.startsWith(SWEDEN_CODE) && digits.length() == 11) {
            return '+' + digits;
        }
        if (digits.startsWith(IRELAND_CODE) && (digits.length() == 12 || digits.length() == 13)) {
            return '+' + digits;
        }
        return null;
    }
    
    private static String getCountryCode(String digits) {
        if (digits.startsWith(DENMARK_CODE)) {
            return DENMARK_CODE;
        }
        if (digits.startsWith(SWEDEN_CODE)) {
            return SWEDEN_CODE;
        }
        if (digits.startsWith(IRELAND_CODE)) {
            return IRELAND_CODE;
        }
        return null;
    }
    
    private static String removeLeadingZeros(String digits) {
        String result = digits;
        while (result.startsWith('0') && result.length() > 1) {
            result = result.substring(1);
        }
        return result;
    }
    
    private static String inferMarketFromDigits(String digits) {
        if (digits.length() == 8) {
            return MARKET_DK;
        }
        if (digits.startsWith('0') && digits.length() >= 9) {
            String afterZero = digits.substring(1);
            if (afterZero.startsWith('7')) {
                return MARKET_SE;
            }
            if (afterZero.startsWith('8')) {
                return MARKET_IE;
            }
        }
        return null;
    }
    
    private static String buildLocalNumber(String digits, String marketUnit) {
        if (marketUnit == MARKET_DK) {
            String normalizedDigits = digits;
            if (normalizedDigits.length() == 9 && normalizedDigits.startsWith('0')) {
                normalizedDigits = normalizedDigits.substring(1);
            }
            if (normalizedDigits.length() == 8) {
                return '+' + DENMARK_CODE + normalizedDigits;
            }
        } else if (marketUnit == MARKET_SE) {
            String normalizedDigits = removeSingleTrunkZero(digits);
            if (normalizedDigits.length() >= 7 && normalizedDigits.length() <= 10) {
                return '+' + SWEDEN_CODE + normalizedDigits;
            }
        } else if (marketUnit == MARKET_IE) {
            String normalizedDigits = removeSingleTrunkZero(digits);
            if (normalizedDigits.length() >= 9 && normalizedDigits.length() <= 10) {
                return '+' + IRELAND_CODE + normalizedDigits;
            }
        }
        throw new PhoneNormalizationException(
            'Cannot determine country code for number: ' + digits + ' with Market_Unit: ' + marketUnit
        );
    }
    
    private static String removeSingleTrunkZero(String digits) {
        if (digits.startsWith('0') && digits.length() > 1) {
            return digits.substring(1);
        }
        return digits;
    }
    
    /**
     * Validate that the phone number is in proper E.164 format
     * Format: +[CountryCode][Number] where everything after + is digits only
     */
    private static Boolean isValidE164Format(String phoneNumber) {
        if (String.isBlank(phoneNumber) || !phoneNumber.startsWith('+')) {
            return false;
        }
        
        // Check that everything after + is digits
        String digits = phoneNumber.substring(1);
        if (digits.length() < 8) {
            return false; // Too short to be a valid phone number
        }
        
        for (Integer i = 0; i < digits.length(); i++) {
            String ch = digits.substring(i, i + 1);
            if (ch < '0' || ch > '9') {
                return false;
            }
        }
        
        return true;
    }
}