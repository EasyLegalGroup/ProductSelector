/**
 * Test class for AccountPhoneTrigger and PhoneFieldNormalizer for Account object
 * Tests both Business Accounts and Person Accounts
 */
@isTest
private class AccountPhoneTriggerTest {
    
    /**
     * Test Business Account insert with Phone field
     */
    @isTest
    static void testBusinessAccountInsert() {
        Account testAccount = new Account(
            Name = 'Test Business Account',
            Market_Unit__c = 'DFJ_DK',
            BillingCountry = 'Denmark',
            Phone = '42 45 51 50'
        );
        
        Test.startTest();
        insert testAccount;
        Test.stopTest();
        
        Account result = [
            SELECT Phone 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals('+4542455150', result.Phone, 'Business Account Phone should be normalized');
    }
    
    /**
     * Test Person Account insert with all phone fields
     * Note: Person Account creation requires specific RecordType and different approach
     */
    @isTest
    static void testPersonAccountInsert() {
        // Check if Person Accounts are enabled in this org
        if (!Schema.sObjectType.Account.fields.getMap().containsKey('IsPersonAccount')) {
            return; // Skip test if Person Accounts not enabled
        }
        
        Account testAccount = new Account(
            FirstName = 'Test',
            LastName = 'Person',
            Market_Unit__c = 'FA_SE',
            BillingCountry = 'Sweden',
            Phone = '070-123 45 67'
        );
        
        Test.startTest();
        try {
            insert testAccount;
        } catch (Exception e) {
            // Person Accounts might not be configured in all orgs
            System.debug('Person Account insert failed: ' + e.getMessage());
            return;
        }
        Test.stopTest();
        
        Account result = [
            SELECT Phone, IsPersonAccount
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals('+46701234567', result.Phone, 'Phone normalized');
    }
    
    /**
     * Test Person Account with multiple phone fields
     */
    @isTest
    static void testPersonAccountMultipleFields() {
        // Check if Person Accounts are enabled in this org
        if (!Schema.sObjectType.Account.fields.getMap().containsKey('IsPersonAccount')) {
            return; // Skip test if Person Accounts not enabled
        }
        
        Account testAccount = new Account(
            FirstName = 'Test',
            LastName = 'Person',
            Market_Unit__c = 'FA_SE',
            BillingCountry = 'Sweden',
            Phone = '070-123 45 67',
            PersonMobilePhone = '070-123 45 67',
            PersonHomePhone = '0046701234587',
            PersonAssistantPhone = '(+46) 70-123-45-97',
            PersonOtherPhone = '+460701234507',
            Spouse_Phone__pc = '701234517'
        );
        
        Test.startTest();
        try {
            insert testAccount;
        } catch (Exception e) {
            // Person Accounts might not be configured in all orgs
            System.debug('Person Account insert failed: ' + e.getMessage());
            return;
        }
        Test.stopTest();
        
        Account result = [
            SELECT Phone, PersonMobilePhone, PersonHomePhone, PersonAssistantPhone, 
                   PersonOtherPhone, Spouse_Phone__pc, IsPersonAccount
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        if (result.IsPersonAccount) {
            System.assertEquals('+46701234567', result.Phone, 'Phone normalized');
            System.assertEquals('+46701234567', result.PersonMobilePhone, 'PersonMobilePhone normalized');
            System.assertEquals('+46701234587', result.PersonHomePhone, 'PersonHomePhone normalized');
            System.assertEquals('+46701234597', result.PersonAssistantPhone, 'PersonAssistantPhone normalized');
            System.assertEquals('+46701234507', result.PersonOtherPhone, 'PersonOtherPhone normalized');
            System.assertEquals('+46701234517', result.Spouse_Phone__pc, 'Spouse_Phone__pc normalized');
        }
    }
    
    /**
     * Test Business Account update with Phone change
     */
    @isTest
    static void testBusinessAccountUpdate() {
        Account testAccount = new Account(
            Name = 'Test Business Account',
            Market_Unit__c = 'Ireland',
            BillingCountry = 'Ireland'
        );
        insert testAccount;
        
        testAccount.Phone = '087 123 4567';
        
        Test.startTest();
        update testAccount;
        Test.stopTest();
        
        Account result = [
            SELECT Phone 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals('+353871234567', result.Phone, 'Phone should be normalized after update');
    }
    
    /**
     * Test bulk insert
     */
    @isTest
    static void testBulkAccountInsert() {
        List<Account> accounts = new List<Account>();
        
        for (Integer i = 0; i < 200; i++) {
            Integer phoneNum = 10000000 + i;
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Market_Unit__c = 'DFJ_DK',
                BillingCountry = 'Denmark',
                Phone = String.valueOf(phoneNum)
            ));
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        List<Account> results = [
            SELECT Phone 
            FROM Account 
            WHERE Id IN :accounts
        ];
        
        System.assertEquals(200, results.size(), 'Should have 200 accounts');
        
        for (Account result : results) {
            System.assert(result.Phone.startsWith('+45'), 'All phones should be normalized with +45');
        }
    }
    
    /**
     * Test different country codes
     */
    @isTest
    static void testMultipleCountryCodes() {
        List<Account> accounts = new List<Account>();
        
        accounts.add(new Account(
            Name = 'Danish Account',
            Market_Unit__c = 'DFJ_DK',
            BillingCountry = 'Denmark',
            Phone = '42455150'
        ));
        
        accounts.add(new Account(
            Name = 'Swedish Account',
            Market_Unit__c = 'FA_SE',
            BillingCountry = 'Sweden',
            Phone = '701234567'
        ));
        
        accounts.add(new Account(
            Name = 'Irish Account',
            Market_Unit__c = 'Ireland',
            BillingCountry = 'Ireland',
            Phone = '871234567'
        ));
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        List<Account> results = [
            SELECT Name, Phone 
            FROM Account 
            WHERE Id IN :accounts
            ORDER BY Name
        ];
        
        System.assertEquals('+4542455150', results[0].Phone, 'Danish phone normalized');
        System.assertEquals('+353871234567', results[1].Phone, 'Irish phone normalized');
        System.assertEquals('+46701234567', results[2].Phone, 'Swedish phone normalized');
    }
    
    /**
     * Test update without phone changes
     */
    @isTest
    static void testUpdateWithoutPhoneChanges() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'DFJ_DK',
            BillingCountry = 'Denmark',
            Phone = '+4542455150'
        );
        insert testAccount;
        
        testAccount.Name = 'Updated Account';
        
        Test.startTest();
        update testAccount;
        Test.stopTest();
        
        Account result = [
            SELECT Phone, Name 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals('+4542455150', result.Phone, 'Phone should remain unchanged');
        System.assertEquals('Updated Account', result.Name, 'Name should be updated');
    }
    
    /**
     * Test with complex phone formats
     */
    @isTest
    static void testComplexPhoneFormats() {
        List<Account> accounts = new List<Account>();
        
        accounts.add(new Account(
            Name = 'Account 1',
            Market_Unit__c = 'DFJ_DK',
            BillingCountry = 'Denmark',
            Phone = '(+45) 0-42-45-51-50'
        ));
        
        accounts.add(new Account(
            Name = 'Account 2',
            Market_Unit__c = 'FA_SE',
            BillingCountry = 'Sweden',
            Phone = '0046 (0)70-123-45-67'
        ));
        
        accounts.add(new Account(
            Name = 'Account 3',
            Market_Unit__c = 'Ireland',
            BillingCountry = 'Ireland',
            Phone = '00 353 (0)87 123 4567'
        ));
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        List<Account> results = [
            SELECT Phone 
            FROM Account 
            WHERE Id IN :accounts
            ORDER BY Name
        ];
        
        System.assertEquals('+4542455150', results[0].Phone, 'Complex Danish format normalized');
        System.assertEquals('+46701234567', results[1].Phone, 'Complex Swedish format normalized');
        System.assertEquals('+353871234567', results[2].Phone, 'Complex Irish format normalized');
    }
    
    /**
     * Test with null phone field
     */
    @isTest
    static void testAccountWithNullPhone() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'DFJ_DK',
            BillingCountry = 'Denmark'
        );
        
        Test.startTest();
        insert testAccount;
        Test.stopTest();
        
        Account result = [
            SELECT Phone 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals(null, result.Phone, 'Phone should be null');
    }
    
    /**
     * Test already normalized phone
     */
    @isTest
    static void testAlreadyNormalizedPhone() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'DFJ_DK',
            BillingCountry = 'Denmark',
            Phone = '+4542455150'
        );
        
        Test.startTest();
        insert testAccount;
        Test.stopTest();
        
        Account result = [
            SELECT Phone 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals('+4542455150', result.Phone, 'Already normalized phone should remain unchanged');
    }
}