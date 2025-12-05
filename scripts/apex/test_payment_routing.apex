// Test Payment Routing - Run this in Anonymous Apex to diagnose payment key routing
// This script tests WITHOUT making actual API calls to Reepay

System.debug('========================================');
System.debug('=== PAYMENT ROUTING DIAGNOSTIC TEST ===');
System.debug('========================================');

// 1. Check Org Identity
System.debug('\n--- ORG IDENTITY ---');
String currentOrgId = UserInfo.getOrganizationId();
String productionOrgId = PS_PaymentUtility.PRODUCTION_ORG_ID;
Boolean isProduction = PS_PaymentUtility.isProductionOrg();
Boolean useTestMode = PS_PaymentUtility.shouldUseTestMode();

System.debug('Current Org ID: ' + currentOrgId);
System.debug('Production Org ID: ' + productionOrgId);
System.debug('Org ID starts with Production ID: ' + currentOrgId.startsWith(productionOrgId));
System.debug('isProductionOrg(): ' + isProduction);
System.debug('shouldUseTestMode(): ' + useTestMode);

// 2. Check Price_Book__mdt Configuration
System.debug('\n--- PRICE_BOOK__MDT CONFIGURATION ---');
List<Price_Book__mdt> allConfigs = [
    SELECT DeveloperName, Internal_Identifier__c, 
           Encoded_Private_Key__c, Test_Encoded_Private_Key__c,
           Custom_Permission__c
    FROM Price_Book__mdt
];

for (Price_Book__mdt config : allConfigs) {
    System.debug('');
    System.debug('Config: ' + config.DeveloperName);
    System.debug('  Internal_Identifier__c: ' + config.Internal_Identifier__c);
    System.debug('  Has Encoded_Private_Key__c: ' + String.isNotBlank(config.Encoded_Private_Key__c));
    System.debug('  Has Test_Encoded_Private_Key__c: ' + String.isNotBlank(config.Test_Encoded_Private_Key__c));
    if (String.isNotBlank(config.Encoded_Private_Key__c)) {
        System.debug('  Prod Key (first 30 chars): ' + config.Encoded_Private_Key__c.substring(0, Math.min(30, config.Encoded_Private_Key__c.length())) + '...');
    }
    if (String.isNotBlank(config.Test_Encoded_Private_Key__c)) {
        System.debug('  Test Key (first 30 chars): ' + config.Test_Encoded_Private_Key__c.substring(0, Math.min(30, config.Test_Encoded_Private_Key__c.length())) + '...');
    }
}

// 3. Check Pricebook2 records
System.debug('\n--- PRICEBOOK2 RECORDS ---');
List<Pricebook2> pricebooks = [
    SELECT Id, Name, Internal_Identifier__c, IsActive
    FROM Pricebook2
    WHERE Internal_Identifier__c != null
    ORDER BY Name
];

for (Pricebook2 pb : pricebooks) {
    System.debug('');
    System.debug('Pricebook: ' + pb.Name);
    System.debug('  Id: ' + pb.Id);
    System.debug('  Internal_Identifier__c: ' + pb.Internal_Identifier__c);
    System.debug('  IsActive: ' + pb.IsActive);
    
    // Check if it maps to a Price_Book__mdt
    Boolean hasConfig = false;
    for (Price_Book__mdt config : allConfigs) {
        if (config.Internal_Identifier__c == pb.Internal_Identifier__c) {
            hasConfig = true;
            System.debug('  -> Maps to Price_Book__mdt: ' + config.DeveloperName);
            break;
        }
    }
    if (!hasConfig) {
        System.debug('  WARNING: No matching Price_Book__mdt found!');
    }
}

// 4. Test the Lead in question
System.debug('\n--- TEST LEAD 00QG500000Oo0AHMAZ ---');
List<Lead> testLeads = [
    SELECT Id, Name, Email, Market_Unit__c
    FROM Lead
    WHERE Id = '00QG500000Oo0AHMAZ'
    LIMIT 1
];

if (!testLeads.isEmpty()) {
    Lead l = testLeads[0];
    System.debug('Lead found: ' + l.Name);
    System.debug('Email: ' + l.Email);
    System.debug('Market_Unit__c: ' + l.Market_Unit__c);
    
    // Check for associated Payments
    List<Payments__c> payments = [
        SELECT Id, Name, Status__c, Pricebook2Id__c, CurrencyIsoCode,
               Lead__c, Invoice_id__c, Reepay_ID__c, Error_message__c,
               CreatedDate
        FROM Payments__c
        WHERE Lead__c = :l.Id
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    
    System.debug('Recent Payments for this Lead: ' + payments.size());
    for (Payments__c p : payments) {
        System.debug('');
        System.debug('  Payment: ' + p.Name);
        System.debug('  Status: ' + p.Status__c);
        System.debug('  Pricebook2Id__c: ' + p.Pricebook2Id__c);
        System.debug('  CurrencyIsoCode: ' + p.CurrencyIsoCode);
        System.debug('  Invoice_id__c: ' + p.Invoice_id__c);
        System.debug('  Reepay_ID__c: ' + p.Reepay_ID__c);
        System.debug('  Error_message__c: ' + p.Error_message__c);
        System.debug('  Created: ' + p.CreatedDate);
        
        if (p.Pricebook2Id__c != null) {
            // Test the key routing for this payment
            try {
                String key = PS_PaymentService.getReepayPrivateKeyByPricebook(p.Pricebook2Id__c);
                System.debug('  Key returned (first 30): ' + key.substring(0, Math.min(30, key.length())) + '...');
            } catch (Exception e) {
                System.debug('  ERROR getting key: ' + e.getMessage());
            }
        } else {
            System.debug('  WARNING: No Pricebook2Id__c set on Payment!');
        }
    }
    
    // Check LeadProducts
    List<LeadProducts__c> leadProducts = [
        SELECT Id, Name, Pricebook_Id__c, Product_Name__c
        FROM LeadProducts__c
        WHERE Lead__c = :l.Id
        LIMIT 10
    ];
    System.debug('\nLead Products: ' + leadProducts.size());
    for (LeadProducts__c lp : leadProducts) {
        System.debug('  ' + lp.Product_Name__c + ' - Pricebook: ' + lp.Pricebook_Id__c);
    }
} else {
    System.debug('Lead not found with ID 00QG500000Oo0AHMAZ');
}

// 5. Check Log__c for recent errors
System.debug('\n--- RECENT LOG ENTRIES ---');
List<Log__c> recentLogs = [
    SELECT Id, Event__c, Message__c, Error_Message__c, Severity__c, Source__c, CreatedDate
    FROM Log__c
    WHERE Source__c LIKE '%Payment%' OR Source__c LIKE '%Reepay%'
    ORDER BY CreatedDate DESC
    LIMIT 10
];

System.debug('Recent payment-related logs: ' + recentLogs.size());
for (Log__c log : recentLogs) {
    System.debug('');
    System.debug('  ' + log.CreatedDate + ' [' + log.Severity__c + '] ' + log.Event__c);
    System.debug('  Source: ' + log.Source__c);
    if (String.isNotBlank(log.Message__c)) {
        System.debug('  Message: ' + log.Message__c.substring(0, Math.min(200, log.Message__c.length())));
    }
    if (String.isNotBlank(log.Error_Message__c)) {
        System.debug('  Error: ' + log.Error_Message__c.substring(0, Math.min(200, log.Error_Message__c.length())));
    }
}

System.debug('\n========================================');
System.debug('=== END DIAGNOSTIC TEST ===');
System.debug('========================================');
