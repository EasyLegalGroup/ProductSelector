/**
 * Test class for PhoneNormalizationService
 * Covers all normalization scenarios for Denmark, Sweden, and Ireland
 */
@isTest
private class PhoneNormalizationServiceTest {
    
    /**
     * Test Danish phone normalization
     */
    @isTest
    static void testDanishPhoneNormalization() {
        // Test 1: Local format with spaces
        String result = PhoneNormalizationService.normalize('42 45 51 50', 'DFJ_DK');
        System.assertEquals('+4542455150', result, 'Should normalize Danish local number with spaces');
        
        // Test 2: International format with leading zero
        result = PhoneNormalizationService.normalize('+45 042 45 51 50', 'DFJ_DK');
        System.assertEquals('+4542455150', result, 'Should remove leading zero after +45');
        
        // Test 3: 00 prefix
        result = PhoneNormalizationService.normalize('0045 42 45 51 50', 'DFJ_DK');
        System.assertEquals('+4542455150', result, 'Should convert 00 prefix to +');
        
        // Test 4: With parentheses and hyphens
        result = PhoneNormalizationService.normalize('(+45) 42-45-51-50', 'DFJ_DK');
        System.assertEquals('+4542455150', result, 'Should strip parentheses and hyphens');
        
        // Test 5: With leading 0 in international format
        result = PhoneNormalizationService.normalize('+450123123123', 'DFJ_DK');
        System.assertEquals('+45123123123', result, 'Should remove 0 after country code');
        
        // Test 6: Already normalized
        result = PhoneNormalizationService.normalize('+4542455150', 'DFJ_DK');
        System.assertEquals('+4542455150', result, 'Should handle already normalized number');
    }
    
    /**
     * Test Swedish phone normalization
     */
    @isTest
    static void testSwedishPhoneNormalization() {
        // Test 1: Local format with leading zero
        String result = PhoneNormalizationService.normalize('070-123 45 67', 'FA_SE');
        System.assertEquals('+46701234567', result, 'Should normalize Swedish local number');
        
        // Test 2: International format with leading zero
        result = PhoneNormalizationService.normalize('+46 070 123 45 67', 'FA_SE');
        System.assertEquals('+46701234567', result, 'Should remove leading zero after +46');
        
        // Test 3: 00 prefix
        result = PhoneNormalizationService.normalize('0046701234567', 'FA_SE');
        System.assertEquals('+46701234567', result, 'Should convert 00 prefix to +');
        
        // Test 4: With parentheses
        result = PhoneNormalizationService.normalize('(+46) 70-123-45-67', 'FA_SE');
        System.assertEquals('+46701234567', result, 'Should strip parentheses and hyphens');
        
        // Test 5: With leading 0 in international format
        result = PhoneNormalizationService.normalize('+460701234567', 'FA_SE');
        System.assertEquals('+46701234567', result, 'Should remove 0 after country code');
        
        // Test 6: Already normalized
        result = PhoneNormalizationService.normalize('+46701234567', 'FA_SE');
        System.assertEquals('+46701234567', result, 'Should handle already normalized number');
    }
    
    /**
     * Test Irish phone normalization
     */
    @isTest
    static void testIrishPhoneNormalization() {
        // Test 1: Local format with leading zero
        String result = PhoneNormalizationService.normalize('087 123 4567', 'Ireland');
        System.assertEquals('+353871234567', result, 'Should normalize Irish local number');
        
        // Test 2: International format with leading zero
        result = PhoneNormalizationService.normalize('+353 087 123 4567', 'Ireland');
        System.assertEquals('+353871234567', result, 'Should remove leading zero after +353');
        
        // Test 3: 00 prefix
        result = PhoneNormalizationService.normalize('00353 87 123 4567', 'Ireland');
        System.assertEquals('+353871234567', result, 'Should convert 00 prefix to +');
        
        // Test 4: With parentheses
        result = PhoneNormalizationService.normalize('(+353) 87-123-4567', 'Ireland');
        System.assertEquals('+353871234567', result, 'Should strip parentheses and hyphens');
        
        // Test 5: With leading 0 in international format
        result = PhoneNormalizationService.normalize('+3530871234567', 'Ireland');
        System.assertEquals('+353871234567', result, 'Should remove 0 after country code');
        
        // Test 6: Already normalized
        result = PhoneNormalizationService.normalize('+353871234567', 'Ireland');
        System.assertEquals('+353871234567', result, 'Should handle already normalized number');
    }
    
    /**
     * Test pattern detection without Market_Unit
     */
    @isTest
    static void testPatternDetection() {
        // Danish: 45 + 8 digits = 10 total
        String result = PhoneNormalizationService.normalize('4542455150', null);
        System.assertEquals('+4542455150', result, 'Should detect Danish pattern');
        
        // Swedish: 46 + 9 digits = 11 total
        result = PhoneNormalizationService.normalize('46701234567', null);
        System.assertEquals('+46701234567', result, 'Should detect Swedish pattern');
        
        // Irish: 353 + 9 digits = 12 total
        result = PhoneNormalizationService.normalize('353871234567', null);
        System.assertEquals('+353871234567', result, 'Should detect Irish pattern');
    }
    
    /**
     * Test complex formatting scenarios
     */
    @isTest
    static void testComplexFormatting() {
        // Multiple types of separators
        String result = PhoneNormalizationService.normalize('(+45) 0-42-45-51-50', 'DFJ_DK');
        System.assertEquals('+4542455150', result, 'Should handle complex formatting');
        
        result = PhoneNormalizationService.normalize('+46 (0)70-123-45-67', 'FA_SE');
        System.assertEquals('+46701234567', result, 'Should handle parentheses around zero');
        
        result = PhoneNormalizationService.normalize('00 353 (0)87 123 4567', 'Ireland');
        System.assertEquals('+353871234567', result, 'Should handle 00 prefix with complex format');
    }
    
    /**
     * Test null and blank inputs
     */
    @isTest
    static void testNullAndBlank() {
        String result = PhoneNormalizationService.normalize(null, 'DFJ_DK');
        System.assertEquals(null, result, 'Should return null for null input');
        
        result = PhoneNormalizationService.normalize('', 'DFJ_DK');
        System.assertEquals('', result, 'Should return empty for empty input');
        
        result = PhoneNormalizationService.normalize('   ', 'DFJ_DK');
        System.assertEquals('   ', result, 'Should return blank for blank input');
    }
    
    /**
     * Test error scenarios
     */
    @isTest
    static void testErrorScenarios() {
        // Local number without Market_Unit should still normalize via pattern detection
        String detected = PhoneNormalizationService.normalize('42455150', null);
        System.assertEquals('+4542455150', detected, 'Should detect Danish format without Market Unit');
        
        // Invalid number format
        try {
            PhoneNormalizationService.normalize('123', 'DFJ_DK');
            System.assert(false, 'Should throw exception for invalid number');
        } catch (PhoneNormalizationService.PhoneNormalizationException e) {
            System.assert(true, 'Should throw exception for too short number');
        }
        
        // Unsupported Market_Unit should still normalize if pattern is clear
        String inferred = PhoneNormalizationService.normalize('12345678', 'UNKNOWN');
        System.assertEquals('+4512345678', inferred, 'Should fall back to Danish pattern even with unknown Market Unit');
    }
    
    /**
     * Test edge cases with zeros
     */
    @isTest
    static void testZeroHandling() {
        // Multiple leading zeros in local number
        String result = PhoneNormalizationService.normalize('00042455150', 'DFJ_DK');
        System.assertEquals('+4542455150', result, 'Should handle 00 prefix correctly');
        
        // Zero after country code
        result = PhoneNormalizationService.normalize('+45042455150', 'DFJ_DK');
        System.assertEquals('+4542455150', result, 'Should remove zero after +45');
        
        result = PhoneNormalizationService.normalize('+460701234567', 'FA_SE');
        System.assertEquals('+46701234567', result, 'Should remove zero after +46');
        
        result = PhoneNormalizationService.normalize('+3530871234567', 'Ireland');
        System.assertEquals('+353871234567', result, 'Should remove zero after +353');
    }
    
    /**
     * Test additional edge cases for full coverage
     */
    @isTest
    static void testAdditionalEdgeCases() {
        // Empty string should return empty
        String result = PhoneNormalizationService.normalize('', 'DFJ_DK');
        System.assertEquals('', result, 'Empty string should return empty');
        
        // Just a plus sign
        try {
            PhoneNormalizationService.normalize('+', 'DFJ_DK');
            System.assert(false, 'Should throw exception for just plus sign');
        } catch (PhoneNormalizationService.PhoneNormalizationException e) {
            System.assert(true, 'Should throw exception for invalid format');
        }
        
        // Unknown country code with plus
        try {
            PhoneNormalizationService.normalize('+991234567890', 'DFJ_DK');
            System.assert(false, 'Should throw exception for unknown country code');
        } catch (PhoneNormalizationService.PhoneNormalizationException e) {
            System.assert(true, 'Should throw exception for unknown country code');
        }
        
        // Number that looks like it has country code but too short
        try {
            PhoneNormalizationService.normalize('4512345', 'DFJ_DK');
            System.assert(false, 'Should throw exception for short number');
        } catch (PhoneNormalizationService.PhoneNormalizationException e) {
            System.assert(true, 'Should throw exception for invalid length');
        }
        
        // Test with formatting characters only
        try {
            PhoneNormalizationService.normalize('(-)--', 'DFJ_DK');
            System.assert(false, 'Should throw exception for no digits');
        } catch (PhoneNormalizationService.PhoneNormalizationException e) {
            System.assert(true, 'Should throw exception when no digits present');
        }
    }
}