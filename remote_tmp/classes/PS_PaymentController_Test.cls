/**
 * @description Test class for Payment Controller
 */
@isTest public with sharing class PS_PaymentController_Test {
    @isTest static void createPaymentRecordLeadWithoutEmail() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12');
        insert testLead;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testLead.Id);
        Test.stopTest();
        System.assertEquals('Please populate the email', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: createPaymentRecordLeadWithoutEmail');
    }
    
    @isTest static void createPaymentRecordOrderWithoutEmail() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        Account testAccount = new Account(Name = 'test Account');
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testOrder.Id);
        Test.stopTest();
        System.assertEquals('Please populate the email', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: createPaymentRecordOrderWithoutEmail');
    }
    
    @isTest static void createPaymentRecordWithoutLeadOrOrder() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Account testAccount = new Account(Name = 'test Account');
        insert testAccount;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testAccount.Id);
        Test.stopTest();
        System.assertEquals('Component not placed on Lead, Order or Opportunity', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: createPaymentRecordWithoutLead, Order or Opportunity');
    }
    
    @isTest static void createPaymentRecordLeadInvoicePresent() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test@gmail.com');
        insert testLead;
        
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, Invoice_created__c = true);
        insert testPayment;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testLead.Id);
        Test.stopTest();
        System.assertEquals('Payment already present.', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: createPaymentRecordLeadInvoicePresent');
    }
    
    @isTest static void createPaymentRecordOrderInvoicePresent() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'xyz@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        Payments__c testPayment = new Payments__c(Order__c = testOrder.Id, Invoice_created__c = true);
        insert testPayment;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testOrder.Id);
        Test.stopTest();
        System.assertEquals('Payment already present.', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: createPaymentRecordOrderInvoicePresent');
    }
    
    @isTest static void createPaymentRecordLeadInvoiceNotPresent() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test@gmail.com');
        insert testLead;
        
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, Amount__c = 0);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id, Item_Price__c = 100, Discount__c= 0, CurrencyIsoCode = 'DKK', Quantity__c = 1, Plan_handle__c='FitnessPlan01');
        insert testLeadProduct;
        
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testLead.Id);
        Test.stopTest();
        System.assertEquals(testPayment.Id, paymentRelatedWrapperInstance.payment.Id, 'Test Failed: createPaymentRecordLeadInvoiceNotPresent, Payment');
        System.assertEquals(1, paymentRelatedWrapperInstance.paymentOrderLines.size(), 'Test Failed: createPaymentRecordLeadInvoiceNotPresent, paymentOrderLines');
        System.assertEquals('Created successfully.', paymentRelatedWrapperInstance.successMessage, 'Test Failed: createPaymentRecordLeadInvoiceNotPresent');
    }
    
    @isTest static void createPaymentRecordOrderInvoiceNotPresent() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'xyz@gmail.com', RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        Payments__c testPayment = new Payments__c(Order__c = testOrder.Id, Amount__c = 1000);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testOrder.Id);
        Test.stopTest();
        System.assertEquals(testPayment.Id, paymentRelatedWrapperInstance.payment.Id, 'Test Failed: createPaymentRecordOrderInvoiceNotPresent, Payment');
        System.assertEquals(1, paymentRelatedWrapperInstance.paymentOrderLines.size(), 'Test Failed: createPaymentRecordOrderInvoiceNotPresent, paymentOrderLines');
        System.assertEquals('Created successfully.', paymentRelatedWrapperInstance.successMessage, 'Test Failed: createPaymentRecordOrderInvoiceNotPresent');
    }
    
    @isTest static void createPaymentRecordLeadPaymentNotPresent() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test@gmail.com');
        insert testLead;
        
        // LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id);
        // insert testLeadProduct;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testLead.Id);
        Test.stopTest();
        System.assertEquals('Please add the lead product first', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: createPaymentRecordLeadPaymentNotPresent');
    }
    
    @isTest static void createPaymentRecordOrderPaymentNotPresent() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'xyz@gmail.com', RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        // OrderItem testOrderItem = new OrderItem(OrderId = testOrder.Id, UnitPrice = 100, Quantity = 2);
        // insert testOrderItem;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testOrder.Id);
        Test.stopTest();
        System.assertEquals('Please add the order products first', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: createPaymentRecordOrderPaymentNotPresent');
    }
    
    @isTest static void createPaymentRecordLeadWithProductPaymentNotPresent() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test@gmail.com');
        insert testLead;
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id, Discount__c = 0, Item_Price__c = 100, Quantity__c = 1);
        insert testLeadProduct;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testLead.Id);
        Test.stopTest();
    }
    
    @isTest static void createPaymentRecordOrderWithProductPaymentNotPresent() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'xyz@gmail.com', RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        // OrderItem testOrderItem = new OrderItem(OrderId = testOrder.Id, UnitPrice = 100, Quantity = 2);
        // insert testOrderItem;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecord(testOrder.Id);
        Test.stopTest();
        System.assertEquals('Please add the order products first', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: createPaymentRecordOrderWithProductPaymentNotPresent');
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceLeadWithoutMail() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12');
        insert testLead;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testLead.Id,  '', '', new List<LeadProducts__c>());
        Test.stopTest();
        System.assertEquals('Unable to fetch lead record', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: makeCalloutToCreateCustomerInvoiceLeadWithoutMail');
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceOrderWithoutMail() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Account testAccount = new Account(Name = 'test Account');
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        Payments__c testPayment = new Payments__c(Order__c = testOrder.Id);
        insert testPayment;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testOrder.Id,  '', '', new List<LeadProducts__c>());
        Test.stopTest();
        System.assertEquals('Unable to fetch order record', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: makeCalloutToCreateCustomerInvoiceOrderWithoutMail');
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceLeadWithMailSuccess() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test@gmail.com');
        insert testLead;
        
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Amount__c = 100);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id, CurrencyIsoCode = 'DKK', Quantity__c = 1, Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id,Discount__c = 0, Item_Price__c = 100,CurrencyIsoCode = 'DKK', Quantity__c = 1,  Plan_handle__c = 'FitnessPlan01');
        insert testLeadProduct;
        List<LeadProducts__c> leadProductList = new List<LeadProducts__c>();
        leadProductList.add(testLeadProduct);
        //insert leadProductList;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        request.requestURI = 'https://api.reepay.com/v1/customer/test@gmail.com';
        request.httpMethod = 'GET';
        //request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testLead.Id,  JSON.serialize(testPayment), JSON.serialize(polList), leadProductList);
        Test.stopTest();
    }
    
    @isTest
    static void makeCalloutToCreateCustomerInvoiceForOppProductsSuccess() {
        // Setup test configuration
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Product2 prod = new Product2(name = 'testProd', isActive = true,Product_Identifier__c = 'PI1');
        insert prod;
        
        // Create a PricebookEntry for the standard pricebook
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = prod.Id,
        UnitPrice = 100,
        IsActive = true
            );
        insert standardPricebookEntry;
        
        // Create a test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30),
        AccountId = testAccount.Id,
        Pricebook2Id = Test.getStandardPricebookId()
            );
        insert testOpportunity;
        
        // Create a test OpportunityLineItem
        OpportunityLineItem testLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
        Product2Id = prod.Id, // Use an existing product
        Quantity = 1,
        UnitPrice = 100,
        pricebookentryid = standardPricebookEntry.id
            );
        insert testLineItem;
        
        // Create a test Payment record
        Payments__c testPayment = new Payments__c(
            Opportunity__c = testOpportunity.Id, // Assuming there is a field linking Payments to Opportunities
        CurrencyIsoCode = 'DKK',
        BillingCity__c = 'Jalandhar',
        Billing_name__c = 'Test',
        Billing_email__c = 'carl@leone.com',
        BillingState__c = 'Punjab',
        Billing_PostalCode__c = '144201',
        Amount__c = 100
            );
        insert testPayment;
        
        // Create a test Payment Order Line
        Payment_order_line__c testPol = new Payment_order_line__c(
            Name = 'Test Pol',
        Payments__c = testPayment.Id,
        CurrencyIsoCode = 'DKK',
        Quantity__c = 1,
        Amount__c = 100
            );
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        // Prepare the mock HTTP callout
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        request.requestURI = 'https://api.reepay.com/v1/customer/test@gmail.com';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the method to test
        Test.startTest();
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance =
            PS_PaymentController.makeCalloutToCreateCustomerInvoiceForOppProducts(
            testOpportunity.Id,
        JSON.serialize(testPayment),
        JSON.serialize(polList),
        new List<OpportunityLineItem> { testLineItem } // Pass the created OpportunityLineItem
        );
        Test.stopTest();
        
        // Add assertions to validate results if necessary
        System.assertNotEquals(null, paymentRelatedWrapperInstance, 'PaymentWrapper should not be null');
        //System.assertEquals(null, paymentRelatedWrapperInstance.errorMessage, 'There should be no error message');
    }
    
    
    @isTest static void makeCalloutToCreateCustomerInvoiceLeadWithMailNotFound() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test1@gmail.com');
        insert testLead;
        
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Amount__c = 0);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id, CurrencyIsoCode = 'DKK',Quantity__c = 1,Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Plan_handle__c='FitnessPlan01',Name = 'Test Lead Product', Lead__c = testLead.Id, Item_Price__c = 100, Discount__c= 0, CurrencyIsoCode = 'DKK', Quantity__c = 1);
        insert testLeadProduct;
        
        List<LeadProducts__c> leadProductList = new List<LeadProducts__c>();
        leadProductList.add(testLeadProduct);
        
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        request.requestURI = 'https://api.reepay.com/v1/customer/test1@gmail.com';
        request.httpMethod = 'GET';
        //request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testLead.Id,  JSON.serialize(testPayment), JSON.serialize(polList), leadProductList);
        Test.stopTest();
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceLeadWithMailOther() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test2@gmail.com');
        insert testLead;
        
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Amount__c = 1000);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id, CurrencyIsoCode = 'DKK',Quantity__c = 1,Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id, Item_Price__c = 100, Discount__c = 0, CurrencyIsoCode = 'DKK', Quantity__c = 1);
        
        List<LeadProducts__c> leadProductList = new List<LeadProducts__c>();
        leadProductList.add(testLeadProduct);
        insert leadProductList;
        
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = 'https://api.reepay.com/v1/customer/test2@gmail.com';
        request.httpMethod = 'GET';
        //request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        paymentRelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testLead.Id,  JSON.serialize(testPayment), JSON.serialize(polList), leadProductList);
        Test.stopTest();
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceOrderWithMailSuccess() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        Payments__c testPayment = new Payments__c(Order__c = testOrder.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Amount__c = 1000);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id,Quantity__c = 1,Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        
        PS_PaymentUtility.PaymentWrapper paymentelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        request.requestURI = 'https://api.reepay.com/v1/customer/test@gmail.com';
        request.httpMethod = 'GET';
        //request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        Test.startTest();
        paymentelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testOrder.Id,  JSON.serialize(testPayment), JSON.serialize(polList), new List<LeadProducts__c>());
        Test.stopTest();
        // System.assertEquals(200, paymentRelatedWrapperInstance., 'Status code error');
        
        //System.assertEquals('Unable to fetch order record', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: makeCalloutToCreateCustomerInvoiceOrderWithoutMail');
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceOrderWithMailNotFound() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test1@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        Payments__c testPayment = new Payments__c(Order__c = testOrder.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201',Amount__c = 0);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id,Quantity__c = 1,Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        PS_PaymentUtility.PaymentWrapper paymentelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        request.requestURI = 'https://api.reepay.com/v1/customer/test1@gmail.com';
        request.httpMethod = 'GET';
        //request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        Test.startTest();
        paymentelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testOrder.Id,  JSON.serialize(testPayment), JSON.serialize(polList), new List<LeadProducts__c>());
        Test.stopTest();
        // System.assertEquals(200, paymentRelatedWrapperInstance., 'Status code error');
        
        //System.assertEquals('Unable to fetch order record', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: makeCalloutToCreateCustomerInvoiceOrderWithoutMail');
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceOrderWithMailOther() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        Payments__c testPayment = new Payments__c(Order__c = testOrder.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201');
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id, Amount__c = 100, Quantity__c = 1);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        
        PS_PaymentUtility.PaymentWrapper paymentelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        request.requestURI = 'https://api.reepay.com/v1/customer/test2@gmail.com';
        request.httpMethod = 'GET';
        //request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        Test.startTest();
        paymentelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testOrder.Id,  JSON.serialize(testPayment), JSON.serialize(testPol), new List<LeadProducts__c>());
        Test.stopTest();
        // System.assertEquals(200, paymentRelatedWrapperInstance., 'Status code error');
        
        //System.assertEquals('Unable to fetch order record', paymentRelatedWrapperInstance.errorMessage, 'Test Failed: makeCalloutToCreateCustomerInvoiceOrderWithoutMail');
    }
    
    @isTest static void getPaymentRecordsForStatusLead() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test2@gmail.com');
        insert testLead;
        
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK');
        insert testPayment;
        
        PS_PaymentUtility.PaymentStatusWrapper paymentStatusWrapperInstance = new PS_PaymentUtility.PaymentStatusWrapper();
        Test.startTest();
        paymentStatusWrapperInstance = PS_PaymentController.getPaymentRecordsForStatus(testLead.Id);
        Test.stopTest();
        System.assertEquals('Found the payments', paymentStatusWrapperInstance.successMessage, 'Assert Fails: getPaymentRecordsForStatusLead');
    }
    
    @isTest static void getPaymentRecordsForStatusOrder() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        Payments__c testPayment = new Payments__c(Order__c = testOrder.Id, CurrencyIsoCode = 'DKK');
        insert testPayment;
        
        
        PS_PaymentUtility.PaymentStatusWrapper paymentStatusWrapperInstance = new PS_PaymentUtility.PaymentStatusWrapper();
        Test.startTest();
        paymentStatusWrapperInstance = PS_PaymentController.getPaymentRecordsForStatus(testOrder.Id);
        Test.stopTest();
        System.assertEquals('Found the payments', paymentStatusWrapperInstance.successMessage, 'Assert Fails: getPaymentRecordsForStatusOrder');
    }
    
    @isTest static void getPaymentRecordsForStatusLeadNoPayment() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test2@gmail.com');
        insert testLead;
        
        //Chnages TCS-16
        //Start
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK',Status__c = 'Refunded');
        insert testPayment;
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id, Item_Price__c = 100, Discount__c = 0, CurrencyIsoCode = 'DKK',Quantity__c = 1,Plan_handle__c = 'FitnessPlan01');
        insert testLeadProduct;
        
        //End
        PS_PaymentUtility.PaymentStatusWrapper paymentStatusWrapperInstance = new PS_PaymentUtility.PaymentStatusWrapper();
        Test.startTest();
        paymentStatusWrapperInstance = PS_PaymentController.getPaymentRecordsForStatus(testLead.Id);
        Test.stopTest();
        System.assertEquals('No payment found', paymentStatusWrapperInstance.successMessage, 'Assert Fails: getPaymentRecordsForStatusLeadNoPayment');
    }
    
    @isTest static void getPaymentRecordsForStatusOrderNoPayment() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today());
        insert testOrder;
        
        PS_PaymentUtility.PaymentStatusWrapper paymentStatusWrapperInstance = new PS_PaymentUtility.PaymentStatusWrapper();
        Test.startTest();
        paymentStatusWrapperInstance = PS_PaymentController.getPaymentRecordsForStatus(testOrder.Id);
        Test.stopTest();
        System.assertEquals('No payment found', paymentStatusWrapperInstance.successMessage, 'Assert Fails: getPaymentRecordsForStatusOrderNoPayment');
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceOrderWithOtherMail() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        // Insert Product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        p.Product_Identifier__c = 'PI2';
        insert p;
        
        
        Id pricebookId = Test.getStandardPricebookId();
        
        // Insert PricebookEntry
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        // Insert Order
        
        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = testAccount.id;
        o.Pricebook2Id =  pricebookId ;
        
        insert o;
        
        // Insert Order Item
        
        OrderItem i = new OrderItem();
        i.OrderId = o.id;
        i.Quantity = 24;
        i.UnitPrice = 240;
        i.Product2id = p.id;
        i.PricebookEntryId=standardPrice.id;
        i.Discount__c = 10;
        insert i;
        
        PS_PaymentUtility.PaymentWrapper paymentelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        Test.startTest();
        paymentelatedWrapperInstance = PS_PaymentController.createPaymentRecord(o.Id);
        Test.stopTest();
    }
    
    @isTest static void createPaymentRecordException() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Test.startTest();
        PS_PaymentController.createPaymentRecord(null);
        Test.stopTest();
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceException() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Test.startTest();
        PS_PaymentController.makeCalloutToCreateCustomerInvoice(null, '', '', null);
        Test.stopTest();
    }
    
    
    @isTest static void getPaymentRecordsForStatusException() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Test.startTest();
        PS_PaymentController.getPaymentRecordsForStatus(null);
        Test.stopTest();
    }
    
    @isTest static void handleCompoentDebugLogsError_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Test.startTest();
        PS_PaymentController.handleCompoentDebugLogs('', 'message', 'severity', 'source');
        Test.stopTest();
    }
    
    @isTest static void handleCompoentDebugLogs_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Test.startTest();
        Boolean result = PS_PaymentController.handleCompoentDebugLogs('test event', 'Error message', 'Error', 'Test class method');
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest static void cancelPaymentTest() {
        
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test2@gmail.com', Fixed_Discount_Type__c = 0);
        insert testLead;
        
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201');
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id, CurrencyIsoCode = 'DKK',Quantity__c = 1,Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id, Item_Price__c = 100, Discount__c = 0, CurrencyIsoCode = 'DKK',Quantity__c = 1,Plan_handle__c = 'FitnessPlan01');
        insert testLeadProduct;
        
        PS_PaymentUtility.PaymentStatusWrapper paymentStatusWrapperInstance = new PS_PaymentUtility.PaymentStatusWrapper();
        Test.startTest();
        String cancelStatus = PS_PaymentController.cancelPayment(testLead.Id, testPayment.Id);
        Test.stopTest();
        // System.assertEquals('Found the payments', paymentStatusWrapperInstance.successMessage, 'Assert Fails: getPaymentRecordsForStatusLead');
    }
    
    @isTest static void cancelSubscription() {
        
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test2@gmail.com', Fixed_Discount_Type__c = 0);
        insert testLead;
        
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Status__c = 'Refunded');
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id, CurrencyIsoCode = 'DKK',Quantity__c = 1,Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id, Item_Price__c = 100, Discount__c = 0, Quantity__c = 1);
        insert testLeadProduct;
        
        PS_PaymentUtility.PaymentStatusWrapper paymentStatusWrapperInstance = new PS_PaymentUtility.PaymentStatusWrapper();
        Test.startTest();
        String isCancelled = PS_PaymentService.cancelInvoiceFromId(testLead.Id, 'DKK');
        Test.stopTest();
        // System.assertEquals('Found the payments', paymentStatusWrapperInstance.successMessage, 'Assert Fails: getPaymentRecordsForStatusLead');
    }
    
    @isTest static void getAddressInfoFromLeadOROrder_Test() {
        
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today(), ShippingCity ='Jal');
        insert testOrder;
        
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test2@gmail.com',PostalCode = '144201', Street='123 Secret Street', City = 'Jal',Country = 'IN');
        insert testLead;
        
        Journal__c journal = new Journal__c(External_record_uuid__c='8f162afe-7be7-44c0-980d-e08aed3757ad', Lead__c = testLead.Id);
        insert journal;
        
        df_journal_dk__c journalDK = new df_journal_dk__c();
        journalDK.Journal__c = journal.Id;
        journalDK.person_1_address__c = '122 Secret Screet';
        journalDK.person_1_city__c = 'Jal';
        journalDK.uuid__c = '8f162afe-7be7-44c0-980d-e08aed3757ad';
        insert journalDK;
        
        PS_PaymentUtility.PS_AddressInfoWrapper addressInfoWrapper = new PS_PaymentUtility.PS_AddressInfoWrapper();
        Test.startTest();
        addressInfoWrapper = PS_PaymentController.getAddressInfoFromLeadOROrder('');
        addressInfoWrapper = PS_PaymentController.getAddressInfoFromLeadOROrder(testLead.Id);
        Test.stopTest();
        
        
    }
    
    @isTest static void getAddressInfoFromLeadOROrder_Test1() {
        
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, Status = 'DRAFT', EffectiveDate = Date.today(), ShippingCity ='Jal');
        insert testOrder;
        
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12',Country = 'IN');
        insert testLead;
        
        Journal__c journal = new Journal__c(External_record_uuid__c='8f162afe-7be7-44c0-980d-e08aed3757ad', Lead__c = testLead.Id);
        insert journal;
        
        df_journal_dk__c journalDK = new df_journal_dk__c();
        journalDK.Journal__c = journal.Id;
        journalDK.person_1_address__c = '122 Secret Screet';
        journalDK.person_1_city__c = 'Jal';
        journalDK.uuid__c = '8f162afe-7be7-44c0-980d-e08aed3757ad';
        journalDK.person_1_email__c = 'test@gmaul.com';
        insert journalDK;
        
        PS_PaymentUtility.PS_AddressInfoWrapper addressInfoWrapper = new PS_PaymentUtility.PS_AddressInfoWrapper();
        Test.startTest();
        addressInfoWrapper = PS_PaymentController.getAddressInfoFromLeadOROrder(testLead.Id);
        Test.stopTest();
        
        
    }
    
    //DFJ-80
    @isTest static void createPaymentRecordOnAccount_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12');
        insert testLead;
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType);
        insert testAccount;
        
        // Insert Product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        p.Product_Identifier__c = 'PI5';
        insert p;
        
        
        Id pricebookId = Test.getStandardPricebookId();
        
        // Insert PricebookEntry
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        // Insert Order
        
        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = testAccount.id;
        o.Pricebook2Id =  pricebookId ;
        
        //   insert o;
        
        // Insert Order Item
        List<OrderItem> orderItemList = new List<OrderItem>();
        OrderItem i = new OrderItem();
        i.OrderId = o.id;
        i.Quantity = 24;
        i.UnitPrice = 240;
        i.Product2id = p.id;
        i.PricebookEntryId=standardPrice.id;
        orderItemList.add(i);
        // insert i;
        
        Decimal orderFixedDisc = 10;
        Decimal totalOrder = 100;
        List<Journal__c> getJournal = new List<Journal__c>();
        Journal__c newJournal = new Journal__c();
        newJournal.Lead__c = testLead.Id;
        newJournal.DocFab_Record_Model_ID__c = '54';
        newJournal.External_record_uuid__c = '1234';
        newJournal.Contains_Custom_Documents__c = false;
        newJournal.Account__c = testAccount.Id;
        getJournal.add(newJournal);
        insert newJournal;
        
        df_journal_dk__c testjournaldk = new df_journal_dk__c();
        testjournaldk.Journal__c = getJournal[0].Id;
        testjournaldk.uuid__c = '1234';
        testjournaldk.person_1_cpr__c = 'test';
        testjournaldk.person_1_first_name__c = 'abc';
        testjournaldk.person_1_last_name__c = 'tset';
        testjournaldk.person_2_first_name__c = 'Test2';
        testjournaldk.person_2_last_name__c = 'test';
        testjournaldk.person_1_email__c = 'abc@abc.com';
        testjournaldk.person_1_phone__c = '1234';
        testjournaldk.person_2_email__c = 'abc@abc.com';
        testjournaldk.person_2_phone__c = '234567';
        testjournaldk.nsker_medlemskab_person_1__c = true;
        testjournaldk.nsker_medlemskab_person_2__c =true;
        testjournaldk.person_1_address__c = '122 Secret Screet';
        testjournaldk.person_1_city__c = 'Jal';
        insert testjournaldk;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.createPaymentRecordOnAccount(testAccount.Id,o,JSON.serialize(orderItemList),orderFixedDisc,totalOrder,getJournal[0].Id);
        Test.stopTest();
        List<Payments__c> getPaymentOnAcc =  [SELECT Id FROM Payments__c WHERE Account__c=:testAccount.Id];
        System.assertEquals(1, getPaymentOnAcc.size());
    }
    
    
    @isTest static void getUpdatedPayment_Test() {
        Payments__c record = new Payments__c();
        record.Status__c = 'Pending';
        record.BillingStreet__c = 'testaddress';
        record.Billing_PostalCode__c = '123';
        record.BillingCity__c = 'test city';
        record.CurrencyIsoCode = 'DKK';
        record.BillingCountry__c = 'DKK';
        record.Billing_name__c = 'Test';
        record.Amount__c = 1000;
        insert record;
        Payments__c updatedRecord = new Payments__c();
        updatedRecord.Status__c = 'Accepted';
        updatedRecord.Id = record.Id;
        update updatedRecord;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.getUpdatedPayment(record.Id);
        Test.stopTest();
        List<Payments__c> getPaymentOnAcc =  [SELECT Id,Status__c FROM Payments__c WHERE Id=:record.Id];
        System.assertEquals('Accepted', getPaymentOnAcc[0].Status__c);
    }
    @isTest static void getUpdatedPayment_Test2() {
        Payments__c record = new Payments__c();
        record.Status__c = 'Pending';
        record.BillingStreet__c = 'testaddress';
        record.Billing_PostalCode__c = '123';
        record.BillingCity__c = 'test city';
        record.CurrencyIsoCode = 'DKK';
        record.BillingCountry__c = 'DKK';
        record.Billing_name__c = 'Test';
        record.Amount__c = 1000;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.getUpdatedPayment(record.Id);
        Test.stopTest();
        List<Payments__c> getPaymentOnAcc =  [SELECT Id,Status__c FROM Payments__c WHERE Id=:record.Id];
        System.assertEquals(0, getPaymentOnAcc.size());
    }
    
    
    @isTest static void showPaymentStatusOnAccount_Test() {
        Payments__c record = new Payments__c();
        record.Status__c = 'Pending';
        record.BillingStreet__c = 'testaddress';
        record.Billing_PostalCode__c = '123';
        record.BillingCity__c = 'test city';
        record.CurrencyIsoCode = 'DKK';
        record.BillingCountry__c = 'DKK';
        record.Billing_name__c = 'Test';
        record.Amount__c = 1000;
        insert record;
        Payments__c updatedRecord = new Payments__c();
        updatedRecord.Status__c = 'Accepted';
        updatedRecord.Id = record.Id;
        update updatedRecord;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.showPaymentStatusOnAccount(record.Id);
        Test.stopTest();
        List<Payments__c> getPaymentOnAcc =  [SELECT Id,Status__c FROM Payments__c WHERE Id=:record.Id];
        System.assertEquals('Accepted', getPaymentOnAcc[0].Status__c);
    }
    @isTest static void showPaymentStatusOnAccount_Test2() {
        Payments__c record = new Payments__c();
        record.Status__c = 'Pending';
        record.BillingStreet__c = 'testaddress';
        record.Billing_PostalCode__c = '123';
        record.BillingCity__c = 'test city';
        record.CurrencyIsoCode = 'DKK';
        record.BillingCountry__c = 'DKK';
        record.Billing_name__c = 'Test';
        record.Amount__c = 1000;
        // insert record;
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.showPaymentStatusOnAccount(record.Id);
        Test.stopTest();
        List<Payments__c> getPaymentOnAcc =  [SELECT Id,Status__c FROM Payments__c WHERE Id=:record.Id];
        System.assertEquals(0, getPaymentOnAcc.size());
    }
    
    @isTest static void getAddressInfoFromAccount_Test() {
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12');
        insert testLead;
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType, lead__c =testLead.Id );
        insert testAccount;
        
        List<Journal__c> getJournal = new List<Journal__c>();
        Journal__c newJournal = new Journal__c();
        newJournal.Lead__c = testLead.Id;
        newJournal.DocFab_Record_Model_ID__c = '54';
        newJournal.External_record_uuid__c = '1234';
        newJournal.Contains_Custom_Documents__c = false;
        newJournal.Account__c = testAccount.Id;
        getJournal.add(newJournal);
        insert newJournal;
        
        df_journal_dk__c testjournaldk = new df_journal_dk__c();
        testjournaldk.Journal__c = getJournal[0].Id;
        testjournaldk.uuid__c = '1234';
        testjournaldk.person_1_cpr__c = 'test';
        testjournaldk.person_1_first_name__c = 'abc';
        testjournaldk.person_1_last_name__c = 'tset';
        testjournaldk.person_2_first_name__c = 'Test2';
        testjournaldk.person_2_last_name__c = 'test';
        testjournaldk.person_1_email__c = 'abc@abc.com';
        testjournaldk.person_1_phone__c = '1234';
        testjournaldk.person_2_email__c = 'abc@abc.com';
        testjournaldk.person_2_phone__c = '234567';
        testjournaldk.nsker_medlemskab_person_1__c = true;
        testjournaldk.nsker_medlemskab_person_2__c =true;
        testjournaldk.person_1_address__c = '122 Secret Screet';
        testjournaldk.person_1_city__c = 'Jal';
        insert testjournaldk;
        
        PS_PaymentUtility.PS_AddressInfoWrapper addressWrapperInstance = new PS_PaymentUtility.PS_AddressInfoWrapper();
        Test.startTest();
        addressWrapperInstance = PS_PaymentController.getAddressInfoFromAccount(testAccount.Id,newJournal.Id);
        Test.stopTest();
        
    }
    @isTest static void getAddressInfoFromAccount_Test2() {
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12');
        insert testLead;
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType, lead__c =testLead.Id );
        insert testAccount;
        
        List<Journal__c> getJournal = new List<Journal__c>();
        Journal__c newJournal = new Journal__c();
        newJournal.Lead__c = testLead.Id;
        newJournal.DocFab_Record_Model_ID__c = '54';
        newJournal.External_record_uuid__c = '1234';
        newJournal.Contains_Custom_Documents__c = false;
        newJournal.Account__c = testAccount.Id;
        getJournal.add(newJournal);
        //insert newJournal;
        PS_PaymentUtility.PS_AddressInfoWrapper addressWrapperInstance = new PS_PaymentUtility.PS_AddressInfoWrapper();
        Test.startTest();
        addressWrapperInstance = PS_PaymentController.getAddressInfoFromAccount(testAccount.Id,getJournal[0].Id);
        Test.stopTest();
        
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceAccount_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test@gmail.com');
        insert testLead;
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test@gmail.com',RecordTypeId= accountRecordType, lead__c =testLead.Id );
        insert testAccount;
        
        Payments__c testPayment = new Payments__c(Account__c = testAccount.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Amount__c = 100);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id, CurrencyIsoCode = 'DKK', Quantity__c = 1, Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        
        /* LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = testLead.Id,Discount__c = 0, Item_Price__c = 100,CurrencyIsoCode = 'DKK', Quantity__c = 1,  Plan_handle__c = 'FitnessPlan01');
        insert testLeadProduct;*/
            List<LeadProducts__c> leadProductList = new List<LeadProducts__c>();
        // leadProductList.add(testLeadProduct);
        //  System.debug('leadProductList >>>> 283'+leadProductList);
        //insert leadProductList;
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        request.requestURI = 'https://api.reepay.com/v1/customer/test@gmail.com';
        request.httpMethod = 'GET';
        //request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testAccount.Id,  JSON.serialize(testPayment), JSON.serialize(polList), leadProductList);
        Test.stopTest();
    }
    
    @isTest static void makeCalloutToCreateCustomerInvoiceAccount_Test2() {
        
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;
        
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test1@gmail.com');
        insert testLead;
        
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test1@gmail.com',RecordTypeId= accountRecordType );
        insert testAccount;
        
        Payments__c testPayment = new Payments__c(Account__c = testAccount.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Amount__c = 0);
        insert testPayment;
        
        Payment_order_line__c testPol = new Payment_order_line__c(Name = 'Test Pol', Payments__c = testPayment.Id, CurrencyIsoCode = 'DKK',Quantity__c = 1,Amount__c = 100);
        insert testPol;
        
        List<Payment_order_line__c> polList = new List<Payment_order_line__c>();
        polList.add(testPol);
        
        LeadProducts__c testLeadProduct = new LeadProducts__c(Plan_handle__c='FitnessPlan01',Name = 'Test Lead Product', Lead__c = testLead.Id, Item_Price__c = 100, Discount__c= 0, CurrencyIsoCode = 'DKK', Quantity__c = 1);
        insert testLeadProduct;
        
        List<LeadProducts__c> leadProductList = new List<LeadProducts__c>();
        leadProductList.add(testLeadProduct);
        
        
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        request.requestURI = 'https://api.reepay.com/v1/customer/test1@gmail.com';
        request.httpMethod = 'GET';
        //request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        Test.startTest();
        paymentRelatedWrapperInstance = PS_PaymentController.makeCalloutToCreateCustomerInvoice(testAccount.Id,  JSON.serialize(testPayment), JSON.serialize(polList), leadProductList);
        Test.stopTest();
        
    }
    
}