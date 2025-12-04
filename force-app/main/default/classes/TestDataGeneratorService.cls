/**
 * @description Service class to generate test data for sandbox initialization
 * @author Copilot
 * @date 2025
 * 
 * Generates:
 * - 20 Leads with various Market Units, Record Types, and Statuses
 * - 10 PersonAccounts (converted from 10 of the Leads)
 * - 13 Orders (10 PersonAccounts: 7 with 1 order, 3 with 2 orders)
 * - 13 Journals with bidirectional relationship to Orders
 */
public with sharing class TestDataGeneratorService {
    
    /**
     * @description LWC-callable method to generate test data
     */
    @AuraEnabled
    public static TestDataResult generateTestData() {
        List<TestDataResult> results = generateTestDataInternal();
        return results.isEmpty() ? new TestDataResult() : results[0];
    }
    
    /**
     * @description Invocable method for Flow/Process Builder
     */
    @InvocableMethod(
        label='Generate Test Data' 
        description='Generates test Leads, PersonAccounts, Orders, and Journals for sandbox testing'
        category='Test Data'
    )
    public static List<String> generateTestDataForFlow() {
        List<TestDataResult> results = generateTestDataInternal();
        List<String> messages = new List<String>();
        for (TestDataResult result : results) {
            messages.add(result.message);
        }
        return messages;
    }
    
    private static List<TestDataResult> generateTestDataInternal() {
        List<TestDataResult> results = new List<TestDataResult>();
        TestDataResult result = new TestDataResult();
        List<String> progressLog = new List<String>();
        List<String> errorLog = new List<String>();
        
        try {
            progressLog.add('Starting test data generation...');
            
            // Get Record Type IDs with validation
            progressLog.add('Validating Record Types...');
            Map<String, Id> leadRecordTypes = getLeadRecordTypes();
            Map<String, Id> accountRecordTypes = getAccountRecordTypes();
            
            if (leadRecordTypes.isEmpty()) {
                errorLog.add('No active Lead record types found');
            }
            if (accountRecordTypes.isEmpty()) {
                errorLog.add('No active Account record types found');
            }
            
            // Step 1: Generate Leads
            progressLog.add('Creating 20 test Leads...');
            List<Lead> leads = createLeads(leadRecordTypes, progressLog, errorLog);
            result.leadsCreated = leads.size();
            
            if (leads.size() < 10) {
                String errorDetails = 'Not enough leads created for conversion. Expected at least 10, got ' + leads.size();
                if (!errorLog.isEmpty()) {
                    errorDetails += '\n\nLead Creation Errors:\n' + String.join(errorLog, '\n');
                }
                throw new TestDataGeneratorException(errorDetails);
            }
            
            // Add created leads to result
            for (Lead l : leads) {
                result.createdRecords.add(new TestDataResult.CreatedRecord('Lead', l.Id, l.FirstName + ' ' + l.LastName));
            }
            
            // Step 2: Convert first 10 leads to PersonAccounts
            progressLog.add('Converting 10 Leads to PersonAccounts...');
            List<Id> convertedAccountIds = convertLeadsToPersonAccounts(leads, accountRecordTypes, progressLog, errorLog);
            result.accountsCreated = convertedAccountIds.size();
            
            // Get converted account details
            List<Account> convertedAccounts = [SELECT Id, Name FROM Account WHERE Id IN :convertedAccountIds];
            for (Account acc : convertedAccounts) {
                result.createdRecords.add(new TestDataResult.CreatedRecord('Account', acc.Id, acc.Name));
            }
            
            // Step 3: Create Orders
            progressLog.add('Creating Orders for PersonAccounts...');
            List<Order> orders = createOrders(convertedAccountIds, progressLog, errorLog);
            result.ordersCreated = orders.size();
            
            for (Order ord : orders) {
                result.createdRecords.add(new TestDataResult.CreatedRecord('Order', ord.Id, 'Order ' + ord.OrderNumber));
            }
            
            // Step 4: Create Journals
            progressLog.add('Creating Journals...');
            List<Journal__c> journals = createJournals(convertedAccountIds, orders, progressLog, errorLog);
            result.journalsCreated = journals.size();
            
            for (Journal__c jour : journals) {
                result.createdRecords.add(new TestDataResult.CreatedRecord('Journal__c', jour.Id, jour.Name));
            }
            
            // Step 5: Update Orders with Journal relationships
            progressLog.add('Linking Orders and Journals...');
            updateOrdersWithJournals(orders, journals, errorLog);
            
            result.isSuccess = true;
            result.message = String.format('Successfully generated {0} leads, {1} accounts, {2} orders, and {3} journals', 
                new List<Object>{result.leadsCreated, result.accountsCreated, result.ordersCreated, result.journalsCreated});
            result.progressLog = progressLog;
            result.errorLog = errorLog;
            
            if (!errorLog.isEmpty()) {
                result.warningLog.add('Some warnings occurred during generation. Check error log for details.');
            }
            
        } catch (Exception e) {
            result.isSuccess = false;
            result.message = 'Test data generation failed: ' + e.getMessage();
            result.progressLog = progressLog;
            result.errorLog = errorLog;
            
            // Add the exception details to error log if not already there
            String exceptionMsg = 'Fatal error: ' + e.getMessage();
            if (e.getStackTraceString() != null) {
                exceptionMsg += '\n\nStack Trace:\n' + e.getStackTraceString();
            }
            result.errorLog.add(exceptionMsg);
            
            // Also add errors to warning log so they show in the UI
            if (!errorLog.isEmpty()) {
                result.warningLog.addAll(errorLog);
            }
        }
        
        results.add(result);
        return results;
    }
    
    /**
     * Create 20 test Leads with realistic field data
     */
    private static List<Lead> createLeads(Map<String, Id> recordTypes, List<String> progressLog, List<String> errorLog) {
        List<Lead> leads = new List<Lead>();
        
        // Use simple ASCII names to avoid email validation issues
        List<String> firstNames = new List<String>{
            'Anders', 'Birgitte', 'Christian', 'Dorte', 'Erik', 'Freja', 'Gunnar', 'Hanne', 'Ivan', 'Janne',
            'Karen', 'Lars', 'Mette', 'Niels', 'Oline', 'Peter', 'Rikke', 'Soren', 'Tine', 'Uffe'
        };
        List<String> lastNames = new List<String>{
            'Andersen', 'Nielsen', 'Hansen', 'Pedersen', 'Larsen', 'Sorensen', 'Rasmussen', 'Jorgensen', 'Petersen', 'Madsen'
        };
        
        // Streets and cities for Danish addresses
        List<String> streets = new List<String>{
            'Krogagervej 22', 'Vesterbrogade 45', 'Nørregade 12', 'Østergade 88', 'Søndergade 7',
            'Hovedgaden 34', 'Strandvejen 101', 'Parkalle 56', 'Brogade 18', 'Skolevej 29'
        };
        List<String> cities = new List<String>{
            'København', 'Aarhus', 'Odense', 'Aalborg', 'Esbjerg', 'Vejle', 'Randers', 'Kolding', 'Horsens', 'Roskilde'
        };
        List<String> postalCodes = new List<String>{
            '1000', '8000', '5000', '9000', '6700', '7100', '8900', '6000', '8700', '4000'
        };
        
        // Use actual valid Lead statuses from the sandbox
        List<String> statuses = new List<String>{'New', 'Working', 'Unqualified'};
        
        // Lead sources matching CSV examples
        List<String> leadSources = new List<String>{'Calendly', 'Partner', 'Totalliv', 'Findforsikring.dk', 'Website', 'Foredrag'};
        
        // UTM parameters
        List<String> utmCampaigns = new List<String>{'Gratis raadgivning', 'Arv og testamente', 'Fremtidsfuldmagt', 'Aegtepagt'};
        List<String> utmMediums = new List<String>{'Totalliv', 'Findforsikring.dk', 'Partner', 'Foredrag'};
        List<String> utmSources = new List<String>{'Foredrag', 'Partner', 'Website', 'Email'};
        
        // Marital status and working status options
        List<String> maritalStatuses = new List<String>{'Married', 'Single', 'Divorced', 'Widowed'};
        List<String> workingStatuses = new List<String>{'Appointment', 'Callback', 'Contact Again'};
        List<String> newStatuses = new List<String>{'Unprocessed', 'Reopened', 'New'};
        
        // Interaction types
        List<String> interactions = new List<String>{'Contact Form', 'Booked Meeting', 'Phone Call', 'Email'};
        
        // Check if we have the "Person" record type or use any available record type
        Id defaultRecordTypeId = null;
        if (recordTypes.containsKey('Person')) {
            defaultRecordTypeId = recordTypes.get('Person');
            progressLog.add('Using "Person" record type for leads');
        } else if (!recordTypes.isEmpty()) {
            // Use the first available record type
            String firstRecordType = new List<String>(recordTypes.keySet())[0];
            defaultRecordTypeId = recordTypes.get(firstRecordType);
            progressLog.add('Using "' + firstRecordType + '" record type for leads');
        }
        
        // Use DFJ_DK as default market unit (should work with most record types)
        String defaultMarketUnit = 'DFJ_DK';
        
        for (Integer i = 0; i < 20; i++) {
            Lead lead = new Lead();
            
            // Basic fields
            lead.FirstName = firstNames[Math.mod(i, firstNames.size())];
            lead.LastName = lastNames[Math.mod(i, lastNames.size())];
            lead.Company = lead.FirstName + ' ' + lead.LastName; // Person leads typically use name as company
            
            // Contact information
            lead.Email = lead.FirstName.toLowerCase() + '.' + lead.LastName.toLowerCase() + (i + 1) + '@testmail.dk';
            lead.Phone = '45' + String.valueOf(20000000 + i * 111111).substring(0, 8);
            lead.MobilePhone = '45' + String.valueOf(50000000 + i * 123456).substring(0, 8);
            
            // Address
            lead.Street = streets[Math.mod(i, streets.size())];
            lead.City = cities[Math.mod(i, cities.size())];
            lead.PostalCode = postalCodes[Math.mod(i, postalCodes.size())];
            lead.Country = 'Denmark';
            
            // Status and classification
            lead.Status = statuses[Math.mod(i, statuses.size())];
            lead.Market_Unit__c = defaultMarketUnit;
            lead.LeadSource = leadSources[Math.mod(i, leadSources.size())];
            
            // Custom fields from CSV examples
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('Marital_Status__c')) {
                lead.put('Marital_Status__c', maritalStatuses[Math.mod(i, maritalStatuses.size())]);
            }
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('Working_Status__c')) {
                lead.put('Working_Status__c', workingStatuses[Math.mod(i, workingStatuses.size())]);
            }
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('New_Status__c')) {
                lead.put('New_Status__c', newStatuses[Math.mod(i, newStatuses.size())]);
            }
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('Interaction__c')) {
                lead.put('Interaction__c', interactions[Math.mod(i, interactions.size())]);
            }
            
            // UTM tracking fields
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('UTM_Campaign__c')) {
                lead.put('UTM_Campaign__c', utmCampaigns[Math.mod(i, utmCampaigns.size())]);
            }
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('UTM_Medium__c')) {
                lead.put('UTM_Medium__c', utmMediums[Math.mod(i, utmMediums.size())]);
            }
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('UTM_Source__c')) {
                lead.put('UTM_Source__c', utmSources[Math.mod(i, utmSources.size())]);
            }
            
            // Boolean and numeric fields
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('DoNotCall')) {
                lead.DoNotCall = Math.mod(i, 5) == 0; // 20% true
            }
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('IsCallableNew__c')) {
                lead.put('IsCallableNew__c', Math.mod(i, 4) != 0); // 75% true
            }
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('Lead_Priority__c')) {
                lead.put('Lead_Priority__c', Math.mod(i, 6) + 1); // Priority 1-6
            }
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('Call_Priority__c')) {
                lead.put('Call_Priority__c', Math.mod(i, 100) + 1); // Priority 1-100
            }
            
            // Set record type if available
            if (defaultRecordTypeId != null) {
                lead.RecordTypeId = defaultRecordTypeId;
            }
            
            leads.add(lead);
        }
        
        progressLog.add('Created ' + leads.size() + ' leads');
        
        try {
            insert leads;
        } catch (DmlException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                errorLog.add('Lead DML error: ' + e.getDmlMessage(i));
            }
        }
        
        return leads;
    }
    
    /**
     * Convert first 10 leads to PersonAccounts
     */
    private static List<Id> convertLeadsToPersonAccounts(List<Lead> leads, Map<String, Id> accountRecordTypes, List<String> progressLog, List<String> errorLog) {
        List<Id> convertedAccountIds = new List<Id>();
        
        // Only convert first 10 leads
        List<Lead> leadsToConvert = new List<Lead>();
        for (Integer i = 0; i < Math.min(10, leads.size()); i++) {
            leadsToConvert.add(leads[i]);
        }
        
        // Get the record type mapping to determine converted status
        // Query the leads with their record type names
        Map<Id, String> leadIdToRecordTypeName = new Map<Id, String>();
        for (Lead l : [SELECT Id, RecordType.DeveloperName FROM Lead WHERE Id IN :leadsToConvert]) {
            if (l.RecordType != null) {
                leadIdToRecordTypeName.put(l.Id, l.RecordType.DeveloperName);
            }
        }
        
        try {
            List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
            
            for (Lead l : leadsToConvert) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.Id);
                lc.setDoNotCreateOpportunity(true);
                
                // Use correct converted status based on record type
                // Person leads → "Converted", Host leads → "Qualified"
                String recordTypeName = leadIdToRecordTypeName.get(l.Id);
                if (recordTypeName == 'Host') {
                    lc.setConvertedStatus('Qualified');
                } else {
                    // Default to "Converted" for Person and any other record types
                    lc.setConvertedStatus('Converted');
                }
                
                leadConverts.add(lc);
            }
            
            Database.LeadConvertResult[] results = Database.convertLead(leadConverts, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    convertedAccountIds.add(results[i].getAccountId());
                } else {
                    for (Database.Error error : results[i].getErrors()) {
                        errorLog.add('Lead conversion error for ' + leadsToConvert[i].Email + ': ' + error.getMessage());
                    }
                }
            }
            
        } catch (Exception e) {
            errorLog.add('Exception during lead conversion: ' + e.getMessage());
        }
        
        progressLog.add('Converted ' + convertedAccountIds.size() + ' out of ' + leadsToConvert.size() + ' leads to PersonAccounts');
        return convertedAccountIds;
    }
    
    /**
     * Create Orders for PersonAccounts
     */
    private static List<Order> createOrders(List<Id> accountIds, List<String> progressLog, List<String> errorLog) {
        List<Order> orders = new List<Order>();
        
        // Get Pricebook2 ID
        List<Pricebook2> pricebooks = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (pricebooks.isEmpty()) {
            errorLog.add('No standard pricebook found. Orders may not be created properly.');
            return orders;
        }
        Id pricebookId = pricebooks[0].Id;
        
        List<String> orderTypes = new List<String>{'Standard', 'Express', 'Premium'};
        
        for (Integer i = 0; i < accountIds.size(); i++) {
            Id accountId = accountIds[i];
            
            // First 7 accounts get 1 order, last 3 get 2 orders
            Integer orderCount = (i < 7) ? 1 : 2;
            
            for (Integer j = 0; j < orderCount; j++) {
                Order ord = new Order();
                ord.AccountId = accountId;
                ord.Status = 'Draft';
                ord.EffectiveDate = Date.today();
                ord.Pricebook2Id = pricebookId;
                ord.Type = orderTypes[Math.mod(i + j, orderTypes.size())];
                
                orders.add(ord);
            }
        }
        
        // Insert orders with error handling
        Database.SaveResult[] results = Database.insert(orders, false);
        List<Order> successfulOrders = new List<Order>();
        
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successfulOrders.add(orders[i]);
            } else {
                for (Database.Error error : results[i].getErrors()) {
                    errorLog.add('Order creation error: ' + error.getMessage());
                }
            }
        }
        
        progressLog.add('Created ' + successfulOrders.size() + ' out of ' + orders.size() + ' orders');
        return successfulOrders;
    }
    
    /**
     * Create Journals
     */
    private static List<Journal__c> createJournals(List<Id> accountIds, List<Order> orders, List<String> progressLog, List<String> errorLog) {
        List<Journal__c> journals = new List<Journal__c>();
        
        List<String> journalTypes = new List<String>{'Legal Consultation', 'Document Review', 'Court Representation'};
        List<String> statuses = new List<String>{'Open', 'In Progress', 'Completed'};
        
        for (Integer i = 0; i < orders.size(); i++) {
            Journal__c journal = new Journal__c();
            journal.Account__c = orders[i].AccountId;
            journal.Status__c = statuses[Math.mod(i, statuses.size())];
            journal.Type__c = journalTypes[Math.mod(i, journalTypes.size())];
            
            journals.add(journal);
        }
        
        // Insert journals with error handling
        Database.SaveResult[] results = Database.insert(journals, false);
        List<Journal__c> successfulJournals = new List<Journal__c>();
        
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successfulJournals.add(journals[i]);
            } else {
                for (Database.Error error : results[i].getErrors()) {
                    errorLog.add('Journal creation error: ' + error.getMessage());
                }
            }
        }
        
        progressLog.add('Created ' + successfulJournals.size() + ' out of ' + journals.size() + ' journals');
        return successfulJournals;
    }
    
    /**
     * Update Orders with Journal relationships
     */
    private static void updateOrdersWithJournals(List<Order> orders, List<Journal__c> journals, List<String> errorLog) {
        List<Order> ordersToUpdate = new List<Order>();
        
        // Create bidirectional relationship
        for (Integer i = 0; i < Math.min(orders.size(), journals.size()); i++) {
            orders[i].Journal__c = journals[i].Id;
            ordersToUpdate.add(orders[i]);
        }
        
        if (!ordersToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(ordersToUpdate, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error error : results[i].getErrors()) {
                        errorLog.add('Order-Journal relationship error: ' + error.getMessage());
                    }
                }
            }
        }
    }
    
    /**
     * Get Lead Record Type IDs
     */
    private static Map<String, Id> getLeadRecordTypes() {
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Lead' 
            AND IsActive = true
        ]) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }
        return recordTypeMap;
    }
    
    /**
     * Get Account Record Type IDs
     */
    private static Map<String, Id> getAccountRecordTypes() {
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND IsActive = true
        ]) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }
        return recordTypeMap;
    }
}