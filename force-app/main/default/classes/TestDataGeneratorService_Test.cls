/**
 * @description Test class for TestDataGeneratorService
 * @author Copilot
 * @date 2025
 */
@isTest
private class TestDataGeneratorService_Test {
    
    @isTest
    static void testGenerateTestData_Success() {
        Test.startTest();
        
        // Call the invocable method
        List<TestDataGeneratorService.TestDataResult> results = TestDataGeneratorService.generateTestDataInternal();
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        
        TestDataGeneratorService.TestDataResult result = results[0];
        System.assertEquals(true, result.success, 'Generation should succeed: ' + result.message);
        System.assertEquals(20, result.leadCount, 'Should create 20 Leads');
        System.assertEquals(10, result.accountCount, 'Should create 10 PersonAccounts');
        System.assertEquals(13, result.orderCount, 'Should create 13 Orders');
        System.assertEquals(13, result.journalCount, 'Should create 13 Journals');
        
        // Verify Leads were created
        List<Lead> leads = [SELECT Id, Market_Unit__c, Status FROM Lead];
        System.assertEquals(20, leads.size(), 'Should have 20 Leads in database');
        
        // Verify PersonAccounts were created (converted leads)
        List<Lead> convertedLeads = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE IsConverted = true];
        System.assertEquals(10, convertedLeads.size(), 'Should have 10 converted Leads');
        
        // Verify Orders were created
        List<Order> orders = [SELECT Id, AccountId, Journal__c FROM Order];
        System.assertEquals(13, orders.size(), 'Should have 13 Orders');
        
        // Verify Journals were created
        List<Journal__c> journals = [SELECT Id, Order__c, Account__c FROM Journal__c];
        System.assertEquals(13, journals.size(), 'Should have 13 Journals');
        
        // Verify bidirectional relationship
        Integer ordersWithJournals = 0;
        Integer journalsWithOrders = 0;
        
        for (Order o : orders) {
            if (o.Journal__c != null) {
                ordersWithJournals++;
            }
        }
        
        for (Journal__c j : journals) {
            if (j.Order__c != null) {
                journalsWithOrders++;
            }
        }
        
        System.assertEquals(13, ordersWithJournals, 'All Orders should have Journal lookup');
        System.assertEquals(13, journalsWithOrders, 'All Journals should have Order lookup');
    }
    
    @isTest
    static void testGenerateTestData_MarketUnitDistribution() {
        Test.startTest();
        
        // Call the invocable method
        List<TestDataGeneratorService.TestDataResult> results = TestDataGeneratorService.generateTestDataInternal();
        
        Test.stopTest();
        
        // Verify Market Unit distribution
        List<Lead> dfjDkLeads = [SELECT Id FROM Lead WHERE Market_Unit__c = 'DFJ_DK'];
        List<Lead> faSeLeads = [SELECT Id FROM Lead WHERE Market_Unit__c = 'FA_SE'];
        List<Lead> irelandLeads = [SELECT Id FROM Lead WHERE Market_Unit__c = 'Ireland'];
        List<Lead> hostLeads = [SELECT Id FROM Lead WHERE Leadtype__c = 'B2B'];
        
        System.assertEquals(5, dfjDkLeads.size(), 'Should have 5 DFJ_DK Leads');
        System.assertEquals(5, faSeLeads.size(), 'Should have 5 FA_SE Leads');
        System.assertEquals(5, irelandLeads.size(), 'Should have 5 Ireland Leads');
        System.assertEquals(5, hostLeads.size(), 'Should have 5 Host Leads');
    }
    
    @isTest
    static void testGenerateTestData_AccountOrderDistribution() {
        Test.startTest();
        
        // Call the invocable method
        List<TestDataGeneratorService.TestDataResult> results = TestDataGeneratorService.generateTestDataInternal();
        
        Test.stopTest();
        
        // Verify Order distribution across PersonAccounts
        List<Account> accounts = [
            SELECT Id, (SELECT Id FROM Orders) 
            FROM Account 
            WHERE Id IN (SELECT ConvertedAccountId FROM Lead WHERE IsConverted = true)
        ];
        
        System.assertEquals(10, accounts.size(), 'Should have 10 PersonAccounts');
        
        Integer accountsWith1Order = 0;
        Integer accountsWith2Orders = 0;
        
        for (Account acc : accounts) {
            if (acc.Orders.size() == 1) {
                accountsWith1Order++;
            } else if (acc.Orders.size() == 2) {
                accountsWith2Orders++;
            }
        }
        
        System.assertEquals(7, accountsWith1Order, 'Should have 7 accounts with 1 order');
        System.assertEquals(3, accountsWith2Orders, 'Should have 3 accounts with 2 orders');
    }
    
    @isTest
    static void testGenerateTestData_LeadAccountLookup() {
        Test.startTest();
        
        // Call the invocable method
        List<TestDataGeneratorService.TestDataResult> results = TestDataGeneratorService.generateTestDataInternal();
        
        Test.stopTest();
        
        // Verify Lead__c lookup is set on PersonAccounts
        List<Account> accounts = [
            SELECT Id, Lead__c 
            FROM Account 
            WHERE Id IN (SELECT ConvertedAccountId FROM Lead WHERE IsConverted = true)
        ];
        
        for (Account acc : accounts) {
            System.assertNotEquals(null, acc.Lead__c, 'PersonAccount should have Lead__c lookup populated');
        }
    }
}