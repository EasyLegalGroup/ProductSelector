// Check recent Log__c entries for payment errors
System.debug('=== RECENT LOG ENTRIES ===');

// Get all recent logs, not just payment-related
List<Log__c> recentLogs = [
    SELECT Id, Event__c, Message__c, Error_Message__c, Severity__c, Source__c, 
           Stack_trace__c, Line_Number__c, Affected_Record__c, CreatedDate
    FROM Log__c
    ORDER BY CreatedDate DESC
    LIMIT 20
];

System.debug('Total recent logs: ' + recentLogs.size());
for (Log__c log : recentLogs) {
    System.debug('');
    System.debug('--- Log Entry ---');
    System.debug('Created: ' + log.CreatedDate);
    System.debug('Severity: ' + log.Severity__c);
    System.debug('Event: ' + log.Event__c);
    System.debug('Source: ' + log.Source__c);
    System.debug('Affected Record: ' + log.Affected_Record__c);
    if (String.isNotBlank(log.Message__c)) {
        System.debug('Message: ' + log.Message__c);
    }
    if (String.isNotBlank(log.Error_Message__c)) {
        System.debug('Error Message: ' + log.Error_Message__c);
    }
    if (String.isNotBlank(log.Stack_trace__c)) {
        System.debug('Stack Trace: ' + log.Stack_trace__c);
    }
}

// Also check the Payment record's error message
List<Payments__c> recentPayments = [
    SELECT Id, Name, Status__c, Error_message__c, Transaction_error__c, 
           Invoice_id__c, Reepay_ID__c, CreatedDate
    FROM Payments__c
    WHERE Lead__c = '00QG500000Oo0AHMAZ'
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('');
System.debug('=== RECENT PAYMENTS FOR TEST LEAD ===');
for (Payments__c p : recentPayments) {
    System.debug('');
    System.debug('Payment: ' + p.Name + ' (Created: ' + p.CreatedDate + ')');
    System.debug('Status: ' + p.Status__c);
    System.debug('Invoice_id__c: ' + p.Invoice_id__c);
    System.debug('Reepay_ID__c: ' + p.Reepay_ID__c);
    System.debug('Error_message__c: ' + p.Error_message__c);
    System.debug('Transaction_error__c: ' + p.Transaction_error__c);
}
