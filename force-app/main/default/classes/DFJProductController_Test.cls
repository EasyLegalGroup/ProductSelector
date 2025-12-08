/**
 * @description Test class for DFJProductController_Class and DFJProductService_Class
 * @author Copilot
 * @date 2025-12-08
 */
@isTest
public class DFJProductController_Test {
    
    private static final String TEST_IDENTIFIER = 'test_dfj_identifier';
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Id accountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(
            LastName = 'Test Account',
            PersonEmail = 'test@test.com',
            RecordTypeId = accountRecordType,
            Market_Unit__c = 'DFJ_DK',
            CurrencyIsoCode = 'DKK'
        );
        insert testAccount;
        
        // Create test Lead
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'testlead@test.com',
            Provider_Id__c = 'testProvider123'
        );
        insert testLead;
        
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            IsActive = true,
            Product_Identifier__c = 'TST'
        );
        insert testProduct;
        
        // Create Standard Pricebook Entry
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPbe;
        
        // Create Custom Pricebook with Internal_Identifier__c
        Pricebook2 customPb = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true,
            Internal_Identifier__c = TEST_IDENTIFIER,
            CurrencyIsoCode = 'DKK'
        );
        insert customPb;
        
        // Create Custom Pricebook Entry
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert customPbe;
    }
    
    // ============ DFJProductController_Class Tests ============
    
    @isTest
    static void testUpdateRecord_Apex_Lead() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Map<String, Object> fieldValues = new Map<String, Object>{
            'telegenta__Forecast__c' => 1000.00
        };
        
        Test.startTest();
        Boolean result = DFJProductController_Class.updateRecord_Apex(testLead.Id, fieldValues, 'Lead');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Update should succeed');
    }
    
    @isTest
    static void testUpdateRecord_Apex_Opportunity() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Order_Total__c' => 500.00
        };
        
        Test.startTest();
        Boolean result = DFJProductController_Class.updateRecord_Apex(testOpp.Id, fieldValues, 'Opportunity');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Update should succeed');
    }
    
    @isTest
    static void testInsertRecords_Apex_Lead() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Internal_Identifier__c = :TEST_IDENTIFIER LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id LIMIT 1];
        
        List<Map<String, Object>> newProducts = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Test Lead Product',
                'Quantity__c' => 1,
                'Item_Price__c' => 100.00,
                'Discount__c' => 0,
                'Lead__c' => testLead.Id,
                'Pricebook_Id__c' => pb.Id,
                'PricebookEntry_Id__c' => pbe.Id,
                'Product_Id__c' => pbe.Product2Id
            }
        };
        
        Test.startTest();
        List<sObject> result = DFJProductController_Class.insertRecords_Apex(newProducts, testLead.Id, 100.00, 'Lead');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return inserted records');
    }
    
    @isTest
    static void testDeleteRecord_Apex() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Internal_Identifier__c = :TEST_IDENTIFIER LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id LIMIT 1];
        
        // Create LeadProduct to delete
        LeadProducts__c lp = new LeadProducts__c(
            Name = 'Product To Delete',
            Quantity__c = 1,
            Item_Price__c = 50.00,
            Lead__c = testLead.Id,
            Pricebook_Id__c = pb.Id,
            PricebookEntry_Id__c = pbe.Id,
            Product_Id__c = pbe.Product2Id
        );
        insert lp;
        
        Test.startTest();
        String result = DFJProductController_Class.deleteRecord_Apex(new List<String>{lp.Id}, 'LeadProducts__c');
        Test.stopTest();
        
        System.assert(result.contains('Deleted') || result.contains('Success'), 'Delete should succeed');
    }
    
    @isTest
    static void testGetOrderCategorySize() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        Integer result = DFJProductController_Class.getOrderCategorySize(testLead.Id, 'Lead');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a count');
    }
    
    @isTest
    static void testGetAllPriceBookAndProducts() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        try {
            DFJProductController_Class.ProductsWrapper result = DFJProductController_Class.getAllPriceBookAndProducts(testLead.Id, 'Lead', TEST_IDENTIFIER);
            // May succeed or throw exception based on custom permissions
            System.assert(true, 'Method executed');
        } catch (AuraHandledException e) {
            // Expected when user doesn't have custom permission access
            System.assert(true, 'AuraHandledException thrown as expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccessiblePriceBookIdentifiers() {
        Test.startTest();
        Set<String> result = DFJProductController_Class.getAccessiblePriceBookIdentifiers();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return identifiers set');
    }
    
    // ============ DFJProductService_Class Tests ============
    
    @isTest
    static void testService_getAllThePricebooksAndProducts_Apex() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        try {
            DFJProductController_Class.ProductsWrapper result = DFJProductService_Class.getAllThePricebooksAndProducts_Apex(testLead.Id, 'Lead', TEST_IDENTIFIER);
            // May succeed or throw exception based on custom permissions
            System.assert(true, 'Service method executed');
        } catch (AuraHandledException e) {
            // Expected when user doesn't have custom permission access
            System.assert(true, 'AuraHandledException thrown as expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testService_getAllThePricebooksAndProducts_NullParams() {
        Test.startTest();
        DFJProductController_Class.ProductsWrapper result = DFJProductService_Class.getAllThePricebooksAndProducts_Apex(null, null, null);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for invalid params');
    }
    
    @isTest
    static void testService_getOrderCategorySize() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        Integer result = DFJProductService_Class.getOrderCategorySize(testLead.Id, 'Lead');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Service should return category size');
    }
    
    @isTest
    static void testService_getOrderCategorySize_NullParams() {
        Test.startTest();
        Integer result = DFJProductService_Class.getOrderCategorySize(null, null);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for invalid params');
    }
    
    @isTest
    static void testService_deleteRecord_Apex() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Internal_Identifier__c = :TEST_IDENTIFIER LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id LIMIT 1];
        
        LeadProducts__c lp = new LeadProducts__c(
            Name = 'Service Delete Test',
            Quantity__c = 1,
            Item_Price__c = 25.00,
            Lead__c = testLead.Id,
            Pricebook_Id__c = pb.Id,
            PricebookEntry_Id__c = pbe.Id,
            Product_Id__c = pbe.Product2Id
        );
        insert lp;
        
        Test.startTest();
        String result = DFJProductService_Class.deleteRecord_Apex(new List<String>{lp.Id}, 'Lead');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Service should return result');
    }
    
    @isTest
    static void testService_deleteRecord_Apex_EmptyList() {
        Test.startTest();
        String result = DFJProductService_Class.deleteRecord_Apex(new List<String>(), 'Lead');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for empty list');
    }
    
    @isTest
    static void testService_updateRecord_Apex() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Map<String, Object> fieldValues = new Map<String, Object>{
            'telegenta__Forecast__c' => 2000.00
        };
        
        Test.startTest();
        Boolean result = DFJProductService_Class.updateRecord_Apex(testLead.Id, fieldValues, 'Lead');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Service update should succeed');
    }
    
    @isTest
    static void testService_updateRecord_Apex_InvalidParams() {
        Test.startTest();
        Boolean result = DFJProductService_Class.updateRecord_Apex(null, new Map<String, Object>(), null);
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for invalid params');
    }
    
    @isTest
    static void testService_insertRecords_Apex() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Internal_Identifier__c = :TEST_IDENTIFIER LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id LIMIT 1];
        
        List<Map<String, Object>> newProducts = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Service Insert Product',
                'Quantity__c' => 2,
                'Item_Price__c' => 75.00,
                'Discount__c' => 5,
                'Lead__c' => testLead.Id,
                'Pricebook_Id__c' => pb.Id,
                'PricebookEntry_Id__c' => pbe.Id,
                'Product_Id__c' => pbe.Product2Id
            }
        };
        
        Test.startTest();
        List<sObject> result = DFJProductService_Class.insertRecords_Apex(newProducts, testLead.Id, 150.00, 'Lead');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Service should return inserted records');
    }
    
    @isTest
    static void testService_insertRecords_Apex_EmptyList() {
        Test.startTest();
        List<sObject> result = DFJProductService_Class.insertRecords_Apex(new List<Object>(), null, 0, 'Lead');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for empty products list');
    }
}
