/*
 * Created by Cloud Analogy on 6/24/2019.
 */
public class DFJ_ProductSelectorController_Apex {
    @AuraEnabled
    public static list<Pricebook2> getAllThePricebooks_Apex() {
        try {
            List<Pricebook2> listOfPricebooks = new List<Pricebook2>();
            //Added check for Is_Opportunity_PriceBook__c in Query for DFJ-275
            listOfPricebooks = [SELECT Id,Name FROM Pricebook2 WHERE IsActive = true AND Is_Opportunity_PriceBook__c = false LIMIT 10000];
            return listOfPricebooks;
        } catch (DmlException ex) {
            throw new AuraHandledException('Error==>' + ex.getMessage() + 'at line number==>' + ex.getLineNumber());
        }
    }
    //Not used anymore in code.
    @AuraEnabled
    public static List<PricebookEntry> fetchAllTheAvailableProducts_Apex(String selectedPricebook) {
        try {
            List<PricebookEntry> listOfProducts = new List<PricebookEntry>();
            listOfProducts = [
                    SELECT Id,Name, Product2.Name, Product2.ProductCode, PriceBook2.Name,Partner_provision_value__c,UnitPrice,Sort_Key__c
                    FROM PriceBookEntry
                    WHERE PriceBook2.Id = :selectedPricebook AND Product2.IsActive = true ORDER BY Sort_Key__c DESC NULLS LAST
            ];
            if (listOfProducts != null) {
                if (!listOfProducts.isEmpty()) {
                    return listOfProducts;
                }
            } else {
                return null;
            }
        } catch (DmlException ex) {
            throw new AuraHandledException('Error==>' + ex.getMessage() + 'at line number==>' + ex.getLineNumber());
        }
        return null;
    }

    @AuraEnabled
    public static List<LeadProducts__c> insertRecords_Apex(List<LeadProducts__c> newProductList,String leadId,Decimal total,String totalValues){
        try {

         List<Lead> leadList = new List<Lead>();
            leadList = [Select Id,Name,telegenta__Forecast__c From Lead WHERE Id =: leadId];
            if(!leadList.isEmpty() && total != null){
                leadList[0].telegenta__Forecast__c = total;
                update leadList;
            }
           if(newProductList != null){
               if(!newProductList.isEmpty()){
                   upsert newProductList;
                   return newProductList;
               }
           }
        } catch (DmlException e) {
            throw new AuraHandledException('Error::-->' + e.getMessage() + 'at line number::->' + e.getLineNumber());
        }
        return null;
    }


    @AuraEnabled
    public static Boolean changeTotalSalesValue_Apex(String leadId, Decimal total) {
        if (leadId == null || total == null) {
            return false;
        }

        List<Lead> leads = new List<Lead>();
        leads = [SELECT Id,telegenta__Forecast__c FROM Lead WHERE Id=: leadId];
        if (!leads.isEmpty()) {
            leads[0].telegenta__Forecast__c = total;
            update leads;
            return true;
        }
        return false;
    }


    @AuraEnabled
    public static void saveSelectedProducts_Apex(String selectedProductsData) {

        if (selectedProductsData != null || selectedProductsData.trim() != '') {
            //return null;
			//System.debug('selectedProductsData==>'+selectedProductsData);
        }

        List<LeadProducts__c> LeadProductsList = new List<LeadProducts__c>();
        LeadProductsList = (List<LeadProducts__c>) JSON.deserialize(selectedProductsData, List<LeadProducts__c>.class);
        upsert LeadProductsList;
    }

    @AuraEnabled
    public static leadProductsWithUserCurrencyIso getSelectedProductData_Apex(String leadRecordId) {

        if (leadRecordId == null || leadRecordId.trim() == '') {
            return null;
        }
        String defaultCurrency = UserInfo.getDefaultCurrency();

        List<LeadProducts__c> leadProductsList = new List<LeadProducts__c>();
        leadProductsList = [SELECT Id,Discount__c,Item_Price__c,Lead__c,Name,Pricebook_Id__c,PricebookEntry_Id__c,Product_Id__c,Product_Name__c,Quantity__c,Partner_Provision_Value__c,Partner_Sales_Value__c,Provision_Base__c,CurrencyIsoCode FROM LeadProducts__c WHERE Lead__c =: leadRecordId];

        // Discount Changes
        Lead relatedLead = [SELECT Id,Name,Fixed_discount_Type__c FROM Lead WHERE Id =: leadRecordId];
        // End
        leadProductsWithUserCurrencyIso leadProductsInstance = new leadProductsWithUserCurrencyIso();
        leadProductsInstance.leadProducts = leadProductsList;
        leadProductsInstance.DefaultCurrencyIsoCode = defaultCurrency;
        // Discount Changes
        leadProductsInstance.relatedLead = relatedLead;
        // End
        return leadProductsInstance;
    }

    public class leadProductsWithUserCurrencyIso{
        @AuraEnabled public List<LeadProducts__c> leadProducts;
        @AuraEnabled public String DefaultCurrencyIsoCode;
        // Discount changes
        @AuraEnabled public Lead relatedLead;
    }
    @AuraEnabled
    public static void updateRecordOfLeadProduct_Apex(LeadProducts__c changedDiscount){
        try{
            if(changedDiscount != null) {
                upsert changedDiscount;
            }

        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<listOfPicklistWrapper> getPicklistValues_Apex(String objectName, String fieldsNames){
        try{
           List<listOfPicklistWrapper> picklistWrappersValues = new List<listOfPicklistWrapper>();
           picklistWrappersValues = fetchPicklistValue_Apex(objectName, fieldsNames);
            return picklistWrappersValues;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<listOfPicklistWrapper> fetchPicklistValue_Apex(String objectName, String fieldName) {
        if (objectName != null && objectName.trim() != '' && fieldName != null && fieldName.trim() != '') {
            List<listOfPicklistWrapper> returnPicklistWrapperList = new List<listOfPicklistWrapper>();

            List<String> fieldsList = new List<String>();
            fieldsList = fieldName.split(',');

            for (String fieldNameLoop : fieldsList) {
                List<picklistWrapper> listPickvals = new List<picklistWrapper>();

                Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);//From the Object Api name retrieving the SObject
                SObject Object_name = targetType.newSObject();
                Schema.SObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed

                Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
                Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject

                List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldNameLoop).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
                for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list

                    picklistWrapper picklistWrapperInstance = new picklistWrapper();
                    picklistWrapperInstance.Label = a.getLabel();
                    picklistWrapperInstance.value = a.getValue();
                   // System.debug(LoggingLevel.ERROR, picklistWrapperInstance.Label);
                    listPickvals.add(picklistWrapperInstance);//add the value  to our final listp
                }

                listOfPicklistWrapper listOfPicklistWrapperInstance = new listOfPicklistWrapper();
                listOfPicklistWrapperInstance.fieldName = fieldNameLoop;
                listOfPicklistWrapperInstance.multiplepicklist = listPickvals;
                returnPicklistWrapperList.add(listOfPicklistWrapperInstance);

            }
            return returnPicklistWrapperList;
        }
        return null;
    }

    public class listOfPicklistWrapper {
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public List<picklistWrapper> multiplepicklist { get; set; }
    }

    public class picklistWrapper {
        @AuraEnabled public String Label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String textValue { get; set; }
    }

    @AuraEnabled
    public static List<LeadProducts__c> deleteRecordOfLeadProduct_Apex(String productId, String leadId){
        try{
           if(productId != null && productId.trim() != ''){
               LeadProducts__c leadProductInstance = new LeadProducts__c();
               leadProductInstance = [SELECT Id FROM LeadProducts__c WHERE Id=: productId];
               delete leadProductInstance;

               List<LeadProducts__c> leadProductsList = new List<LeadProducts__c>();
               leadProductsList = [SELECT Id,Discount__c,Item_Price__c,Lead__c,Name,Pricebook_Id__c,CurrencyIsoCode,PricebookEntry_Id__c,Product_Id__c,Product_Name__c,Quantity__c,Partner_Provision_Value__c FROM LeadProducts__c WHERE Lead__c =: leadId];
               return leadProductsList;

            }
        }catch(DmlException ex){
            throw new AuraHandledException(ex.getMessage()+'at line'+ ex.getLineNumber());
        }
        return null;
    }


    // New changes
    
    @AuraEnabled
    public static productWithLeadProduct getAllThePricebooksAndLeadProducts_Apex (String leadId){
        if (leadId == null || leadId.trim() == '') {
            return null;
        }

        try {
            Map<Id, Pricebook2> IdVSPricebook2s = new Map<Id, Pricebook2>();
            Map<Id, List<PricebookEntry>> priceBookIdVSPricebookEntries = new Map<Id, List<PricebookEntry>>();
            Map<Pricebook2, List<PricebookEntry>> pricebookVSPriceBookEntry = new Map<Pricebook2, List<PricebookEntry>>();
            List<Pricebook2> listOfPricebooks = new List<Pricebook2>();
            //Added check of Is_Opportunity_PriceBook__c in Query for fetching Pricebook DFJ-275

            // DFJ-330 changes start

            Lead leadRecord = [SELECT Id, Market_Unit__c FROM Lead WHERE Id =: leadId];
            String marketUnitFilterValueToUseToFilterPricebooks = leadRecord.Market_Unit__c;


            listOfPricebooks = [SELECT Id,Name,CurrencyIsoCode, IsStandard, Market_Unit__c FROM Pricebook2 WHERE
                    IsActive = TRUE AND
                    Market_Unit__c = :marketUnitFilterValueToUseToFilterPricebooks AND
                    Is_Opportunity_PriceBook__c = FALSE LIMIT 10000];

            if (listOfPricebooks.isEmpty()) {
                listOfPricebooks = [SELECT Id,Name,CurrencyIsoCode, IsStandard, Market_Unit__c FROM Pricebook2 WHERE
                        IsActive = TRUE AND
                        Is_Opportunity_PriceBook__c = FALSE LIMIT 10000];
            }

            // DFJ-330 changes end
            List<PricebookEntry> listOfProducts = new List<PricebookEntry>();

            listOfProducts = [SELECT Id,
                                     Name,
                                     PriceBook2.Id,
                                     Product2.Name,
                                     Product2.CurrencyIsoCode,
                                     Product2.Plan__c,
                                     Product2.Is_subscription__c,
                                     Product2.ProductCode,
                                     PriceBook2.Name,
                                     PriceBook2.CurrencyIsoCode,
                                     Partner_provision_value__c,
                                     Partner_sales_value__c,
                                     Provision_base__c,
                                     convertCurrency(UnitPrice)
                                     FROM PriceBookEntry WHERE PriceBook2.Id IN : listOfPricebooks AND IsActive = true AND Product2.IsActive = true ORDER BY Sort_Key__c DESC NULLS LAST];

            List<productDataWithPriceBook> productDataWithPriceBooksList = new List<productDataWithPriceBook>();

            for (PricebookEntry pbe : listOfProducts){
                if (!priceBookIdVSPricebookEntries.containsKey(pbe.PriceBook2.Id)) {
                    priceBookIdVSPricebookEntries.put(pbe.PriceBook2.Id, new List<PricebookEntry>());
                }
                priceBookIdVSPricebookEntries.get(pbe.PriceBook2.Id).add(pbe);
            }

            for (Pricebook2 pb : listOfPricebooks){
                productDataWithPriceBook productInstance = new productDataWithPriceBook();
                productInstance.pb2 = pb;
                productInstance.pbeList = priceBookIdVSPricebookEntries.get(pb.Id);
                productDataWithPriceBooksList.add(productInstance);
            }
            //System.debug(JSON.serialize(pricebookVSPriceBookEntry));
            List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();
            leadProducts = [SELECT Id,Discount__c,Item_Price__c,Lead__c,Name,Pricebook_Id__c,Is_subscription__c,Plan_handle__c,CurrencyIsoCode,PricebookEntry_Id__c,Product_Id__c,Product_Name__c,Quantity__c,Partner_Provision_Value__c,Partner_Sales_Value__c,Provision_Base__c FROM LeadProducts__c WHERE Lead__c =: leadId];
            String defaultCurrency = UserInfo.getDefaultCurrency();
            List<User> userList = new List<User>();
            userList = [SELECT Id,DefaultCurrencyIsoCode From User];

             //Chnages Start DFJ-43

            Currency_Configurater__mdt currencyConfigurationMetadata = Currency_Configurater__mdt.getInstance(leadRecord.Market_Unit__c);
            //End
            productWithLeadProduct productInstance = new productWithLeadProduct();
            productInstance.leadProducts = leadProducts;
            productInstance.productData = productDataWithPriceBooksList;
            productInstance.DefaultCurrencyIsoCode = defaultCurrency;
            productInstance.currencyAccordingMarketUnit = currencyConfigurationMetadata.CurrencyIsoCode__c;
            return productInstance;

        } catch (DmlException ex) {
            throw new AuraHandledException('Error==>' + ex.getMessage() + 'at line number==>' + ex.getLineNumber());
        }
    }

    //New Changes add method for upert Fixed discount Value on Lead
    @AuraEnabled
    public static Lead insertFixedDiscountinLead_Apex(Lead leadRecord){
        try {
            if(leadRecord != null){
                upsert leadRecord;
                return leadRecord;
            }
           return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Lead> returnFixedDiscountValue_Apex(String leadId){
        try {
            if(leadId != null){
               List<Lead> leadList = new List<Lead>();
               leadList = [SELECT Id, Fixed_discount_Type__c FROM Lead Where Id =: leadId];
               return leadList;

            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     //DFJ-340 Changes Start
    @AuraEnabled
    public static Integer getOrderCategorySize(Id leadId) {
        try{
            if(leadId != null){
                Lead ld = [SELECT Id, Market_Unit__c FROM Lead WHERE Id = :leadId];
            List<Order_Category_Definition__c> orderCategoryList = [SELECT Id FROM Order_Category_Definition__c WHERE Order_Category_Type__c = 'Product Bundle' AND Is_Active__c = true AND Market_Unit__c = :ld.Market_Unit__c];
            return orderCategoryList.size();
            }
            return null;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    //DFJ-340 Changes End
    
    public class productWithLeadProduct{
        @AuraEnabled public List<LeadProducts__c> leadProducts;
        @AuraEnabled public List<productDataWithPriceBook> productData;

        @AuraEnabled public String DefaultCurrencyIsoCode;
        @AuraEnabled public String currencyAccordingMarketUnit;

    }
    public class productDataWithPriceBook{
        @AuraEnabled public Pricebook2 pb2;
        @AuraEnabled public List<PricebookEntry> pbeList;
    }

    
}