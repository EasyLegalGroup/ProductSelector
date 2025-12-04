/**
 * @description Wrapper class for test data generation results
 * @author Copilot
 * @date 2025
 */
public class TestDataResult {
    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public String message;
    @AuraEnabled public Integer leadsCreated;
    @AuraEnabled public Integer accountsCreated;
    @AuraEnabled public Integer ordersCreated;
    @AuraEnabled public Integer journalsCreated;
    @AuraEnabled public List<String> progressLog;
    @AuraEnabled public List<String> errorLog;
    @AuraEnabled public List<String> warningLog;
    @AuraEnabled public List<CreatedRecord> createdRecords;
    
    public TestDataResult() {
        this.isSuccess = false;
        this.message = '';
        this.leadsCreated = 0;
        this.accountsCreated = 0;
        this.ordersCreated = 0;
        this.journalsCreated = 0;
        this.progressLog = new List<String>();
        this.errorLog = new List<String>();
        this.warningLog = new List<String>();
        this.createdRecords = new List<CreatedRecord>();
    }
    
    /**
     * @description Inner class for created record details
     */
    public class CreatedRecord {
        @AuraEnabled public String recordType;
        @AuraEnabled public String recordId;
        @AuraEnabled public String recordName;
        
        public CreatedRecord(String type, String id, String name) {
            this.recordType = type;
            this.recordId = id;
            this.recordName = name;
        }
    }
}