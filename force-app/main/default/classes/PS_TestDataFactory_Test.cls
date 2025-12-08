@isTest
public with sharing class PS_TestDataFactory_Test {
    
    public static List<Lead> createLeadWithLeadProductAndPayment(Integer numOfLead, Integer numOfPayment, Integer numOfLeadProduct,Boolean isSubscriptiontype) {
        List<Lead> leadList = new List<Lead>();
        List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();
        for(Integer i = 0;i<numOfLead;i++){
            leadList.add(new Lead(LastName = 'LastName', Company = 'xyz', Provider_Id__c='testProviderLnamev10',Email='test@test.com', OwnerId=UserInfo.getUserId()));
        }
        if(!leadList.isEmpty()){
            insert leadList;
        }
        if (numOfLeadProduct > 0) {
            leadProducts = createLeadProduct(leadList, numOfLeadProduct);
        }
        if (numOfPayment > 0) {
            createPayment(leadList,leadProducts, numOfPayment, isSubscriptiontype);
        }
        return leadList;
    }

    public static List<LeadProducts__c> createLeadProduct(List<Lead> leadList, Integer numOfLeadProduct){
        List<LeadProducts__c> leadProductList = new List<LeadProducts__c>();
        List<Product2> product2Test = new List<Product2>();
        PricebookEntry pbe = new PricebookEntry();
        Pricebook2 pb = new Pricebook2();

        for (Integer i = 0; i<numOfLeadProduct; i++) {
            product2Test.add(new Product2(Name='test',productCode='1234',isActive = true,Product_Identifier__c='PI1'));
        }
        if (numOfLeadProduct > 0) {
            insert product2Test;

            insert new PricebookEntry(pricebook2id = Test.getStandardPricebookId(), product2id = product2Test[0].id,unitprice=1.0, isActive=true);

            // Fixed: Added Internal_Identifier__c to prevent REQUIRED_FIELD_MISSING error
            pb = new pricebook2(name='test', Internal_Identifier__c='test_identifier');
            insert pb;

            pbe = new PricebookEntry(pricebook2id=pb.id, product2id=product2Test[0].id,unitprice=1.0, isActive=true);
            insert pbe;
        }
        for (Integer i = 0; i<numOfLeadProduct; i++) {
            leadProductList.add(new LeadProducts__c(Name='test',Quantity__c= 1,Item_Price__c = 10, Product_Id__c= product2Test[i].Id, Lead__c = leadList[0].Id, Discount__c=10,PricebookEntry_Id__c=pbe.Id,Pricebook_Id__c=pb.Id));
        }
        if (numOfLeadProduct > 0) {
            insert leadProductList;
        }
        return leadProductList;
    }

    public static List<Payments__c> createPayment(List<Lead> leadList, List<LeadProducts__c> leadProducts, Integer numOfPayment, Boolean isSubscriptiontype){
        List<Payments__c> paymentList = new List<Payments__c>();

        for (Integer i = 0; i<numOfPayment; i++) {
            Payments__c paymentSingle = new Payments__c(AMOUNT__c=10,BILLINGCITY__c='TestCity',BILLINGSTATE__c='TestState',BILLINGSTREET__c='Test street',BILLING_EMAIL__c='test@test.com',BILLING_NAME__c='test name',CURRENCYISOCODE='DKK',INVOICE_CREATED__c=true,INVOICE_ID__c='7621ge7qwye23te76376182yf',INVOICE_UNIQUE_HANDLE__c='Inv-0001',LEAD__c=leadList[0].Id,STATUS__c='Pending');
            if (isSubscriptiontype) {
                paymentSingle.TYPE__c='Subscription';
                paymentSingle.Subscription_id__c = leadProducts[0].Id;
            }else{
                paymentSingle.TYPE__c='Onetime';
            }
            paymentList.add(paymentSingle);
        }
        if (numOfPayment > 0) {
            insert paymentList;
        }
        return paymentList;
    }

}
