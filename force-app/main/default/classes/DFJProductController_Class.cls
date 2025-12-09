/*
 * @Author : Kajal Verma
 * @Date : 06/11/2025
 * @Description
 */
public without sharing class DFJProductController_Class {
    private static List<String> fieldsList;
    private static String condition;
    private static String limitVar;
    private static Map<String, List<String>> objFieldMap = new Map<String, List<String>>{
        'Lead' => new List<String>{'telegenta__Forecast__c','Fixed_discount_Type__c','Id'},
        'Opportunity' => new List<String>{'Order_Total__c', 'Fixed_Discount_Type__c'}
    };
    
    public static Boolean updateRecord_Apex(String recordId, Map<String, Object> fieldValuesMap, String objectApiName) {
        try{
            SObject obj = Schema.getGlobalDescribe().get(objectApiName).newSObject(recordId);
            for(String objField : objFieldMap.get(objectApiName)){
                if(fieldValuesMap.containsKey(objField)){
                    obj.put(objField, fieldValuesMap.get(objField));
                }
            }
            Update obj;
            return true;
        }
        catch(DmlException ex){
            return false;
        }
    }
    
    public static List<sObject> insertRecords_Apex(List<Object> newProductList, String recordId, Decimal total, String objectApiName){
        try {
            if(objectApiName == 'Lead' && recordId != null && objectApiName != null){
                Map<String, Object> forecastMap = new Map<String, Object>();
                forecastMap.put('telegenta__Forecast__c', total);
                updateRecord_Apex(recordId, forecastMap, objectApiName);
            }
            List<sObject> productLineItems = new List<sObject>();
            List<LeadProducts__c> leadProductList = new List<LeadProducts__c>();
            List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
            String jsonString = JSON.serialize(newProductList);
            if(objectApiName == 'Lead') {
                leadProductList = (List<LeadProducts__c>) JSON.deserialize(jsonString, List<LeadProducts__c>.class);
            } else if (objectApiName == 'Opportunity') {
                oppLineItemList = (List<OpportunityLineItem>) JSON.deserialize(jsonString, List<OpportunityLineItem>.class);
            }
            if(!leadProductList.isEmpty()){
                upsert leadProductList;
                condition = 'Lead__c = \'' + recordId + '\'';
                limitVar = '';
                fieldsList = new List<String>{'Id', 'Discount__c', 'Item_Price__c', 'Lead__c', 'Name', 'Pricebook_Id__c',
                    'Is_subscription__c', 'Plan_handle__c', 'CurrencyIsoCode', 'PricebookEntry_Id__c', 'Product_Id__c',
                    'Product_Name__c', 'Quantity__c', 'Partner_Provision_Value__c', 'Partner_Sales_Value__c', 'Provision_Base__c'};  
                productLineItems = fetchRecordsDynamically(condition, fieldsList, 'LeadProducts__c', limitVar);
            }
            else if(!oppLineItemList.isEmpty()){
                upsert oppLineItemList;
                condition = 'OpportunityId = \'' + recordId + '\'';
                fieldsList = new List<String>{'Id', 'Discount', 'TotalPrice', 'ListPrice', 'UnitPrice', 'Net_Total_Price__c',
                    'Product2.Name', 'Pricebook_Id__c', 'Is_subscription__c', 'Plan_handle__c', 'PricebookEntryId',
                    'Product2Id', 'Quantity', 'Partner_Provision_Value__c', 'Partner_Sales_Value__c', 'Provision_Base__c', 'Opportunity.CurrencyIsoCode'};
                limitVar = '';
                productLineItems = fetchRecordsDynamically(condition, fieldsList, 'OpportunityLineItem', limitVar);
            }
            return productLineItems;
        } catch (DmlException e) {
            throw new AuraHandledException('Error::-->' + e.getMessage() + 'at line number::->' + e.getLineNumber());
        }
    }
    
    public static String deleteRecord_Apex(List<String> recordIds, String objectName){
        String recordDeleteStatus = '';
        try{
            condition = 'Id IN (' + '\'' + String.join(recordIds, '\',\'') + '\'' + ')';  
            System.debug('condition-->'+condition);
            fieldsList = new List<String>{'Id'};
            limitVar = '';
            List<sObject> objList = new List<sObject>();
            objList = fetchRecordsDynamically(condition, fieldsList, objectName, limitVar);
            System.debug('objList-->'+objList);
            Database.DeleteResult[] deleteResults = Database.delete(objList, false);
            for(Integer i = 0; i < deleteResults.size(); i++){
                if(deleteResults[i].isSuccess()){
                    recordDeleteStatus = 'Products Deleted Successfully';
                }else{
                    for(Database.Error err : deleteResults[i].getErrors()){
                        recordDeleteStatus = 'Failed to delete Id: ' + (String)objList[i].get('Id') + '. Error: ' + err.getMessage();
                    }
                }
            }
        }
        catch(DmlException ex){
            recordDeleteStatus = ex.getMessage()+'at line'+ ex.getLineNumber();
            throw new AuraHandledException(ex.getMessage()+'at line'+ ex.getLineNumber());
        }
        return recordDeleteStatus;
    }
    
    public static Integer getOrderCategorySize(String recordId, String objectApiName) {
        try{
            condition = 'Id = \'' + recordId + '\'';
            limitVar = '';
            fieldsList = new List<String>{'Id','Market_Unit__c'};
            List<sObject> objList = fetchRecordsDynamically(condition, fieldsList, objectApiName, limitVar);
            condition = 'Order_Category_Type__c = \'Product Bundle\' ' + 'AND Is_Active__c = true AND Market_Unit__c = \'' + (String)objList[0].get('Market_Unit__c') + '\'';
            fieldsList = new List<String>{'Id'};
            List<Order_Category_Definition__c> orderCategoryList = new List<Order_Category_Definition__c>();
            orderCategoryList = fetchRecordsDynamically(condition, fieldsList, 'Order_Category_Definition__c', limitVar);
            return orderCategoryList.size();
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * Gets the pricebook identifiers the current user has access to based on custom permissions.
     * Queries Price_Book__mdt CMDT records and checks each custom permission.
     * @return Set of Internal_Identifier__c values the user can access
     */
    public static Set<String> getAccessiblePricebookIdentifiers() {
        Set<String> accessibleIdentifiers = new Set<String>();
        
        // Query all Price_Book__mdt records
        List<Price_Book__mdt> priceBookConfigs = [SELECT Custom_Permission__c, Internal_Identifier__c FROM Price_Book__mdt];
        
        // Check which custom permissions the user has
        for (Price_Book__mdt config : priceBookConfigs) {
            if (String.isNotBlank(config.Custom_Permission__c) && 
                FeatureManagement.checkPermission(config.Custom_Permission__c)) {
                accessibleIdentifiers.add(config.Internal_Identifier__c);
            }
        }
        
        return accessibleIdentifiers;
    }
    
    public static ProductsWrapper getAllPriceBookAndProducts(String recordId, String objectApiName){
        return getAllPriceBookAndProducts(recordId, objectApiName, null);
    }
    
    public static ProductsWrapper getAllPriceBookAndProducts(String recordId, String objectApiName, String defaultPriceBookIdentifier){
        try {
            Map<Id, Pricebook2> IdVSPricebook2s = new Map<Id, Pricebook2>();
            Map<Id, List<PricebookEntry>> priceBookIdVSPricebookEntries = new Map<Id, List<PricebookEntry>>();
            Map<Pricebook2, List<PricebookEntry>> pricebookVSPriceBookEntry = new Map<Pricebook2, List<PricebookEntry>>();
            List<Pricebook2> listOfPricebooks = new List<Pricebook2>();
            List<PricebookEntry> listOfProducts = new List<PricebookEntry>();
            
            // Get accessible pricebook identifiers based on custom permissions
            Set<String> accessibleIdentifiers = getAccessiblePricebookIdentifiers();
            
            if(objectApiName == 'Lead'){
                fieldsList = new List<String>{'Id', 'Market_Unit__c', 'Fixed_discount_Type__c'};
            }
            else if(objectApiName == 'Opportunity'){
                fieldsList = new List<String>{'Id', 'Market_Unit__c', 'Fixed_Discount_Type__c','Pricebook2Id', 'AccountId', 'Lead__c'};
            }
            condition = 'Id = \'' + recordId + '\'';
            limitVar = ' Limit 1';
            //Fetch current page record.
            List<sObject> objList = fetchRecordsDynamically(condition, fieldsList, objectApiName, limitVar);
            
            String marketUnitFilterValueToUseToFilterPricebooks = !objList.isEmpty() ? (String)objList[0].get('Market_Unit__c') : '';
            Currency_Configurater__mdt currencyConfigurationMetadata = Currency_Configurater__mdt.getInstance(marketUnitFilterValueToUseToFilterPricebooks);
            fieldsList = new List<String>{'Id', 'Name', 'CurrencyIsoCode', 'Internal_Identifier__c'};
            limitVar = ' Limit 10000';
            
            if(objectApiName == 'Lead'){
                // Check if user has any pricebook permissions
                if (accessibleIdentifiers.isEmpty()) {
                    throw new AuraHandledException('You do not have access to any Price Books. Please contact your administrator to request the appropriate permissions.');
                }
                
                // Build condition to filter by accessible pricebooks
                String identifierStr = '\'' + String.join(new List<String>(accessibleIdentifiers), '\',\'') + '\'';
                condition = 'IsActive = TRUE AND IsStandard = false AND Internal_Identifier__c IN (' + identifierStr + ')';
                
                // Also filter by Market_Unit if available
                if (String.isNotBlank(marketUnitFilterValueToUseToFilterPricebooks)) {
                    condition += ' AND Market_Unit__c = \'' + marketUnitFilterValueToUseToFilterPricebooks + '\'';
                }
            }
            else if(objectApiName == 'Opportunity'){
                Id existingPricebookId = (Id)objList[0].get('Pricebook2Id');
                
                if (existingPricebookId != null) {
                    // Opportunity already has a pricebook - check if user has access to it
                    List<Pricebook2> existingPb = [SELECT Id, Name, Internal_Identifier__c FROM Pricebook2 WHERE Id = :existingPricebookId LIMIT 1];
                    
                    if (!existingPb.isEmpty()) {
                        String pbIdentifier = existingPb[0].Internal_Identifier__c;
                        if (!accessibleIdentifiers.contains(pbIdentifier)) {
                            throw new AuraHandledException('You do not have the required permissions to use the Price Book "' + existingPb[0].Name + '". Please contact your administrator.');
                        }
                    }
                    
                    condition = 'Id = \'' + existingPricebookId + '\'';
                } else {
                    // No pricebook set - show accessible opportunity pricebooks
                    if (accessibleIdentifiers.isEmpty()) {
                        throw new AuraHandledException('You do not have access to any Price Books. Please contact your administrator to request the appropriate permissions.');
                    }
                    
                    String identifierStr = '\'' + String.join(new List<String>(accessibleIdentifiers), '\',\'') + '\'';
                    condition = 'IsActive = true AND IsStandard = false AND Internal_Identifier__c IN (' + identifierStr + ')';
                    
                    if (currencyConfigurationMetadata != null && String.isNotBlank(currencyConfigurationMetadata.CurrencyIsoCode__c)) {
                        condition += ' AND CurrencyIsoCode = \'' + currencyConfigurationMetadata.CurrencyIsoCode__c + '\'';
                    }
                }
            }
            //Get Pricebook2
            listOfPricebooks = fetchRecordsDynamically(condition, fieldsList, 'Pricebook2', limitVar);
            
            // For Lead: if no pricebooks found with Market_Unit filter, try without it
            if (objectApiName == 'Lead' && listOfPricebooks.isEmpty() && !accessibleIdentifiers.isEmpty()) {
                String identifierStr = '\'' + String.join(new List<String>(accessibleIdentifiers), '\',\'') + '\'';
                condition = 'IsActive = TRUE AND IsStandard = false AND Internal_Identifier__c IN (' + identifierStr + ')';
                listOfPricebooks = fetchRecordsDynamically(condition, fieldsList, 'Pricebook2', limitVar);
            }
            
            Set<Id> pricebook2Ids = new Set<Id>();
            for(Pricebook2 pbe : listOfPricebooks){
                pricebook2Ids.add(pbe.Id);
            }
            String idStr = '\'' + String.join(pricebook2Ids, '\',\'') + '\'';
            if(!pricebook2Ids.isEmpty()){
                condition = 'IsActive = true AND Product2.IsActive = true AND PriceBook2.Id IN (' + idStr + ') ORDER BY Sort_Key__c DESC NULLS LAST';
                limitVar = ' Limit 10000';
                fieldsList = new List<String>{'Id', 'PriceBook2.Id', 'Name', 'Product2.Name', 'Product2.CurrencyIsoCode', 'Product2.Plan__c',
                    'Product2.Is_subscription__c', 'Product2.ProductCode', 'PriceBook2.Name', 'PriceBook2.CurrencyIsoCode', 'IsActive', 
                    'Partner_provision_value__c', 'Partner_sales_value__c', 'Provision_base__c', 'convertCurrency(UnitPrice)'};
                listOfProducts = fetchRecordsDynamically(condition, fieldsList, 'PriceBookEntry', limitVar);
            }
            List<productDataWithPriceBook> productDataWithPriceBooksList = new List<productDataWithPriceBook>();
            for (PricebookEntry pbe : listOfProducts){
                if (!priceBookIdVSPricebookEntries.containsKey(pbe.PriceBook2.Id)) {
                    priceBookIdVSPricebookEntries.put(pbe.PriceBook2.Id, new List<PricebookEntry>());
                }
                priceBookIdVSPricebookEntries.get(pbe.PriceBook2.Id).add(pbe);
            }
            
            // Build maps of Internal_Identifier__c to Icon, VAT Rate, and Amount Includes VAT from Price_Book__mdt
            Map<String, String> identifierToIcon = new Map<String, String>();
            Map<String, Decimal> identifierToVatRate = new Map<String, Decimal>();
            Map<String, Boolean> identifierToAmountIncludesVat = new Map<String, Boolean>();
            for (Price_Book__mdt pbConfig : [SELECT Internal_Identifier__c, Icon__c, VAT_Rate__c, Amount_Includes_VAT__c FROM Price_Book__mdt]) {
                String icon = String.isNotBlank(pbConfig.Icon__c) ? pbConfig.Icon__c : 'standard:price_books';
                identifierToIcon.put(pbConfig.Internal_Identifier__c, icon);
                identifierToVatRate.put(pbConfig.Internal_Identifier__c, pbConfig.VAT_Rate__c);
                identifierToAmountIncludesVat.put(pbConfig.Internal_Identifier__c, pbConfig.Amount_Includes_VAT__c);
            }
            
            for (Pricebook2 pb : listOfPricebooks){
                productDataWithPriceBook productInstance = new productDataWithPriceBook();
                productInstance.pb2 = pb;
                productInstance.pbeList = priceBookIdVSPricebookEntries.get(pb.Id);
                // Set icon from CMDT, default to standard:price_books if not found
                productInstance.icon = identifierToIcon.containsKey(pb.Internal_Identifier__c) 
                    ? identifierToIcon.get(pb.Internal_Identifier__c) 
                    : 'standard:price_books';
                // Set VAT configuration from CMDT
                productInstance.vatRate = identifierToVatRate.get(pb.Internal_Identifier__c);
                productInstance.amountIncludesVat = identifierToAmountIncludesVat.containsKey(pb.Internal_Identifier__c)
                    ? identifierToAmountIncludesVat.get(pb.Internal_Identifier__c)
                    : true; // Default to true (prices include VAT) if not configured
                productDataWithPriceBooksList.add(productInstance);
            }
            List<sObject> childProducts = new List<sObject>();
            if(objectApiName == 'Lead'){
                condition = 'Lead__c = \'' + recordId + '\'';
                limitVar = '';
                fieldsList = new List<String>{'Id', 'Discount__c', 'Item_Price__c', 'Lead__c', 'Name', 'Pricebook_Id__c',
                    'Is_subscription__c', 'Plan_handle__c', 'CurrencyIsoCode', 'PricebookEntry_Id__c', 'Product_Id__c',
                    'Product_Name__c', 'Quantity__c', 'Partner_Provision_Value__c', 'Partner_Sales_Value__c', 'Provision_Base__c'};  
                childProducts = fetchRecordsDynamically(condition, fieldsList, 'LeadProducts__c', limitVar);
            }
            else if(objectApiName == 'Opportunity'){
                fieldsList = new List<String>{'Id', 'Discount', 'TotalPrice', 'ListPrice', 'UnitPrice', 'Net_Total_Price__c',
                    'Product2.Name', 'Pricebook_Id__c', 'Is_subscription__c', 'Plan_handle__c', 'PricebookEntryId',
                    'Product2Id', 'Quantity', 'Partner_Provision_Value__c', 'Partner_Sales_Value__c', 'Provision_Base__c', 'Opportunity.CurrencyIsoCode'};
                        condition = 'OpportunityId = \'' + recordId + '\'';
                limitVar = '';
                childProducts = fetchRecordsDynamically(condition, fieldsList, 'OpportunityLineItem', limitVar);
            }
            String defaultCurrency = UserInfo.getDefaultCurrency();
            ProductsWrapper productInstance = new ProductsWrapper();
            productInstance.childProductData = childProducts;
            productInstance.currentRecord = objList;
            productInstance.productData = productDataWithPriceBooksList;
            productInstance.DefaultCurrencyIsoCode = defaultCurrency;
            return productInstance;
        } catch (AuraHandledException ahe) {
            // Re-throw AuraHandledExceptions as-is (permission errors, etc.)
            throw ahe;
        } catch (Exception ex) {
            throw new AuraHandledException('Error==>' + ex.getMessage() + ' at line number==>' + ex.getLineNumber());
        }
    }
    
    /*
     * @Description : This method is used to make dynamic query and fetch the data.
     */ 
    public static List<SObject> fetchRecordsDynamically(String condition, List<String> fields, String objectName, String queryLimit) {
        try {
            if ( fields.isEmpty() || String.isBlank(objectName)) {
                return null;
            }
            String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName + (!String.isBlank(condition) ? ' WHERE ' + condition : '') + queryLimit;
            System.debug('query-->'+query);
            return Database.query(query);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Fetch records Dynamically.', ex.getMessage(), 'Error', 'DFJ_ProductSelectorForOpportunity_Apex.fetchRecordsDynamically', '', String.valueOf(ex.getLineNumber()));
            return null;
        }
    }
    
    public class ProductsWrapper {
        @AuraEnabled public String errorMessage;
        @AuraEnabled public List<sObject> childProductData;
        @AuraEnabled public List<sObject> currentRecord;
        @AuraEnabled public List<productDataWithPriceBook> productData;
        @AuraEnabled public String DefaultCurrencyIsoCode;
    }
    public class productDataWithPriceBook{
        @AuraEnabled public Pricebook2 pb2;
        @AuraEnabled public List<PricebookEntry> pbeList;
        @AuraEnabled public String icon;
        @AuraEnabled public Decimal vatRate; // VAT rate as decimal (e.g., 0.25 for 25%)
        @AuraEnabled public Boolean amountIncludesVat; // If true, prices already include VAT
    }
}