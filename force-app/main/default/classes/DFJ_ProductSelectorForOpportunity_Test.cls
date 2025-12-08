/**
 * @description Tests for the DFJ_ProductSelectorForOpportunity_Apex class.
 */
@isTest
public class DFJ_ProductSelectorForOpportunity_Test {
    
    public static Account testAccount;
    public static Opportunity testOpportunity;
    public static Product2 testProduct;
    public static Pricebook2 testCustomPricebook;
    public static PricebookEntry testStandardPricebookEntry;
    public static PricebookEntry testCustomPricebookEntry;
    
    @testSetup
    static void setupTestData() {
        // Create a test Account
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a custom Pricebook
        testCustomPricebook = new Pricebook2(
            Name = 'Custom Pricebook',
            IsActive = true,
            Is_Opportunity_PriceBook__c = true,
            Internal_Identifier__c = 'CUS'
        );
        insert testCustomPricebook;
        
        // Create a test Product
        testProduct = new Product2(Name = 'Test Product', IsActive = true, Product_Identifier__c = 'PI1');
        insert testProduct;
        
        // Create Pricebook Entry in the standard Pricebook
        testStandardPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = testProduct.Id,
        UnitPrice = 100,
        IsActive = true
            );
        insert testStandardPricebookEntry;
        
        // Create Pricebook Entry in the custom Pricebook
        testCustomPricebookEntry = new PricebookEntry(
            Pricebook2Id = testCustomPricebook.Id,
        Product2Id = testProduct.Id,
        UnitPrice = 100,
        IsActive = true
            );
        insert testCustomPricebookEntry;
        
        // Create a test Opportunity with the custom Pricebook
        testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        AccountId = testAccount.Id,
        Market_Unit__c = 'DFJ_DK', 
        Pricebook2Id = testCustomPricebook.Id
            );
        insert testOpportunity;
    }
    
    @isTest
    static void testGetAllThePricebooksAndOpportunityProductsApex() {
        // Test the main method
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1]; // Query to get the opportunity
        DFJ_ProductSelectorForOpportunity_Apex.ProductsWrapper result =
            DFJ_ProductSelectorForOpportunity_Apex.getAllThePricebooksAndOpportunityProducts_Apex(opp.Id);
        Test.stopTest();
        
        // Validate results
        System.assertNotEquals(null, result,'result shold be null');
        System.assertNotEquals(null, result.productData,'product data should not be null');
            }
    
    @isTest
    static void testUpdateRecordsApex() {
        // Create an OpportunityLineItem
        OpportunityLineItem lineItem = new OpportunityLineItem(
            OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id,
                PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Pricebook2.IsStandard=FALSE LIMIT 1].Id,
        Quantity = 1,
        UnitPrice = 100
            );
        insert lineItem;
        
        // Modify the discount
        lineItem.Discount = 10;
        
        // Test the update method
        Test.startTest();
        DFJ_ProductSelectorForOpportunity_Apex.updateRecords_Apex(lineItem);
         DFJ_ProductSelectorForOpportunity_Apex.updateRecords_Apex(null);
        Test.stopTest();
        
        // Verify the update
        OpportunityLineItem updatedItem = [SELECT Id, Discount FROM OpportunityLineItem WHERE Id = :lineItem.Id];
        System.assertEquals(10, updatedItem.Discount,'Discount value is 10');
    }
    
    @isTest
    static void testDeleteRecordsApex() {
        // Create an OpportunityLineItem
        OpportunityLineItem lineItem = new OpportunityLineItem(
                OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id,
                PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Pricebook2.IsStandard=FALSE LIMIT 1].Id,
                Quantity = 1,
                UnitPrice = 100
        );
        insert lineItem;
        
        // Test the delete method
        Test.startTest();
        List<OpportunityLineItem> result =
            DFJ_ProductSelectorForOpportunity_Apex.deleteRecords_Apex(lineItem.Id, lineItem.OpportunityId);
        Test.stopTest();
        
        // Verify deletion
        Integer count = [SELECT COUNT() FROM OpportunityLineItem WHERE Id = :lineItem.Id];
        System.assertEquals(0, count,'count should be zero');
        System.assertNotEquals(null, result,'result should not be null');
    }

@isTest
    static void testInsertRecordsApex() {
    OpportunityLineItem lineItem = new OpportunityLineItem(
            OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Pricebook2.IsStandard=FALSE LIMIT 1].Id,
            Quantity = 1,
            UnitPrice = 100
    );
    insert lineItem;
        
        
        // Test the insertRecords method
        Test.startTest();
        List<OpportunityLineItem> result =
            DFJ_ProductSelectorForOpportunity_Apex.insertRecords_Apex( new List<OpportunityLineItem>{ lineItem });
        Test.stopTest();
        
        // Verify
        Integer count = [SELECT COUNT() FROM OpportunityLineItem WHERE Id = :lineItem.Id];
        System.assertEquals(1, count,'count should be one');
    }
    
  @isTest
    static void testUpdateOpportunity() {
        Id opportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        
        Decimal orderTotalValue = 200;
        Decimal fixedDiscountValue = 20;
        
        // Test the updateOpportunity method
        Test.startTest();
        
        DFJ_ProductSelectorForOpportunity_Apex.updateOpportunity(opportunityId, orderTotalValue, fixedDiscountValue);
        DFJ_ProductSelectorForOpportunity_Apex.updateOpportunity(null, orderTotalValue, fixedDiscountValue);
        Test.stopTest();
        
        // fetch the opportunity
        Opportunity opp = [SELECT Id, Order_Total__c, Fixed_Discount_Type__c FROM Opportunity LIMIT 1];
        
        // Verify
        
        System.assertEquals(orderTotalValue, opp.Order_Total__c,'Order total value should be updated.');
        System.assertEquals(fixedDiscountValue, opp.Fixed_Discount_Type__c,'Fixed discount value should be updated.');
    } 
    
     @isTest
    public static void testgetOrderCategorySize(){
        Account acc = new Account(Name = 'test acc');
        insert acc;
         Opportunity oppInstance = new Opportunity();
        oppInstance.Name = 'TestOpp';
        oppInstance.Market_unit__c='DFJ_DK';
        oppInstance.StageName = 'Closed Won';
        oppInstance.CloseDate = Date.Today() + 1;
        oppInstance.accountId = acc.Id;
        insert oppInstance;
        
        Order_Category_Definition__c ocd = new Order_Category_Definition__c();
        ocd.Market_Unit__c = 'DFJ_DK';
        ocd.Order_Category_Type__c = 'Product Bundle';
        ocd.Is_Active__c = true;
        insert ocd;
        
         Test.startTest();
      	Integer count =  DFJ_ProductSelectorForOpportunity_Apex.getOrderCategorySize(oppInstance.Id);
        Integer count2 =  DFJ_ProductSelectorForOpportunity_Apex.getOrderCategorySize(null);
        Test.stopTest();
        System.assertEquals(count,1,'Order category size should be 1 only');
    }
    
   /* @isTest
    static void testFetchPriceBookAndPriceBookEntry() {
        // Test the fetch method
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1]; // Query to get the opportunity
        DFJ_ProductSelectorForOpportunity_Apex.ProductsWrapper result =
            DFJ_ProductSelectorForOpportunity_Apex.fetchPriceBookAndPriceBookEntry(opp.Id);
        Test.stopTest();
        
        // Validate results
        System.assertNotEquals(null, result,'result should not be null');
        System.assertNotEquals(null, result.selectedPriceBook, 'selected priceBook should not be null');
    }*/
    
/*    @isTest
static void testFetchPriceBookAndPriceBookEntry() {
    // Step 1: Create test data
    

    // Create an Account
    Account testAccount = [select id from account limit 1];

    // Create a custom Pricebook
  id testPriceBook = test.getstandardPriceBookId();

    // Create a Product
    Product2 testProduct = new Product2(
        Name = 'Test Product',
        ProductCode = 'TP001',
        IsActive = true,
        Family = 'Test Products'
    );
    insert testProduct;

    // Create a Pricebook Entry for the Product
    PricebookEntry testPricebookEntry = new PricebookEntry(
        Pricebook2Id = testPricebook,
        Product2Id = testProduct.Id,
        UnitPrice = 100,
        IsActive = true
    );
    insert testPricebookEntry;

    // Create an Opportunity associated with the Account
    Opportunity testOpportunity = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        AccountId = testAccount.Id,
        Market_Unit__c = 'DFJ_DK'
    );
    insert testOpportunity;
    
     Currency_Configurater__mdt fetchedCurrencyConfig = Currency_Configurater__mdt.getInstance(testOpportunity.Market_Unit__c);

    // Step 2: Call the method under test
    Test.startTest();
    DFJ_ProductSelectorForOpportunity_Apex.ProductsWrapper result = DFJ_ProductSelectorForOpportunity_Apex.fetchPriceBookAndPriceBookEntry(testOpportunity.Id);
    Test.stopTest();

    // Step 3: Validate the results
    System.assertNotEquals(null, result, 'Expected ProductsWrapper to not be null.');
    System.assertNotEquals(null, result.selectedPriceBookEntries, 'Expected selectedPriceBookEntries to not be null.');
    System.assertNotEquals(null, result.selectedPriceBook, 'Expected selectedPriceBook to not be null.');
    System.assertEquals(testOpportunity.Id, result.opportunityRecordInstance.Id, 'Expected opportunity record to match.');
    System.assertEquals(testAccount.Id, result.accountRecordInstance.Id, 'Expected account record to match.');
}  */
    
   
}