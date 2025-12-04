/**
 * @description Test Class for Payment Service
 */
@isTest
public with sharing class PS_PaymentService_Test {
    
    // Test private key for mocking Reepay API calls
    private static final String TEST_PRIVATE_KEY = 'dGVzdF9wcml2YXRlX2tleQ==';
    
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
        
        // Use Test.getStandardPricebookId() to get the standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create a custom Pricebook with Internal_Identifier__c for testing
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true,
            Internal_Identifier__c = 'TEST_PB_001'
        );
        insert testPricebook;
        
        // Create a test Opportunity with pricebook
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = a.Id,
            Order_Total__c = 1000,
            Pricebook2Id = testPricebook.Id
        );
        insert testOpportunity;
        
        // Create a Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true,
            Family = 'Test Products',
            Product_Identifier__c = 'PI2'
        );
        insert testProduct;
        
        // Create a PricebookEntry for the standard pricebook
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPricebookEntry;
        
        // Create a PricebookEntry for the test pricebook
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create test LeadProducts__c with pricebook
        LeadProducts__c testLeadProduct = new LeadProducts__c(
            Lead__c = testLead.Id,
            Discount__c = 0,
            Item_Price__c = 100,
            Quantity__c = 1,
            CurrencyIsoCode = 'SEK',
            Pricebook_Id__c = testPricebook.Id,
            PricebookEntry_Id__c = testPricebookEntry.Id
        );
        insert testLeadProduct;
        
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
        // Set test private key
        PS_PaymentService.testPrivateKey = 'dGVzdF9wcml2YXRlX2tleQ==';
        
        // Create pricebook
        Pricebook2 testPb = new Pricebook2(Name = 'Test PB', IsActive = true, Internal_Identifier__c = 'TEST_INFO');
        insert testPb;
        
        Payments__c paymentRecord = new Payments__c(
            Payment_type__c = 'Credit Card',
            CurrencyIsoCode = 'DKK',
            Amount__c = 500.00,
            Refunded_Amount__c = 50.00,
            Invoice_unique_handle__c = 'INV-12345',
            Pricebook2Id__c = testPb.Id
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
        // Set test private key
        PS_PaymentService.testPrivateKey = 'dGVzdF9wcml2YXRlX2tleQ==';
        
        // Create pricebook for refund
        Pricebook2 testPb = new Pricebook2(Name = 'Test Refund PB', IsActive = true, Internal_Identifier__c = 'TEST_REFUND');
        insert testPb;
        
        Test.startTest();
        String result = PS_PaymentService.refundHandler(testPb.Id, 'test');
        Test.stopTest();
        
        System.assertEquals('An error occurred', result);
    }
    
    @isTest
    public static void refundHandlerNullPricebookTest(){
        Test.startTest();
        String result = PS_PaymentService.refundHandler(null, 'test');
        Test.stopTest();
        
        System.assertEquals('Either calloutBody or pricebookId is blank.', result);
    }
    
    @isTest
    public static void handleExpireOfSubscriptionTest(){
        // Set test private key
        PS_PaymentService.testPrivateKey = 'dGVzdF9wcml2YXRlX2tleQ==';
        
        // Create pricebook
        Pricebook2 testPb = new Pricebook2(Name = 'Test Expire PB', IsActive = true, Internal_Identifier__c = 'TEST_EXPIRE');
        insert testPb;
        
        // Create subscription
        Subscriptions__c subscription = new Subscriptions__c(
            CurrencyIsoCode = 'DKK',
            Subscription_handle__c = 'SUB-12345'
        );
        insert subscription;
        
        // Create related payment with pricebook
        Payments__c payment = new Payments__c(
            CurrencyIsoCode = 'DKK',
            Subscriptions__c = subscription.Id,
            Pricebook2Id__c = testPb.Id
        );
        insert payment;
        
        Test.startTest();
        String result = PS_PaymentService.handleExpireOfSubscription(subscription.Id, 'Subscriptions__c');
        Test.stopTest();
        
        System.assertEquals('Error occurred while doing callout for expireSubscription.', result);
    }
    
    @isTest
    public static void handleExpireOfSubscriptionNoPaymentTest(){
        // Create subscription without related payment
        Subscriptions__c subscription = new Subscriptions__c(
            CurrencyIsoCode = 'DKK',
            Subscription_handle__c = 'SUB-NO-PAYMENT'
        );
        insert subscription;
        
        Test.startTest();
        String result = PS_PaymentService.handleExpireOfSubscription(subscription.Id, 'Subscriptions__c');
        Test.stopTest();
        
        System.assertEquals('No Payment with Pricebook found for this Subscription.', result);
    }
    
    @isTest
    public static void handleCancellationOfSubscriptionTest(){
        // Set test private key
        PS_PaymentService.testPrivateKey = 'dGVzdF9wcml2YXRlX2tleQ==';
        
        // Create pricebook
        Pricebook2 testPb = new Pricebook2(Name = 'Test Cancel PB', IsActive = true, Internal_Identifier__c = 'TEST_CANCEL');
        insert testPb;
        
        // Create subscription
        Subscriptions__c subscription = new Subscriptions__c(
            CurrencyIsoCode = 'DKK',
            Subscription_handle__c = 'SUB-67890'
        );
        insert subscription;
        
        // Create related payment with pricebook
        Payments__c payment = new Payments__c(
            CurrencyIsoCode = 'DKK',
            Subscriptions__c = subscription.Id,
            Pricebook2Id__c = testPb.Id
        );
        insert payment;
        
        Test.startTest();
        String result = PS_PaymentService.handleCancellationOfSubscription(subscription.Id, 'Subscriptions__c');
        Test.stopTest();
        
        System.assertEquals('Error occurred while doing callout to cancel Subscription.', result);
    }
    
    @isTest
    public static void handleCancellationOfSubscriptionNoPaymentTest(){
        // Create subscription without related payment
        Subscriptions__c subscription = new Subscriptions__c(
            CurrencyIsoCode = 'DKK',
            Subscription_handle__c = 'SUB-NO-PAY-CANCEL'
        );
        insert subscription;
        
        Test.startTest();
        String result = PS_PaymentService.handleCancellationOfSubscription(subscription.Id, 'Subscriptions__c');
        Test.stopTest();
        
        System.assertEquals('No Payment with Pricebook found for this Subscription.', result);
    }
    
    @isTest
    public static void handleOfflineManualSettleTest(){
        // Set test private key
        PS_PaymentService.testPrivateKey = 'dGVzdF9wcml2YXRlX2tleQ==';
        
        // Create pricebook
        Pricebook2 testPb = new Pricebook2(Name = 'Test Settle PB', IsActive = true, Internal_Identifier__c = 'TEST_SETTLE');
        insert testPb;
        
        Payments__c paymentRecord = new Payments__c(
            Payment_type__c = 'Credit Card',
            CurrencyIsoCode = 'DKK',
            Amount__c = 500.00,
            Refunded_Amount__c = 50.00,
            Invoice_unique_handle__c = 'INV-12345',
            Pricebook2Id__c = testPb.Id
        );
        insert paymentRecord;
        
        Test.startTest();
        String result = PS_PaymentService.handleOfflineManualSettle(paymentRecord.Id, 'test');
        Test.stopTest();
        
        System.assertEquals('Offline Manual Settle failed.', result);
    }
    
    @isTest
    public static void handleOfflineManualSettleNoPricebookTest(){
        Payments__c paymentRecord = new Payments__c(
            Payment_type__c = 'Credit Card',
            CurrencyIsoCode = 'DKK',
            Amount__c = 500.00
        );
        insert paymentRecord;
        
        Test.startTest();
        String result = PS_PaymentService.handleOfflineManualSettle(paymentRecord.Id, 'test');
        Test.stopTest();
        
        System.assertEquals('Pricebook not set on Payment record.', result);
    }
    
    @isTest
    public static void getReepayPrivateKeyByPricebookTest(){
        // Create pricebook
        Pricebook2 testPb = new Pricebook2(Name = 'Test Key PB', IsActive = true, Internal_Identifier__c = 'TEST_KEY');
        insert testPb;
        
        // Set test private key
        PS_PaymentService.testPrivateKey = 'dGVzdF9wcml2YXRlX2tleQ==';
        
        Test.startTest();
        String result = PS_PaymentService.getReepayPrivateKeyByPricebook(testPb.Id);
        Test.stopTest();
        
        System.assertEquals('dGVzdF9wcml2YXRlX2tleQ==', result);
    }
    
    @isTest
    public static void getReepayPrivateKeyByPricebookNullTest(){
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            PS_PaymentService.getReepayPrivateKeyByPricebook(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            // Exception is expected
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    
    @isTest
    public static void handleExpireWrongObjectTest(){
        Test.startTest();
        String result = PS_PaymentService.handleExpireOfSubscription(null, 'Account');
        Test.stopTest();
        
        System.assertEquals('Either recordId or objectApiName is blank.', result);
    }
    
    @isTest
    public static void handleCancellationWrongObjectTest(){
        Test.startTest();
        String result = PS_PaymentService.handleCancellationOfSubscription(null, 'Account');
        Test.stopTest();
        
        System.assertEquals('Either recordId or objectApiName is blank.', result);
    }
    //Changes DFJ-318 End
}