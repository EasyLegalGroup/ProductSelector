@isTest
private class OrderAssetCreatorTest {
    @isTest static void testAssetCreationForEachUnit() {
        // --- Setup ---
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        
        Journal__c journal = new Journal__c();
        insert journal;
        
        Pricebook2 customPB = new Pricebook2(Name = 'Test Pricebook', IsActive = true, Internal_Identifier__c = 'OAT');
        insert customPB;
        
        Order testOrder = new Order(
            AccountId     = acct.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            CurrencyIsoCode = 'DKK',
            Pricebook2Id  = customPB.Id,
            Journal__c    = journal.Id
        );
        insert testOrder;
        testOrder = [SELECT Id, CreatedDate, CurrencyIsoCode, Journal__c FROM Order WHERE Id = :testOrder.Id];
        
        Product2 prod = new Product2(
            Name                    = 'Test Product',
            isActive                = true,
            Product_Identifier__c   = 'ABC',
            Requires_Tinglysning__c = false
        );
        insert prod;
        
        Id standardPBId = Test.getStandardPricebookId();
        insert new PricebookEntry(
            Product2Id  = prod.Id,
            Pricebook2Id = standardPBId,
            UnitPrice    = 50,
            IsActive     = true
        );
        insert new PricebookEntry(
            Product2Id  = prod.Id,
            Pricebook2Id = customPB.Id,
            UnitPrice    = 50,
            IsActive     = true
        );
        
        OrderItem oi1 = new OrderItem(
            OrderId         = testOrder.Id,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :customPB.Id AND Product2Id = :prod.Id LIMIT 1].Id,
            Quantity        = 3,
            UnitPrice       = 50,
            Product2Id      = prod.Id
        );
        OrderItem oi2 = new OrderItem(
            OrderId         = testOrder.Id,
            PricebookEntryId = oi1.PricebookEntryId,
            Quantity        = 2,
            UnitPrice       = 50,
            Product2Id      = prod.Id
        );
        insert new List<OrderItem>{ oi1, oi2 };
        
        // --- Execute ---
        OrderAssetCreator.RequestWrapper req = new OrderAssetCreator.RequestWrapper();
        req.orderId = testOrder.Id;
        Test.startTest();
            OrderAssetCreator.createAssets(new List<OrderAssetCreator.RequestWrapper>{ req });
        Test.stopTest();
        
        // --- Verify ---
        List<Asset> assets = [
            SELECT Id, RecordTypeId, Order__c, Quantity, Name, Price, PurchaseDate,
                   CurrencyIsoCode, Public_Registration_Required__c,
                   Public_Registration_Status__c, Journal__c
              FROM Asset
             WHERE Order__c = :testOrder.Id
        ];
        System.assertEquals(5, assets.size(), 'Expected 5 asset records.');
        
        Date expectedPurchaseDate = testOrder.CreatedDate.date();
        Id expectedRt = Schema.SObjectType.Asset
            .getRecordTypeInfosByDeveloperName()
            .get('Product_Assets')
            .getRecordTypeId();
        
        for (Asset ast : assets) {
            System.assertEquals(1, ast.Quantity, 'Each asset should have a quantity of 1.');
            System.assertEquals(expectedPurchaseDate, ast.PurchaseDate,
                'Asset PurchaseDate should equal the Order CreatedDate.');
            System.assertEquals(50, ast.Price,
                'Asset Price should match the OrderItem UnitPrice.');
            System.assertEquals('DKK', ast.CurrencyIsoCode,
                'Asset currency should match the Order currency.');
            System.assertEquals(false, ast.Public_Registration_Required__c,
                'Public Registration Required should be false.');
            System.assertEquals('Not Required', ast.Public_Registration_Status__c,
                'Public Registration Status should be "Not Required".');
            System.assertEquals('Test Product', ast.Name,
                'Asset name should match the product name.');
            System.assertEquals(testOrder.Journal__c, ast.Journal__c,
                'Asset Journal__c should match the Order Journal__c.');
            System.assertEquals(expectedRt, ast.RecordTypeId,
                'Each Asset must have the Product_Assets record type.');
        }
        
        testOrder = [SELECT Assets_Created__c FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals(true, testOrder.Assets_Created__c,
            'Order should have Assets_Created__c set to true.');
    }
}