/**
 * Test class for LeadPhoneTrigger and PhoneFieldNormalizer for Lead object
 */
@isTest
private class LeadPhoneTriggerTest {
    
    /**
     * Test insert with phone fields
     */
    @isTest
    static void testLeadInsertWithPhones() {
        // Create Lead with phone in MobilePhone field only
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'DFJ_DK',
            Country = 'Denmark',
            MobilePhone = '42 45 51 50'
        );
        
        Test.startTest();
        insert testLead;
        Test.stopTest();
        
        // Query the lead to verify normalization
        Lead result = [
            SELECT MobilePhone 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        
        System.assertEquals('+4542455150', result.MobilePhone, 'MobilePhone should be normalized');
    }
    
    /**
     * Test different phone formats on different fields
     */
    @isTest
    static void testMultiplePhoneFields() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'DFJ_DK',
            Country = 'Denmark',
            MobilePhone = '42 45 51 50',
            Phone = '+45 042 45 51 60',
            Phone2__c = '0045 42 45 51 70',
            Phone3__c = '(+45) 42-45-51-80'
        );
        
        Test.startTest();
        insert testLead;
        Test.stopTest();
        
        // Query the lead to verify normalization
        Lead result = [
            SELECT MobilePhone, Phone, Phone2__c, Phone3__c 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        
        // Note: The trigger processes all phone fields
        System.assertEquals('+4542455150', result.MobilePhone, 'MobilePhone should be normalized');
        System.assertEquals('+4542455160', result.Phone, 'Phone should be normalized');
        System.assertEquals('+4542455170', result.Phone2__c, 'Phone2__c should be normalized');
        System.assertEquals('+4542455180', result.Phone3__c, 'Phone3__c should be normalized');
    }
    
    /**
     * Test update with phone field changes
     */
    @isTest
    static void testLeadUpdateWithPhoneChanges() {
        // Create Lead without phones
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'FA_SE',
            Country = 'Sweden'
        );
        insert testLead;
        
        // Update with phone numbers - use only MobilePhone
        testLead.MobilePhone = '070-123 45 67';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // Query the lead to verify normalization
        Lead result = [
            SELECT MobilePhone 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        
        System.assertEquals('+46701234567', result.MobilePhone, 'MobilePhone should be normalized');
    }
    
    /**
     * Test bulk insert
     */
    @isTest
    static void testBulkLeadInsert() {
        List<Lead> leads = new List<Lead>();
        
        for (Integer i = 0; i < 200; i++) {
            Integer phoneNum = 10000000 + i;
            leads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Market_Unit__c = 'DFJ_DK',
                Country = 'Denmark',
                MobilePhone = String.valueOf(phoneNum)
            ));
        }
        
        Test.startTest();
        insert leads;
        Test.stopTest();
        
        // Verify all were normalized
        List<Lead> results = [
            SELECT MobilePhone 
            FROM Lead 
            WHERE Id IN :leads
        ];
        
        System.assertEquals(200, results.size(), 'Should have 200 leads');
        
        for (Lead result : results) {
            System.assert(result.MobilePhone.startsWith('+45'), 'All phones should be normalized with +45');
        }
    }
    
    /**
     * Test Irish market unit
     */
    @isTest
    static void testIrishLeadPhones() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'Ireland',
            Country = 'Ireland',
            MobilePhone = '087 123 4567'
        );
        
        Test.startTest();
        insert testLead;
        Test.stopTest();
        
        Lead result = [
            SELECT MobilePhone 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        
        System.assertEquals('+353871234567', result.MobilePhone, 'Irish mobile should be normalized');
    }
    
    /**
     * Test update without phone changes (should not trigger normalization)
     */
    @isTest
    static void testUpdateWithoutPhoneChanges() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'DFJ_DK',
            MobilePhone = '+4542455150'
        );
        insert testLead;
        
        // Update non-phone field
        testLead.FirstName = 'Updated';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        Lead result = [
            SELECT MobilePhone, FirstName 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        
        System.assertEquals('+4542455150', result.MobilePhone, 'Phone should remain unchanged');
        System.assertEquals('Updated', result.FirstName, 'FirstName should be updated');
    }
    
    /**
     * Test with null phone fields
     */
    @isTest
    static void testLeadWithNullPhones() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'DFJ_DK',
            Country = 'Denmark'
        );
        
        Test.startTest();
        insert testLead;
        Test.stopTest();
        
        Lead result = [
            SELECT MobilePhone, Phone, Phone2__c, Phone3__c 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        
        System.assertEquals(null, result.MobilePhone, 'MobilePhone should be null');
        System.assertEquals(null, result.Phone, 'Phone should be null');
        System.assertEquals(null, result.Phone2__c, 'Phone2__c should be null');
        System.assertEquals(null, result.Phone3__c, 'Phone3__c should be null');
    }
    
    /**
     * Test mixed phone formats
     */
    @isTest
    static void testMixedPhoneFormats() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'DFJ_DK',
            Country = 'Denmark',
            MobilePhone = '0045 24 55 51 67',     // 00 prefix with Danish number
            Phone = '(+45) 24-55-51-77',          // Parentheses and hyphens
            Phone2__c = '+450024555187',          // With zero after code  
            Phone3__c = '24555197'                // Local format
        );
        
        Test.startTest();
        insert testLead;
        Test.stopTest();
        
        Lead result = [
            SELECT MobilePhone, Phone, Phone2__c, Phone3__c 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        
        System.assertEquals('+4524555167', result.MobilePhone, 'Should normalize 00 prefix');
        System.assertEquals('+4524555177', result.Phone, 'Should strip formatting');
        System.assertEquals('+4524555187', result.Phone2__c, 'Should remove zero after code');
        System.assertEquals('+4524555197', result.Phone3__c, 'Should add country code from Market_Unit');
    }
}