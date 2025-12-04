/**
 * Trigger to normalize phone numbers on Lead records.
 * Runs asynchronously after insert/update to avoid DML issues.
 * 
 * Normalized Fields:
 * - MobilePhone
 * - Phone
 * - Phone2__c
 * - Phone3__c
 */
trigger LeadPhoneTrigger on Lead (after insert, after update) {
    
    // Phone fields to normalize on Lead
    List<String> phoneFields = new List<String>{
        'MobilePhone',
        'Phone',
        'Phone2__c',
        'Phone3__c'
    };
    
    // Collect Lead snapshots that need phone normalization
    List<Lead> leadsToNormalize = new List<Lead>();
    
    for (Lead record : Trigger.new) {
        Boolean needsNormalization = false;
        
        if (Trigger.isInsert) {
            // Check if any phone field is not null on insert
            if (String.isNotBlank(record.MobilePhone) ||
                String.isNotBlank(record.Phone) ||
                String.isNotBlank(record.Phone2__c) ||
                String.isNotBlank(record.Phone3__c)) {
                needsNormalization = true;
            }
        } else if (Trigger.isUpdate) {
            // Check if any phone field has changed on update
            Lead oldRecord = Trigger.oldMap.get(record.Id);
            
            if (record.MobilePhone != oldRecord.MobilePhone ||
                record.Phone != oldRecord.Phone ||
                record.Phone2__c != oldRecord.Phone2__c ||
                record.Phone3__c != oldRecord.Phone3__c) {
                needsNormalization = true;
            }
        }
        
        if (needsNormalization) {
            Lead snapshot = new Lead(
                Id = record.Id,
                Market_Unit__c = record.Market_Unit__c,
                Country = record.Country,
                MobilePhone = record.MobilePhone,
                Phone = record.Phone,
                Phone2__c = record.Phone2__c,
                Phone3__c = record.Phone3__c
            );
            leadsToNormalize.add(snapshot);
        }
    }
    
    // Execute async normalization if we have records to process
    // Prevent execution if already in async context (future/batch/queueable)
    if (!leadsToNormalize.isEmpty() && !System.isFuture() && !System.isBatch() && !System.isQueueable()) {
        System.enqueueJob(new PhoneFieldNormalizer('Lead', leadsToNormalize, phoneFields));
    }
}