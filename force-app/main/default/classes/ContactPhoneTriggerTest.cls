/**
 * Test class for ContactPhoneTrigger and PhoneFieldNormalizer for Contact object
 */
@isTest
private class ContactPhoneTriggerTest {
    
    /**
     * Test insert with phone fields
     */
    @isTest
    static void testContactInsertWithPhones() {
        // Create Account first (required for Contact)
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'DFJ_DK'
        );
        insert testAccount;
        
        // Create Contact with various phone formats
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'DFJ_DK',
            MailingCountry = 'Denmark',
            AssistantPhone = '42 45 51 50',
            HomePhone = '+45 042 45 51 51',
            MobilePhone = '0045 42 45 51 52',
            OtherPhone = '(+45) 42-45-51-53',
            Phone = '42455154',
            Spouse_Phone__c = '+4542455155'
        );
        
        Test.startTest();
        insert testContact;
        Test.stopTest();
        
        // Query the contact to verify normalization
        Contact result = [
            SELECT AssistantPhone, HomePhone, MobilePhone, OtherPhone, Phone, Spouse_Phone__c 
            FROM Contact 
            WHERE Id = :testContact.Id
        ];
        
        System.assertEquals('+4542455150', result.AssistantPhone, 'AssistantPhone should be normalized');
        System.assertEquals('+4542455151', result.HomePhone, 'HomePhone should be normalized');
        System.assertEquals('+4542455152', result.MobilePhone, 'MobilePhone should be normalized');
        System.assertEquals('+4542455153', result.OtherPhone, 'OtherPhone should be normalized');
        System.assertEquals('+4542455154', result.Phone, 'Phone should be normalized');
        System.assertEquals('+4542455155', result.Spouse_Phone__c, 'Spouse_Phone__c should be normalized');
    }
    
    /**
     * Test update with phone field changes
     */
    @isTest
    static void testContactUpdateWithPhoneChanges() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'FA_SE'
        );
        insert testAccount;
        
        // Create Contact without phones
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'FA_SE',
            MailingCountry = 'Sweden'
        );
        insert testContact;
        
        // Update with phone numbers
        testContact.MobilePhone = '070-123 45 67';
        testContact.Phone = '+46 070 123 45 68';
        testContact.HomePhone = '0046701234569';
        
        Test.startTest();
        update testContact;
        Test.stopTest();
        
        // Query the contact to verify normalization
        Contact result = [
            SELECT MobilePhone, Phone, HomePhone 
            FROM Contact 
            WHERE Id = :testContact.Id
        ];
        
        System.assertEquals('+46701234567', result.MobilePhone, 'MobilePhone should be normalized');
        System.assertEquals('+46701234568', result.Phone, 'Phone should be normalized');
        System.assertEquals('+46701234569', result.HomePhone, 'HomePhone should be normalized');
    }
    
    /**
     * Test bulk insert
     */
    @isTest
    static void testBulkContactInsert() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'DFJ_DK'
        );
        insert testAccount;
        
        List<Contact> contacts = new List<Contact>();
        
        for (Integer i = 0; i < 200; i++) {
            Integer phoneNum = 10000000 + i;
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = testAccount.Id,
                Market_Unit__c = 'DFJ_DK',
                MailingCountry = 'Denmark',
                MobilePhone = String.valueOf(phoneNum)
            ));
        }
        
        Test.startTest();
        insert contacts;
        Test.stopTest();
        
        // Verify all were normalized
        List<Contact> results = [
            SELECT MobilePhone 
            FROM Contact 
            WHERE Id IN :contacts
        ];
        
        System.assertEquals(200, results.size(), 'Should have 200 contacts');
        
        for (Contact result : results) {
            System.assert(result.MobilePhone.startsWith('+45'), 'All phones should be normalized with +45');
        }
    }
    
    /**
     * Test Irish market unit
     */
    @isTest
    static void testIrishContactPhones() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'Ireland'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'Ireland',
            MailingCountry = 'Ireland',
            MobilePhone = '087 123 4567',
            Phone = '+353 087 123 4568',
            HomePhone = '00353871234569'
        );
        
        Test.startTest();
        insert testContact;
        Test.stopTest();
        
        Contact result = [
            SELECT MobilePhone, Phone, HomePhone 
            FROM Contact 
            WHERE Id = :testContact.Id
        ];
        
        System.assertEquals('+353871234567', result.MobilePhone, 'Irish mobile should be normalized');
        System.assertEquals('+353871234568', result.Phone, 'Irish phone should be normalized');
        System.assertEquals('+353871234569', result.HomePhone, 'Irish home phone should be normalized');
    }
    
    /**
     * Test update without phone changes (should not trigger normalization)
     */
    @isTest
    static void testUpdateWithoutPhoneChanges() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'DFJ_DK'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'DFJ_DK',
            MailingCountry = 'Denmark',
            MobilePhone = '+4542455150'
        );
        insert testContact;
        
        // Update non-phone field
        testContact.FirstName = 'Updated';
        
        Test.startTest();
        update testContact;
        Test.stopTest();
        
        Contact result = [
            SELECT MobilePhone, FirstName 
            FROM Contact 
            WHERE Id = :testContact.Id
        ];
        
        System.assertEquals('+4542455150', result.MobilePhone, 'Phone should remain unchanged');
        System.assertEquals('Updated', result.FirstName, 'FirstName should be updated');
    }
    
    /**
     * Test all six phone fields with different formats
     */
    @isTest
    static void testAllPhoneFields() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'FA_SE'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'FA_SE',
            MailingCountry = 'Sweden',
            AssistantPhone = '0046701234561',
            HomePhone = '(+46) 70-123-45-62',
            MobilePhone = '+460701234563',
            OtherPhone = '701234564',
            Phone = '070-123 45 65',
            Spouse_Phone__c = '00 46 70 123 45 66'
        );
        
        Test.startTest();
        insert testContact;
        Test.stopTest();
        
        Contact result = [
            SELECT AssistantPhone, HomePhone, MobilePhone, OtherPhone, Phone, Spouse_Phone__c 
            FROM Contact 
            WHERE Id = :testContact.Id
        ];
        
        System.assertEquals('+46701234561', result.AssistantPhone, 'AssistantPhone normalized');
        System.assertEquals('+46701234562', result.HomePhone, 'HomePhone normalized');
        System.assertEquals('+46701234563', result.MobilePhone, 'MobilePhone normalized');
        System.assertEquals('+46701234564', result.OtherPhone, 'OtherPhone normalized');
        System.assertEquals('+46701234565', result.Phone, 'Phone normalized');
        System.assertEquals('+46701234566', result.Spouse_Phone__c, 'Spouse_Phone__c normalized');
    }
    
    /**
     * Test with null phone fields
     */
    @isTest
    static void testContactWithNullPhones() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'DFJ_DK'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'DFJ_DK',
            MailingCountry = 'Denmark'
        );
        
        Test.startTest();
        insert testContact;
        Test.stopTest();
        
        Contact result = [
            SELECT AssistantPhone, HomePhone, MobilePhone, OtherPhone, Phone, Spouse_Phone__c 
            FROM Contact 
            WHERE Id = :testContact.Id
        ];
        
        System.assertEquals(null, result.AssistantPhone, 'AssistantPhone should be null');
        System.assertEquals(null, result.HomePhone, 'HomePhone should be null');
        System.assertEquals(null, result.MobilePhone, 'MobilePhone should be null');
        System.assertEquals(null, result.OtherPhone, 'OtherPhone should be null');
        System.assertEquals(null, result.Phone, 'Phone should be null');
        System.assertEquals(null, result.Spouse_Phone__c, 'Spouse_Phone__c should be null');
    }
}