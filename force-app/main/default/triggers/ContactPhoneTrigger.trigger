/**
 * Trigger to normalize phone numbers on Contact records.
 * Runs asynchronously after insert/update to avoid DML issues.
 * 
 * Normalized Fields:
 * - AssistantPhone
 * - HomePhone
 * - MobilePhone
 * - OtherPhone
 * - Phone
 * - Spouse_Phone__c
 */
trigger ContactPhoneTrigger on Contact (after insert, after update) {
    
    // Phone fields to normalize on Contact
    List<String> phoneFields = new List<String>{
        'AssistantPhone',
        'HomePhone',
        'MobilePhone',
        'OtherPhone',
        'Phone',
        'Spouse_Phone__c'
    };
    
    // Collect Contact snapshots that need phone normalization
    List<Contact> contactsToNormalize = new List<Contact>();
    
    for (Contact record : Trigger.new) {
        Boolean needsNormalization = false;
        
        if (Trigger.isInsert) {
            // Check if any phone field is not null on insert
            if (String.isNotBlank(record.AssistantPhone) ||
                String.isNotBlank(record.HomePhone) ||
                String.isNotBlank(record.MobilePhone) ||
                String.isNotBlank(record.OtherPhone) ||
                String.isNotBlank(record.Phone) ||
                String.isNotBlank(record.Spouse_Phone__c)) {
                needsNormalization = true;
            }
        } else if (Trigger.isUpdate) {
            // Check if any phone field has changed on update
            Contact oldRecord = Trigger.oldMap.get(record.Id);
            
            if (record.AssistantPhone != oldRecord.AssistantPhone ||
                record.HomePhone != oldRecord.HomePhone ||
                record.MobilePhone != oldRecord.MobilePhone ||
                record.OtherPhone != oldRecord.OtherPhone ||
                record.Phone != oldRecord.Phone ||
                record.Spouse_Phone__c != oldRecord.Spouse_Phone__c) {
                needsNormalization = true;
            }
        }
        
        if (needsNormalization) {
            Contact snapshot = new Contact(
                Id = record.Id,
                Market_Unit__c = record.Market_Unit__c,
                MailingCountry = record.MailingCountry,
                OtherCountry = record.OtherCountry,
                AssistantPhone = record.AssistantPhone,
                HomePhone = record.HomePhone,
                MobilePhone = record.MobilePhone,
                OtherPhone = record.OtherPhone,
                Phone = record.Phone,
                Spouse_Phone__c = record.Spouse_Phone__c
            );
            contactsToNormalize.add(snapshot);
        }
    }
    
    // Execute async normalization if we have records to process
    // Prevent execution if already in async context (future/batch/queueable)
    if (!contactsToNormalize.isEmpty() && !System.isFuture() && !System.isBatch() && !System.isQueueable()) {
        System.enqueueJob(new PhoneFieldNormalizer('Contact', contactsToNormalize, phoneFields));
    }
}