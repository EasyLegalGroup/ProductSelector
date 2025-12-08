@isTest with sharing class PS_OrderCreationController_Test {
   
    @TestSetup
    static void makeData(){
        Id accountRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Personkonto').getRecordTypeId();
        Account testAccount = new Account(LastName = 'Test Account', PersonEmail = 'test2@gmail.com',RecordTypeId= accountRecordType, Market_Unit__c = 'DFJ_DK', CurrencyIsoCode = 'DKK');
        insert testAccount;
    
        // Insert Product
        Product2 p = new Product2();
        // DFJ-330 changes start
        p.Product_Identifier__c = 'tst';
        // DFJ-330 changes end
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
    
        Id pricebookId = Test.getStandardPricebookId();
        
        // Insert PricebookEntry
        Pricebook2 customPricebook = new Pricebook2();
        customPricebook.Name = 'DFJ ';
        customPricebook.IsActive = true;
        customPricebook.CurrencyIsoCode='DKK';
        customPricebook.Internal_Identifier__c = 'OCC';
          
        insert customPricebook;
    
        PricebookEntry[] pbe1 = new PricebookEntry[] {
            new PricebookEntry (Product2ID=p.Id,Pricebook2ID=Test.getStandardPricebookId(),UnitPrice=50, isActive=true),
            new PricebookEntry (Product2ID=p.Id,Pricebook2ID=customPricebook.Id,UnitPrice=50, isActive=true) };
          insert pbe1;
        
        //Changes DFJ-77
        List<Journal__c> journalList = new List<Journal__c>();
        for(integer i=0;i<=2;i++){
            Journal__c journalInst = new Journal__c();
            journalInst.Account__c = testAccount.Id;
            journalList.add(journalInst);
        }
        insert journalList;
        //End
          
    }
    @isTest static void createOrderRecord_Test() {
    Account testAccount = [SELECT Id, Name, Market_Unit__c from Account LIMIT 1];

    PS_OrderCreationService.productsWrapper productsWrapperInstance= new PS_OrderCreationService.productsWrapper();
    Test.startTest();
    productsWrapperInstance = PS_OrderCreationController.createOrderRecord(testAccount.Id);
    productsWrapperInstance = PS_OrderCreationController.createOrderRecord('');
    Test.stopTest();
    }

    // DFJ-330 changes start
    @isTest static void fetchPriceBookAndEntries_Test() {
        Account testAccount = [SELECT Id, Name, Market_Unit__c from Account LIMIT 1];

        PS_OrderCreationService.priceBookWithItsEntriesWrapper priceBookWithItsEntriesWrapperInstance= new PS_OrderCreationService.priceBookWithItsEntriesWrapper();
        Test.startTest();
        PS_OrderCreationController.fetchPriceBookAndEntries(testAccount.Id);
        PS_OrderCreationController.fetchPriceBookAndEntries('');
        Test.stopTest();
    }
    // DFJ-330 changes end


    @isTest static void createOrderAndOrderItems_Test() {
        Account testAccount = [SELECT Id, Name, Market_Unit__c,CurrencyIsoCode from Account LIMIT 1];
        Product2 pro = [SELECT Id, productCode,Description, Name, IsActive FROM Product2 LIMIT 1];
        Pricebook2 customPricebook = [SELECT Id,Name,CurrencyIsoCode FROM Pricebook2 
                                            WHERE 
                                            IsActive = true 
                                            AND
                                            CurrencyIsoCode =: testAccount.CurrencyIsoCode
                                            AND IsStandard = false
                                            LIMIT 1];

        PricebookEntry listOfProducts = [ SELECT Id,Name,PriceBook2.Id,Product2.Name,Product2.CurrencyIsoCode,Product2.Plan__c,Product2.Is_subscription__c,
                                            Product2.ProductCode,
                                            PriceBook2.Name,
                                            PriceBook2.CurrencyIsoCode,
                                            Partner_provision_value__c,
                                            Partner_sales_value__c,
                                            Provision_base__c,
                                            UnitPrice
                                            FROM PriceBookEntry
                                            WHERE 
                                            PriceBook2.Id = :customPricebook.Id 
                                            AND 
                                            Product2.IsActive = true ORDER BY Sort_Key__c DESC NULLS LAST LIMIT 1];

        Order orderRecord = new Order(Fixed_discount_Type__c= 0,AccountId= testAccount.Id,Pricebook2Id= customPricebook.Id,Status= 'Draft',EffectiveDate= System.today(),Market_Unit__c=testAccount.Market_Unit__c ,CurrencyIsoCode= 'DKK');
        
        List<OrderItem> orderLineItemList = new List<OrderItem>();
        OrderItem orderLineItem = new OrderItem();
        orderLineItem.OrderId = orderRecord.Id;
        orderLineItem.PricebookEntryId = listOfProducts.Id;
        orderLineItem.Product2Id = pro.Id;
        orderLineItem.Discount__c = 50;
        orderLineItem.Quantity = 2;
        orderLineItem.UnitPrice =499;
        orderLineItem.Partner_provision_value__c = 499;
        orderLineItem.Partner_sales_value__c = 499;
        orderLineItem.Provision_base__c = 499;
        orderLineItemList.add(orderLineItem);

        Test.startTest();
        PS_OrderCreationController.createOrderAndOrderItems(JSON.serialize(orderLineItemList), orderRecord,testAccount.Id);
        PS_OrderCreationController.createOrderAndOrderItems('', null,'');
       
        Test.stopTest();
        }
    //Changes DFJ-77 Starts
    /*
    @isTest static void relateJournalWithOrder_Test() {
    Account testAccount = [SELECT Id, Name, Market_Unit__c from Account LIMIT 1];

    //PS_OrderCreationService.productsWrapper productsWrapperInstance= new PS_OrderCreationService.productsWrapper();
    List<Journal__c> journalListTest = new List<Journal__c>();
    Test.startTest();
    journalListTest = PS_OrderCreationController.relateJournalWithOrder(testAccount.Id);
    journalListTest = PS_OrderCreationController.relateJournalWithOrder('');
    Test.stopTest();
    }*/
     //End
     
    @isTest static void createPaymentRecord_Apex_Test() {
        Account testAccount = [SELECT Id, Name, Market_Unit__c,CurrencyIsoCode from Account LIMIT 1];
        

        Test.startTest();
        PS_OrderCreationController.createPaymentRecord(testAccount.Id);       
        Test.stopTest();
        }
    
}