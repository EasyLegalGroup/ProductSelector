/*
 * @Author : Kajal Verma
 * @Date : 06/11/2025
 * @Description
 */
public class DFJProductService_Class {
    @AuraEnabled
    public static DFJProductController_Class.ProductsWrapper getAllThePricebooksAndProducts_Apex (String recordId, String objectApiName, String defaultPriceBookIdentifier){
        if (recordId == null || recordId.trim() == '' || objectApiName == null) {
            return null;
        }
        return DFJProductController_Class.getAllPriceBookAndProducts(recordId, objectApiName, defaultPriceBookIdentifier);
    }

	@AuraEnabled
    public static Integer getOrderCategorySize(String recordId, String objectApiName) {
        if (recordId == null || recordId.trim() == '' || objectApiName == null) {
            return null;
        }
        return DFJProductController_Class.getOrderCategorySize(recordId, objectApiName);
    }    
    
    @AuraEnabled
    public static String deleteRecord_Apex(List<String> recordIds, String objectApiName){
        if (recordIds.isEmpty() || objectApiName == null) {
            return null;
        }
        String objectName = objectApiName == 'Lead' ? 'LeadProducts__c' : objectApiName == 'Opportunity' ? 'OpportunityLineItem' : '';
        return DFJProductController_Class.deleteRecord_Apex(recordIds, objectName);
    }
    
    @AuraEnabled
    public static Boolean updateRecord_Apex(String recordId, Map<String, Object> fieldValuesMap, String objectApiName) {
        if (recordId == null || objectApiName == null || fieldValuesMap.isEmpty()) {
            return false;
        }
        System.debug('fieldValueMap-->'+fieldValuesMap);
        return DFJProductController_Class.updateRecord_Apex(recordId, fieldValuesMap, objectApiName);
    }
    
     @AuraEnabled
    public static List<sObject> insertRecords_Apex(List<Object> newProductList, String recordId, Decimal total, String objectApiName){
        if (recordId == null || newProductList.isEmpty()) {
            return null;
        }
        return DFJProductController_Class.insertRecords_Apex(newProductList, recordId, total, objectApiName);
    }
}