@IsTest
public with sharing class PS_InvoiceWebhookReceiver_Test {
    @isTest static void createInvoiceBySubscription_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];
        
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        // Ensure lead is owned by current user before conversion
        leadRecords[0].OwnerId = UserInfo.getUserId();
        update leadRecords[0];

        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId( leadRecords[0].Id );  
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true AND MasterLabel = 'Qualified' limit 1];
        lc.setDoNotCreateOpportunity( true );  
        // lc.setA
        lc.setConvertedStatus(convertStatus.MasterLabel);  
          
        Database.LeadConvertResult lcr = Database.convertLead(lc);  
          
        system.assert( lcr.isSuccess() );

        lc.setAccountId(testAccount.Id);

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        // TODO : Use mock
        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "subscription": "'+leadProds[0].Id+'", "customer": "kushagra.mishra@cloudanalogy.com", "event_type": "invoice_created", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        Test.stopTest();

        List<Payments__c> paymentsToassert = [Select Id,Name from Payments__c LIMIT 10000];
        // System.assertEquals(1, paymentsToassert.size());
        
    }
    // update the invoice

    @isTest static void updateInvoiceByInvoice_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, false);

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        //TODO : Use mock
        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "customer": "test@test.com", "event_type": "invoice_settled", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        Test.stopTest();

        List<Payments__c> paymentsToassert = [Select Id,Name,Status__c from Payments__c LIMIT 1];
        System.assertEquals('Settled',paymentsToassert[0].Status__c);
    }

    @isTest static void updateInvoiceByInvoiceSubscription_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);

        LeadProducts__c testLeadProduct = new LeadProducts__c(Name = 'Test Lead Product', Lead__c = leadRecords[0].Id, Item_Price__c = 100, Discount__c = 0, CurrencyIsoCode = 'DKK',Quantity__c = 1,Plan_handle__c = 'FitnessPlan01');
        insert testLeadProduct;
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];

        // TODO : use mock
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "customer": "test@test.com", "subscription": "'+leadProds[0].Id+'", "event_type": "invoice_settled", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        //PS_InvoiceWebhookHelper.updateRelatedSubscription('sub-0002','subscription_changed');
        Test.stopTest();

        List<Payments__c> paymentsToassert = [Select Id,Name,Status__c from Payments__c LIMIT 1];
        System.assertEquals('Settled',paymentsToassert[0].Status__c);

    }
    //Chnages Start TCS-36

    //End

    @isTest static void updateSubscriptionStatus_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];

        // TODO : use mock
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "customer": "test@test.com", "subscription": "'+leadProds[0].Id+'", "event_type": "subscription_payment_method_added", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        Test.stopTest();

        List<Payments__c> paymentsToassert = [Select Id,Name,Subscription_status__c from Payments__c LIMIT 1];
        System.assertEquals('Accepted',paymentsToassert[0].Subscription_status__c);
    }

    @isTest static void updatenullUri_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '';
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        // Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        Test.stopTest();
        //System.assertEquals(400, response , 'PS_InvoiceWebhookReceiver')
    }

    @IsTest static void createOrderAndPaymentTestOfOLI(){
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        Account testAccount = new Account(name='Test Account');
        insert testAccount;

        Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                AccountId = testAccount.Id,
                StageName = 'Needs Analysis',
                CloseDate = System.today() + 20
        );

        insert opp;

        // Insert Product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.ProductCode = 'ABC';
        p.IsActive = true;
        p.Product_Identifier__c = 'PI1';
        insert p;

        // get standard pricebook Id
        Id pricebookId = Test.getStandardPricebookId();

        // Insert PricebookEntry
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;


        OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = standardPrice.Id,
                Quantity = 2,
                TotalPrice = 1000
        );
        insert oli;

        PS_PaymentUtility.GetInvoiceWrapper getInvoiceWrapperInstance = new PS_PaymentUtility.GetInvoiceWrapper();
        getInvoiceWrapperInstance.id = 'dafba2016614418f969fa5697383e47c';
        getInvoiceWrapperInstance.handle = 'Inv-0001';
        getInvoiceWrapperInstance.customer = 'test@test.com';
        getInvoiceWrapperInstance.state = 'settled';
        getInvoiceWrapperInstance.type = 'settled';
        getInvoiceWrapperInstance.amount = 10;
        PS_PaymentUtility.PS_transactions transactions = new PS_PaymentUtility.PS_transactions();
        transactions.id = 'dafba2016614418f969fa5697383e47c';
        transactions.state='settled';
        transactions.invoice='Inv-0001';
        transactions.amount=10000;
        transactions.payment_type='card';

        getInvoiceWrapperInstance.transactions = new List<PS_PaymentUtility.PS_transactions>{transactions};

        Test.startTest();
        PS_InvoiceWebhookHelper.createOrderAndPayment(
                getInvoiceWrapperInstance,
                new List<LeadProducts__c>(),
                new List<OrderItem>(),
                new List<OpportunityLineItem>{oli});

        Test.stopTest();
    }

    @isTest static void createOrderPayment_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        

        Account testAccount = new Account(name='Test Account');
        insert testAccount;

        // Ensure lead is owned by current user before conversion
        leadRecords[0].OwnerId = UserInfo.getUserId();
        update leadRecords[0];

        Database.LeadConvert lc = new database.LeadConvert();  
        lc.setLeadId( leadRecords[0].Id );  
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true AND MasterLabel = 'Qualified' limit 1];
        lc.setDoNotCreateOpportunity( true );  
        // lc.setA
        lc.setConvertedStatus(convertStatus.MasterLabel);  
          
        Database.LeadConvertResult lcr = Database.convertLead(lc);  
          
        system.assert( lcr.isSuccess() );

        lc.setAccountId(testAccount.Id);


        List<LeadProducts__c> leadProds = [Select Id,Name,CurrencyIsoCode,Lead__c,Lead__r.Market_Unit__c,Lead__r.City,Lead__r.Email,Lead__r.Name,Lead__r.PostalCode,Lead__r.State,Lead__r.Street,Pricebook_Id__c,Lead__r.ConvertedAccountId,PricebookEntry_Id__c,Product_Id__c,Discount__c,Quantity__c,Item_Price__c,Partner_Provision_Value__c,Partner_Sales_Value__c,Provision_Base__c from LeadProducts__c LIMIT 1];

        List<OrderItem> orderProds = new List<OrderItem>();
        PS_PaymentUtility.GetInvoiceWrapper getInvoiceWrapperInstance = new PS_PaymentUtility.GetInvoiceWrapper();
        getInvoiceWrapperInstance.id = 'dafba2016614418f969fa5697383e47c';
        getInvoiceWrapperInstance.handle = 'Inv-0001';
        getInvoiceWrapperInstance.customer = 'test@test.com';
        getInvoiceWrapperInstance.state = 'settled';
        getInvoiceWrapperInstance.type = 'settled';
        getInvoiceWrapperInstance.amount = 10;
        PS_PaymentUtility.PS_transactions transactions = new PS_PaymentUtility.PS_transactions();
        transactions.id = 'dafba2016614418f969fa5697383e47c';
        transactions.state='settled';
        transactions.invoice='Inv-0001';
        transactions.amount=10000;
        transactions.payment_type='card';

        getInvoiceWrapperInstance.transactions = new List<PS_PaymentUtility.PS_transactions>{transactions};

        Test.startTest();
        PS_InvoiceWebhookHelper.createOrderAndPayment(getInvoiceWrapperInstance,leadProds,orderProds, new List<OpportunityLineItem>());
        Test.stopTest();
    }

    @isTest static void createOrderPayments_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        
        Account testAccount = new Account(name='Test Account');
        insert testAccount;

        // Ensure lead is owned by current user before conversion
        leadRecords[0].OwnerId = UserInfo.getUserId();
        update leadRecords[0];

        Database.LeadConvert lc = new database.LeadConvert();  
        lc.setLeadId( leadRecords[0].Id );  
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true AND MasterLabel = 'Qualified' limit 1];
        lc.setDoNotCreateOpportunity( true );  
        // lc.setA
        lc.setConvertedStatus(convertStatus.MasterLabel);  
          
        Database.LeadConvertResult lcr = Database.convertLead(lc);  
          
        system.assert( lcr.isSuccess() );

        lc.setAccountId(testAccount.Id);


        List<LeadProducts__c> leadProds = new List<LeadProducts__c>();


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
    insert i;


        List<OrderItem> orderProds = [SELECT Id,Partner_provision_value__c,Partner_sales_value__c,Provision_base__c,Discount__c,Product2Id,PricebookEntryId,Effective_price__c, Product_Name__c, Quantity,Order.AccountId,Order.Market_Unit__c,UnitPrice,ListPrice,TotalPrice,Order.BillingStreet,Order.BillingState,Order.BillingCity,Order.BillingPostalCode,Order.Lead__c,Order.currencyIsoCode,Order.Account.Name,Order.Account.PersonEmail,Order.Pricebook2Id FROM OrderItem LIMIT 1];
        PS_PaymentUtility.GetInvoiceWrapper getInvoiceWrapperInstance = new PS_PaymentUtility.GetInvoiceWrapper();
        getInvoiceWrapperInstance.id = 'dafba2016614418f969fa5697383e47c';
        getInvoiceWrapperInstance.handle = 'Inv-0001';
        getInvoiceWrapperInstance.customer = 'test@test.com';
        getInvoiceWrapperInstance.state = 'settled';
        getInvoiceWrapperInstance.type = 'settled';
        getInvoiceWrapperInstance.amount = 10;
        PS_PaymentUtility.PS_transactions transactions = new PS_PaymentUtility.PS_transactions();
        transactions.id = 'dafba2016614418f969fa5697383e47c';
        transactions.state='settled';
        transactions.invoice='Inv-0001';
        transactions.amount=10000;
        transactions.payment_type='card';

        getInvoiceWrapperInstance.transactions = new List<PS_PaymentUtility.PS_transactions>{transactions};

        Test.startTest();
        PS_InvoiceWebhookHelper.createOrderAndPayment(getInvoiceWrapperInstance,leadProds,orderProds, new List<OpportunityLineItem>());
        Test.stopTest();
    }

    @isTest static void createInvoiceBySubscription_Test1() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        //List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test@test.com', Fixed_Discount_Type__c = 0, OwnerId = UserInfo.getUserId());
        insert testLead;

        Product2 product = (new Product2(Name='test',productCode='1234',isActive = true,Product_Identifier__c = 'PI3'));
        insert product;

        insert new PricebookEntry(pricebook2id = Test.getStandardPricebookId(), product2id = product.id,unitprice=1.0, isActive=true);

        pricebook2 pb = new pricebook2(name='test', Internal_Identifier__c = 'IW1');
        insert pb;

        PricebookEntry pbe = new PricebookEntry(pricebook2id=pb.id, product2id=product.id,unitprice=1.0, isActive=true);
        insert pbe;
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='carl@leone.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Status__c = 'Pending', INVOICE_CREATED__c=true,INVOICE_ID__c='7621ge7qwye23te76376182yf',INVOICE_UNIQUE_HANDLE__c='Inv-0001', Subscription_id__c = '802G50000008zazIAA');
        insert testPayment;
        
        Account testAccount = new Account(name='Test Account');
        insert testAccount;

        // Ensure lead owner is current user before conversion
        testLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLead.Id];
        if (String.valueOf(testLead.OwnerId).startsWith('00G')) {
            testLead.OwnerId = UserInfo.getUserId();
            update testLead;
        }

        Database.LeadConvert lc = new database.LeadConvert();  
        lc.setLeadId( testLead.Id );  
        lc.setOwnerId(UserInfo.getUserId());
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true AND MasterLabel = 'Qualified' limit 1];
        lc.setDoNotCreateOpportunity( true );  
        // lc.setA
        lc.setConvertedStatus(convertStatus.MasterLabel);  
          
        Database.LeadConvertResult lcr = Database.convertLead(lc);  
          
        system.assert( lcr.isSuccess() );

        lc.setAccountId(testAccount.Id);

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        // TODO : Use mock
        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "subscription": "802G50000008zazIAA", "customer": "kushagra.mishra@cloudanalogy.com", "event_type": "invoice_created", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        Test.stopTest();

        List<Payments__c> paymentsToassert = [Select Id,Name from Payments__c LIMIT 10000];
        // System.assertEquals(1, paymentsToassert.size());
        
    }
    @isTest static void refundInvoiceAmount_Test() {
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        Lead testLead = new Lead(LastName = 'Test', Company = 'xyz', Provider_Id__c='testProviderid12', Email='test@test.com', Fixed_Discount_Type__c = 0);
        insert testLead;


        Product2 product = (new Product2(Name='test',productCode='1234',isActive = true,Product_Identifier__c = 'PI4'));
        insert product;

        insert new PricebookEntry(pricebook2id = Test.getStandardPricebookId(), product2id = product.id,unitprice=1.0, isActive=true);

        pricebook2 pb = new pricebook2(name='test', Internal_Identifier__c = 'IW2');
        insert pb;

        PricebookEntry pbe = new PricebookEntry(pricebook2id=pb.id, product2id=product.id,unitprice=1.0, isActive=true);
        insert pbe;
        Payments__c testPayment = new Payments__c(Lead__c = testLead.Id, CurrencyIsoCode = 'DKK',BillingCity__c = 'Jalandhar', Billing_name__c ='Test', Billing_email__c ='test@test.com', BillingState__c='Punjab', Billing_PostalCode__c='144201', Status__c = 'Settled', INVOICE_CREATED__c=true,INVOICE_ID__c='7621ge7qwye23te76376182yf',INVOICE_UNIQUE_HANDLE__c='a34Aa000004qxmTIAQ', Subscription_id__c = '802G50000008zazIAA');
        insert testPayment;
        //List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];

        // TODO : use mock
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"timestamp":"2023-05-26T12:13:39.039Z","subscription":null,"signature":"0713f2facd9d4acbb25a94737375606b383a06af566f315ac8435b8119e8facb","payment_method_reference":null,"payment_method":null,"invoice":"a34Aa000004qxmTIAQ","id":"469c2aa9037e091db63fb3c332bea9bb","event_type":"invoice_refund","event_id":"b2e9c6e2d6e94d9db8225369fe4eadd7","customer":"test@test.com"}');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        Test.stopTest();

        List<Payments__c> paymentsToassert = [Select Id,Name,Subscription_status__c from Payments__c LIMIT 1];
        //System.assertEquals('Accepted',paymentsToassert[0].Subscription_status__c);
    }
    //DFJ-128 Test Methods
    @isTest static void updateRelatedSubscription_Test() {
         ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];
		
        Subscriptions__c subRecord = new Subscriptions__c(Subscription_handle__c = 'sub-0002',Trial_End_Date__c=System.now()-2);
        insert subRecord;
        
        Payments__c patmentRecord = new Payments__c(Lead__c = leadRecords[0].Id,Subscription_id__c= subRecord.Subscription_handle__c);
        insert patmentRecord;
        // TODO : use mock
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "customer": "test@test.com", "subscription": "sub-0002", "event_type": "subscription_changed", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        //PS_InvoiceWebhookHelper.updateRelatedSubscription('sub-0002','subscription_changed');
        Test.stopTest();

        List<Subscriptions__c> subsRecord = [Select Id,Account__c FROM Subscriptions__c WHERE Subscription_handle__c='sub-0002' LIMIT 1 ];
        System.assertEquals(1,subsRecord.size());
        
    }
    @isTest static void updateRelatedSubscription_Test2() {
         ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];
		
        Subscriptions__c subRecord = new Subscriptions__c(Subscription_handle__c = 'sub-0002',Trial_End_Date__c=System.now()-2);
        insert subRecord;
        
        Payments__c patmentRecord = new Payments__c(Lead__c = leadRecords[0].Id,Subscription_id__c= subRecord.Subscription_handle__c);
        insert patmentRecord;
        // TODO : use mock
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "customer": "test@test.com", "subscription": "sub-0002", "event_type": "subscription_expired", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        //PS_InvoiceWebhookHelper.updateRelatedSubscription('sub-0002','subscription_changed');
        Test.stopTest();

        List<Subscriptions__c> subsRecord = [Select Id,Account__c FROM Subscriptions__c WHERE Subscription_handle__c='sub-0002' LIMIT 1 ];
        System.assertEquals(1,subsRecord.size());
        
    }
    @isTest static void updateRelatedSubscription_Test3() {
         ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];
		
        Subscriptions__c subRecord = new Subscriptions__c(Subscription_handle__c = 'sub-0002',Trial_End_Date__c=System.now()-2);
        insert subRecord;
        
        Payments__c patmentRecord = new Payments__c(Lead__c = leadRecords[0].Id,Subscription_id__c= subRecord.Subscription_handle__c);
        insert patmentRecord;
        // TODO : use mock
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "customer": "test@test.com", "subscription": "sub-0002", "event_type": "subscription_trial_end", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        //PS_InvoiceWebhookHelper.updateRelatedSubscription('sub-0002','subscription_changed');
        Test.stopTest();

        List<Subscriptions__c> subsRecord = [Select Id,Account__c FROM Subscriptions__c WHERE Subscription_handle__c='sub-0002' LIMIT 1 ];
        System.assertEquals(1,subsRecord.size());
        
    }
    @isTest static void updateRelatedSubscription_Test4() {
         ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];
		
        Subscriptions__c subRecord = new Subscriptions__c(Subscription_handle__c = 'sub-0002',Trial_End_Date__c=System.now()-2);
        insert subRecord;
        
        Payments__c patmentRecord = new Payments__c(Lead__c = leadRecords[0].Id,Subscription_id__c= subRecord.Subscription_handle__c);
        insert patmentRecord;
        // TODO : use mock
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "customer": "test@test.com", "subscription": "sub-0002", "event_type": "subscription_renewal", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        //PS_InvoiceWebhookHelper.updateRelatedSubscription('sub-0002','subscription_changed');
        Test.stopTest();

        List<Subscriptions__c> subsRecord = [Select Id,Account__c FROM Subscriptions__c WHERE Subscription_handle__c='sub-0002' LIMIT 1 ];
        System.assertEquals(1,subsRecord.size());
        
    }
    @isTest static void updateRelatedSubscription_Test5() {
         ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        testConfigurations.Use_test_account__c = true;
        insert testConfigurations;

        List<Lead> leadRecords = PS_TestDataFactory_Test.createLeadWithLeadProductAndPayment(1, 1, 1, true);
        List<LeadProducts__c> leadProds = [Select Id,Name from LeadProducts__c LIMIT 1];
		
        Subscriptions__c subRecord = new Subscriptions__c(Subscription_handle__c = 'sub-0002',Trial_End_Date__c=System.now()-2);
        insert subRecord;
        
        Payments__c patmentRecord = new Payments__c(Lead__c = leadRecords[0].Id,Subscription_id__c= subRecord.Subscription_handle__c);
        insert patmentRecord;
        // TODO : use mock
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/updates';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"id": "4b5707c9c88582ce045174a8d595e982","timestamp": "2022-07-11T14:01:47.59Z","signature":"4cd0d250a3f503dc877b9e4558970f50112e0dcafd911824e02d3a9f0cf1f8bd", "invoice": "Inv-0001", "customer": "test@test.com", "subscription": "sub-0002", "event_type": "subscription_cancelled", "event_id": "a4154288b71c96bba191b4a84be0d38a" }');
        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PS_MockUtility_Test());
        PS_InvoiceWebhookReceiver.invoiceUpdatesHandler();
        //PS_InvoiceWebhookHelper.updateRelatedSubscription('sub-0002','subscription_changed');
        Test.stopTest();

        List<Subscriptions__c> subsRecord = [Select Id,Account__c FROM Subscriptions__c WHERE Subscription_handle__c='sub-0002' LIMIT 1 ];
        System.assertEquals(1,subsRecord.size());
        
    }

}