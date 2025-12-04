/**
 * Trigger to normalize phone numbers on Account records.
 * Runs asynchronously after insert/update to avoid DML issues.
 * 
 * Normalized Fields (Business Accounts):
 * - Phone
 * 
 * Normalized Fields (Person Accounts):
 * - PersonAssistantPhone
 * - PersonHomePhone
 * - PersonMobilePhone
 * - PersonOtherPhone
 * - Phone
 * - Spouse_Phone__pc
 */
trigger AccountPhoneTrigger on Account (after insert, after update) {
    
    // Phone fields to normalize on Account
    // Note: Person Account fields are only processed for Person Accounts
    List<String> phoneFields = new List<String>{
        'Phone',
        'PersonAssistantPhone',
        'PersonHomePhone',
        'PersonMobilePhone',
        'PersonOtherPhone',
        'Spouse_Phone__pc'
    };
    
    // Collect Account snapshots that need phone normalization
    List<Account> accountsToNormalize = new List<Account>();
    
    for (Account record : Trigger.new) {
        Boolean needsNormalization = false;
        
        if (Trigger.isInsert) {
            // Check if any phone field is not null on insert
            if (String.isNotBlank(record.Phone)) {
                needsNormalization = true;
            }
            
            // Check Person Account fields only for Person Accounts
            if (record.IsPersonAccount) {
                if (String.isNotBlank(record.PersonAssistantPhone) ||
                    String.isNotBlank(record.PersonHomePhone) ||
                    String.isNotBlank(record.PersonMobilePhone) ||
                    String.isNotBlank(record.PersonOtherPhone) ||
                    String.isNotBlank(record.Spouse_Phone__pc)) {
                    needsNormalization = true;
                }
            }
        } else if (Trigger.isUpdate) {
            // Check if any phone field has changed on update
            Account oldRecord = Trigger.oldMap.get(record.Id);
            
            if (record.Phone != oldRecord.Phone) {
                needsNormalization = true;
            }
            
            // Check Person Account fields only for Person Accounts
            if (record.IsPersonAccount) {
                if (record.PersonAssistantPhone != oldRecord.PersonAssistantPhone ||
                    record.PersonHomePhone != oldRecord.PersonHomePhone ||
                    record.PersonMobilePhone != oldRecord.PersonMobilePhone ||
                    record.PersonOtherPhone != oldRecord.PersonOtherPhone ||
                    record.Spouse_Phone__pc != oldRecord.Spouse_Phone__pc) {
                    needsNormalization = true;
                }
            }
        }
        
        if (needsNormalization) {
            Account snapshot = new Account(
                Id = record.Id,
                Market_Unit__c = record.Market_Unit__c,
                BillingCountry = record.BillingCountry,
                ShippingCountry = record.ShippingCountry,
                Phone = record.Phone,
                PersonAssistantPhone = record.PersonAssistantPhone,
                PersonHomePhone = record.PersonHomePhone,
                PersonMobilePhone = record.PersonMobilePhone,
                PersonOtherPhone = record.PersonOtherPhone,
                Spouse_Phone__pc = record.Spouse_Phone__pc
            );
            accountsToNormalize.add(snapshot);
        }
    }
    
    // Execute async normalization if we have records to process
    // Prevent execution if already in async context (future/batch/queueable)
    if (!accountsToNormalize.isEmpty() && !System.isFuture() && !System.isBatch() && !System.isQueueable()) {
        System.enqueueJob(new PhoneFieldNormalizer('Account', accountsToNormalize, phoneFields));
    }
}