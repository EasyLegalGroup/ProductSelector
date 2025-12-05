// Simulate creating a new payment and invoice for the test Lead
// This bypasses the UI to test the Apex logic directly

String leadId = '00QG500000Oo0AHMAZ';

// First, get the Lead data
Lead testLead = [
    SELECT Id, Name, Email, Phone, Street, City, PostalCode, 
           Market_Unit__c, FirstName, LastName
    FROM Lead 
    WHERE Id = :leadId 
    LIMIT 1
];

System.debug('Testing with Lead: ' + testLead.Name);
System.debug('Email: ' + testLead.Email);
System.debug('Market_Unit__c: ' + testLead.Market_Unit__c);

// Get the LeadProducts to determine pricebook
List<LeadProducts__c> leadProducts = [
    SELECT Id, Pricebook_Id__c, Product_Name__c, Item_Price__c, Quantity__c
    FROM LeadProducts__c
    WHERE Lead__c = :leadId
    LIMIT 10
];

if (leadProducts.isEmpty()) {
    System.debug('ERROR: No LeadProducts found for this Lead!');
} else {
    System.debug('Lead has ' + leadProducts.size() + ' products');
    Id pricebookId = leadProducts[0].Pricebook_Id__c;
    System.debug('Using Pricebook: ' + pricebookId);
    
    // Test 1: Check if customer exists in Reepay
    System.debug('');
    System.debug('=== Step 1: Check Customer ===');
    String checkResult = DFJ_PaymentController.checkCustomerAlreadyCreated(testLead.Email, pricebookId);
    System.debug('checkCustomerAlreadyCreated result: ' + checkResult);
    
    if (checkResult == 'Not found') {
        // Test 2: Create the customer
        System.debug('');
        System.debug('=== Step 2: Create Customer ===');
        List<Lead> leadList = new List<Lead>{testLead};
        PS_PaymentUtility.CustomerResponseWrapper createResult = 
            DFJ_PaymentController.createReepayCustomer(null, leadList, null, pricebookId, 'Lead');
        
        if (String.isNotBlank(createResult.error)) {
            System.debug('ERROR creating customer: ' + createResult.error);
        } else {
            System.debug('SUCCESS: ' + createResult.message);
        }
    } else if (checkResult == 'Found') {
        System.debug('Customer already exists in Reepay - good!');
    } else {
        System.debug('Unexpected result from checkCustomerAlreadyCreated: ' + checkResult);
    }
    
    // Test 3: Create a test payment record
    System.debug('');
    System.debug('=== Step 3: Create Payment Record (SF only, no Reepay) ===');
    Payments__c testPayment = new Payments__c();
    testPayment.Lead__c = leadId;
    testPayment.Amount__c = 100;
    testPayment.CurrencyIsoCode = 'DKK';
    testPayment.Pricebook2Id__c = pricebookId;
    testPayment.Billing_email__c = testLead.Email;
    testPayment.Billing_name__c = testLead.Name;
    testPayment.Status__c = 'Created';
    testPayment.Payment_type__c = 'Onetime';
    
    // Don't actually insert - just check if we can build the invoice request
    System.debug('Would create Payment with Pricebook2Id__c: ' + testPayment.Pricebook2Id__c);
    
    // Test 4: Verify the private key would be retrieved correctly
    System.debug('');
    System.debug('=== Step 4: Verify Key Retrieval ===');
    try {
        String key = PS_PaymentService.getReepayPrivateKeyByPricebook(pricebookId);
        System.debug('Key retrieved successfully');
        System.debug('Key prefix: ' + key.substring(0, 30) + '...');
        
        // Decode to verify format
        Blob decoded = EncodingUtil.base64Decode(key);
        String decodedStr = decoded.toString();
        System.debug('Decoded key starts with: ' + decodedStr.substring(0, 20) + '...');
        
        if (decodedStr.startsWith('priv_')) {
            System.debug('✓ Key format is correct for Reepay');
        } else {
            System.debug('✗ Key format may be incorrect');
        }
    } catch (Exception e) {
        System.debug('ERROR getting key: ' + e.getMessage());
    }
    
    System.debug('');
    System.debug('=== SUMMARY ===');
    System.debug('If all steps above succeeded, the Apex code is working correctly.');
    System.debug('The issue may be in the LWC/Aura component that calls createPaymentRelatedRecords.');
    System.debug('Enable Debug Logs in Developer Console and try creating a payment from the UI.');
}
