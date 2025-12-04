/**
 * @description Test Class for Payment Service
 */
@isTest
public with sharing class PS_PaymentService_Test {
    
    @testSetup
    static void testCreatePaymentRecord() {
        // Step 1: Create test data
             
        // Create a test Account
        Id accountRecordTypeId = [SELECT Id,Name,DeveloperName FROM RecordType WHERE SObjectType = 'Account' and DeveloperName = 'PersonAccount' LIMIT 1].Id;
        
        Account a = new Account();
        //	a.Name = 'Doe';
        a.LastName = 'doe';
        a.RecordTypeId = accountRecordTypeId;
        a.PersonEmail = 'test@test.com';
        insert a;

        // Create a test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'testlead@example.com',
            Company = 'Test Company',
            CurrencyIsoCode = 'SEK',
            Provider_id__c = '2342'
        );
        insert testLead;
        
        // Create a test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = a.Id,
            Order_Total__c = 1000
        );
        insert testOpportunity;
        
        // Create test LeadProducts__c
        LeadProducts__c testLeadProduct = new LeadProducts__c(
            Lead__c = testLead.Id,
            Discount__c = 0,
            Item_Price__c = 100,
            Quantity__c = 1,
            CurrencyIsoCode = 'SEK'
        );
        insert testLeadProduct;
        
        // Use Test.getStandardPricebookId() to get the standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create a Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true,
            Family = 'Test Products',
                Product_Identifier__c = 'PI2'
        );
        insert testProduct;
        
        // Create a PricebookEntry for the Product
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert oli;
    }
    
    @isTest
    static void testcreatePaymentRecordforOpportunity() {
        // Step 4: Call the method under test for Opportunity
        Test.startTest();
        Opportunity testOpportunity1 = [SELECT Id FROM Opportunity LIMIT 1];
        PS_PaymentUtility.PaymentWrapper opportunityResult = PS_PaymentService.createPaymentRecord(testOpportunity1.Id);
        Test.stopTest();
        
        // Step 5: Validate results for Opportunity
        System.assertNotEquals(
            null,
            opportunityResult,
            'Expected opportunityResult to not be null.'
        );
        System.assertEquals(
            'Created successfully.',
            opportunityResult.successMessage,
            'Expected success message to match.'
        );
        System.assertNotEquals(
            null,
            opportunityResult.payment,
            'Expected payment to not be null.'
        );
        System.assertEquals(
            [SELECT Id, Order_Total__c FROM Opportunity].Order_Total__c,
            opportunityResult.payment.Amount__c,
            'Expected payment amount to match the opportunity total.'
        );
        System.assertEquals(
            [SELECT Id, PersonEmail FROM Account].PersonEmail,
            opportunityResult.payment.Billing_email__c,
            'Expected billing email to match the account email.'
        );
        
    }
    
    @isTest
    static void createPaymentRecordLeadWithoutEmail() {
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'xyz',
            Provider_Id__c = 'testProviderid12'
        );
        insert testLead;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentService.createPaymentRecord(testLead.Id);
        Test.stopTest();
        
        System.assertEquals(
            'Please populate the email',
            paymentRelatedWrapperInstance.errorMessage,
            'Test Failed: createPaymentRecordLeadWithoutEmail'
        );
    }
    
    @isTest
    static void createPaymentRecordOrderWithoutEmail() {
        Account testAccount = new Account(Name = 'test Account');
        insert testAccount;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'DRAFT',
            EffectiveDate = Date.today()
        );
        insert testOrder;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentService.createPaymentRecord(testOrder.Id);
        Test.stopTest();
        
        System.assertEquals(
            'Please populate the email',
            paymentRelatedWrapperInstance.errorMessage,
            'Test Failed: createPaymentRecordOrderWithoutEmail'
        );
    }
    
    @isTest
    static void createPaymentRecordWithoutLeadOrOrder() {
        Account testAccount = new Account(Name = 'test Account');
        insert testAccount;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentService.createPaymentRecord(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(
            'Component not placed on Lead, Order or Opportunity',
        paymentRelatedWrapperInstance.errorMessage,
        'Test Failed: createPaymentRecordWithoutLeadOrOrder'
            );
    }
    
    @isTest
    static void testCreatePaymentRecordOnAccount() {
        // Use Test.getStandardPricebookId() to get the standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create a Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true,
            Family = 'Test Products',
                Product_Identifier__c = 'PI1'
        );
        insert testProduct;
        
        // Create a PricebookEntry for the Product
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create an Account with a valid email
        Id accountRecordTypeId = [SELECT Id,Name,DeveloperName FROM RecordType WHERE SObjectType = 'Account' and DeveloperName = 'PersonAccount' LIMIT 1].Id;
        
        Account testAccount = new Account();
        //	a.Name = 'Doe';
        testAccount.LastName = 'doe';
        testAccount.RecordTypeId = accountRecordTypeId;
        testAccount.PersonEmail = 'test@test.com';
        testAccount.Market_Unit__c = 'Testamente_DK';
        insert  testAccount;
        
        // Create an Order associated with the Account
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            Pricebook2Id = standardPricebookId,
            EffectiveDate = Date.today()
        );
        insert testOrder;
        
        // Create OrderItems associated with the Order
        List<OrderItem> orderItems = new List<OrderItem>{
            new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = testPricebookEntry.Id,
                Quantity = 1,
                UnitPrice = 100
            ),
                new OrderItem(
                    OrderId = testOrder.Id,
                    
                    PricebookEntryId = testPricebookEntry.Id,
                    Quantity = 1,
                    UnitPrice = 200
                )
                };
                    insert orderItems;
        
        //Changes DFJ-318 Start
        Journal__c journal = new Journal__c(DocFab_Record_Model_ID__c = '54',
                                            Type__c = 'Inheritance',
                                            Account__c = testAccount.Id);
        insert journal;
        //Changes DFJ-318 End
        
        // Prepare test parameters
        String orderProductList = JSON.serialize(orderItems);
        Decimal orderFixedDisc = 0;
        Decimal totalOrder = 300;
        
        //Changes DFJ-318 Start
        String selectedJournal = journal.Id;
        //String selectedJournal = 'some_journal_id'; // Replace with an actual Journal Id
        
        df_journal_dk__c jour = new df_journal_dk__c(Journal__c = selectedJournal,
                                                    person_1_address__c = 'test1',
                                                    person_1_city__c = 'California',
                                                    person_1_zip_code__c = '121125');
        insert jour;
        //Changes DFJ-318 End
        
        // Call the method to test
        PS_PaymentUtility.PaymentWrapper result = PS_PaymentService.createPaymentRecordOnAccount(
            testAccount.Id,
            testOrder,
            orderProductList,
            orderFixedDisc,
            totalOrder,
            selectedJournal
        );
        
        // Assertions
        System.assertEquals('Created successfully.', result.successMessage, 'Expected success message not returned.');
        System.assertNotEquals(null, result.payment, 'Payment record was not created.');
        System.assertEquals(2, result.paymentOrderLines.size(), 'Expected two payment order lines to be created.');
    }
    
    //Changes DFJ-318 Start
    @isTest
    public static void getPaymentInfoTest(){
        Payments__c paymentRecord = new Payments__c(
            Payment_type__c = 'Credit Card',
            CurrencyIsoCode = 'DKK',
            Amount__c = 500.00,
            Refunded_Amount__c = 50.00,
            Invoice_unique_handle__c = 'INV-12345'
        );
        insert paymentRecord;
        
        // Create Payment Order Line linked to the above Payment
        Payment_order_line__c paymentOrderLine = new Payment_order_line__c(
            Name = 'Test Order Line',
            Quantity__c = 2,
            Amount__c = 250.00,
            Payments__c = paymentRecord.Id
        );
        insert paymentOrderLine;
        PS_PaymentUtility.PaymentInfo payments = PS_PaymentService.getPaymentInfo(paymentRecord.Id, 'Payments__c');
        System.assertEquals(paymentRecord.CurrencyIsoCode, payments.currencyIsoCode);
        System.assertEquals(paymentRecord.Payment_type__c, payments.paymentType);
    }
    
    @isTest
    public static void refundHandlerTest(){
        String result = PS_PaymentService.refundHandler('DKK','test');
        System.assertEquals('An error occurred', result);
    }
    
    @isTest
    public static void handleExpireOfSubscriptionTest(){
        Subscriptions__c subscription = new Subscriptions__c(
            CurrencyIsoCode = 'DKK',
            Subscription_handle__c = 'SUB-12345'
        );
        insert subscription;
        String result = PS_PaymentService.handleExpireOfSubscription(subscription.Id,'Subscriptions__c');
        System.assertEquals('Error occurred while doing callout for expireSubscription.', result);
    }
    
    @isTest
    public static void handleCancellationOfSubscriptionTest(){
        Subscriptions__c subscription = new Subscriptions__c(
            CurrencyIsoCode = 'DKK',
            Subscription_handle__c = 'SUB-12345'
        );
        insert subscription;
        String result = PS_PaymentService.handleCancellationOfSubscription(subscription.Id,'Subscriptions__c');
        System.assertEquals('Error occurred while doing callout to cancel Subscription.', result);
    }
    
    @isTest
    public static void handleOfflineManualSettleTest(){
        Payments__c paymentRecord = new Payments__c(
            Payment_type__c = 'Credit Card',
            CurrencyIsoCode = 'DKK',
            Amount__c = 500.00,
            Refunded_Amount__c = 50.00,
            Invoice_unique_handle__c = 'INV-12345'
        );
        insert paymentRecord;
        String result = PS_PaymentService.handleOfflineManualSettle(paymentRecord.Id, 'test');
        System.assertEquals('Offline Manual Settle failed.', result);
    }
    //Changes DFJ-318 End
}