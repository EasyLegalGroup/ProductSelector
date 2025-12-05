// Test Actual Reepay API Call - Run this in Anonymous Apex
// This WILL attempt to make a real API call to Reepay test environment

System.debug('========================================');
System.debug('=== REEPAY API CONNECTION TEST ===');
System.debug('========================================');

// Get the test lead's payment
String leadId = '00QG500000Oo0AHMAZ';
List<Payments__c> payments = [
    SELECT Id, Name, Status__c, Pricebook2Id__c, CurrencyIsoCode, Lead__c, 
           Billing_email__c, Amount__c, Invoice_id__c
    FROM Payments__c
    WHERE Lead__c = :leadId
    ORDER BY CreatedDate DESC
    LIMIT 1
];

if (payments.isEmpty()) {
    System.debug('ERROR: No payments found for Lead');
} else {
    Payments__c payment = payments[0];
    System.debug('Testing with Payment: ' + payment.Name);
    System.debug('Pricebook2Id__c: ' + payment.Pricebook2Id__c);
    
    if (payment.Pricebook2Id__c == null) {
        System.debug('ERROR: Payment has no Pricebook2Id__c set!');
    } else {
        try {
            // Get the private key
            String privateKey = PS_PaymentService.getReepayPrivateKeyByPricebook(payment.Pricebook2Id__c);
            System.debug('Got private key (first 30 chars): ' + privateKey.substring(0, 30) + '...');
            
            // Test API connection by checking if customer exists
            String email = payment.Billing_email__c;
            if (String.isBlank(email)) {
                // Get email from lead
                Lead l = [SELECT Email FROM Lead WHERE Id = :leadId LIMIT 1];
                email = l.Email;
            }
            System.debug('Testing with email: ' + email);
            
            // Make a test call to check customer
            String endpoint = 'https://api.reepay.com/v1/customer/' + EncodingUtil.urlEncode(email, 'UTF-8');
            System.debug('Calling endpoint: ' + endpoint);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Basic ' + privateKey);
            req.setHeader('Accept', 'application/json');
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('');
            System.debug('=== REEPAY API RESPONSE ===');
            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Status: ' + res.getStatus());
            System.debug('Body: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                System.debug('SUCCESS: Customer exists in Reepay');
            } else if (res.getStatusCode() == 404) {
                System.debug('INFO: Customer does not exist in Reepay (will be created on payment)');
            } else if (res.getStatusCode() == 401) {
                System.debug('ERROR: Authentication failed - API key may be invalid');
            } else if (res.getStatusCode() == 403) {
                System.debug('ERROR: Forbidden - API key may not have proper permissions');
            } else {
                System.debug('WARNING: Unexpected response code');
            }
            
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
}

// Also test by decoding the API key to verify it's valid
System.debug('');
System.debug('=== VERIFY API KEY FORMAT ===');
List<Price_Book__mdt> configs = [
    SELECT DeveloperName, Test_Encoded_Private_Key__c 
    FROM Price_Book__mdt 
    WHERE DeveloperName = 'Din_Familiejurist'
];

if (!configs.isEmpty() && String.isNotBlank(configs[0].Test_Encoded_Private_Key__c)) {
    String encodedKey = configs[0].Test_Encoded_Private_Key__c;
    try {
        // Decode the Base64 key to see what it looks like
        Blob decodedBlob = EncodingUtil.base64Decode(encodedKey);
        String decodedString = decodedBlob.toString();
        System.debug('Decoded key format: ' + decodedString.substring(0, Math.min(20, decodedString.length())) + '...');
        
        // Check if it starts with 'priv_' which is the Reepay private key format
        if (decodedString.startsWith('priv_')) {
            System.debug('Key format looks correct (starts with priv_)');
        } else {
            System.debug('WARNING: Key does not start with priv_ - may be invalid format');
        }
    } catch (Exception e) {
        System.debug('ERROR decoding key: ' + e.getMessage());
    }
}

System.debug('');
System.debug('========================================');
System.debug('=== END API CONNECTION TEST ===');
System.debug('========================================');
