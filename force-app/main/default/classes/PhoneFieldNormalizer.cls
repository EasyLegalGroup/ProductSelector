/**
 * Generic Queueable class to normalize phone fields on Lead, Contact, and Account objects.
 * Runs asynchronously to handle phone normalization after trigger events.
 * 
 * Usage:
 * Set<Id> recordIds = new Set<Id>{...};
 * List<String> fields = new List<String>{'MobilePhone', 'Phone'};
 * System.enqueueJob(new PhoneFieldNormalizer('Lead', recordIds, fields));
 */
public class PhoneFieldNormalizer implements Queueable {
    
    private static final String MARKET_DK = 'DFJ_DK';
    private static final String MARKET_SE = 'FA_SE';
    private static final String MARKET_IE = 'Ireland';
    private static final Set<String> SUPPORTED_MARKETS = new Set<String>{
        MARKET_DK,
        MARKET_SE,
        MARKET_IE
    };
    
    private String objectType;
    private List<SObject> recordSnapshots;
    private List<String> phoneFields;
    private String marketUnitField;
    
    // Track if we're in a recursive call to prevent infinite loops
    private static Boolean isExecuting = false;
    
    /**
     * Constructor
     * @param objectType - SObject API name: 'Lead', 'Contact', or 'Account'
     * @param recordSnapshots - List of record snapshots with phone and Market_Unit data
     * @param phoneFields - List of phone field API names to normalize
     */
    public PhoneFieldNormalizer(String objectType, List<SObject> recordSnapshots, List<String> phoneFields) {
        this.objectType = objectType;
        this.recordSnapshots = (recordSnapshots == null) ? new List<SObject>() : recordSnapshots;
        this.phoneFields = (phoneFields == null) ? new List<String>() : new List<String>(phoneFields);
        this.marketUnitField = 'Market_Unit__c';
    }
    
    /**
     * Execute method called by Queueable framework
     */
    public void execute(QueueableContext context) {
        // Prevent recursive execution
        if (isExecuting) {
            return;
        }
        isExecuting = true;
        
        try {
            // Process and normalize phone fields using snapshots
            List<SObject> recordsToUpdate = processRecords(recordSnapshots);
            
            // Update records if there are changes
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
            
        } finally {
            isExecuting = false;
        }
    }
    
    /**
     * Process records and normalize phone fields
     * @param records - List of SObjects to process
     * @return List of SObjects that need updating
     */
    private List<SObject> processRecords(List<SObject> records) {
        List<SObject> recordsToUpdate = new List<SObject>();
        
        for (SObject record : records) {
            Boolean needsUpdate = false;
            SObject updatedRecord = record.getSObjectType().newSObject(record.Id);
            
            // Get Market_Unit__c value for this record
            String marketUnit = resolveMarketUnit(record);
            
            // Process each phone field
            for (String phoneField : phoneFields) {
                String currentValue = (String)record.get(phoneField);
                
                if (String.isNotBlank(currentValue)) {
                    try {
                        String normalizedValue = PhoneNormalizationService.normalize(currentValue, marketUnit);
                        
                        // Only update if value changed
                        if (normalizedValue != currentValue) {
                            updatedRecord.put(phoneField, normalizedValue);
                            needsUpdate = true;
                        }
                    } catch (PhoneNormalizationService.PhoneNormalizationException e) {
                        // Log error but continue processing other fields
                        System.debug(LoggingLevel.ERROR, 
                            'Failed to normalize ' + phoneField + ' on ' + objectType + ' ' + record.Id + ': ' + e.getMessage()
                        );
                        // Re-throw to surface the error
                        throw e;
                    }
                }
            }
            
            if (needsUpdate) {
                recordsToUpdate.add(updatedRecord);
            }
        }
        
        return recordsToUpdate;
    }
    
    private String resolveMarketUnit(SObject record) {
        String explicitMarket = (String)record.get(marketUnitField);
        String countryValue = null;
        if (objectType == 'Lead') {
            countryValue = (String)record.get('Country');
        } else if (objectType == 'Contact') {
            countryValue = (String)record.get('MailingCountry');
            if (String.isBlank(countryValue)) {
                countryValue = (String)record.get('OtherCountry');
            }
        } else if (objectType == 'Account') {
            countryValue = (String)record.get('BillingCountry');
            if (String.isBlank(countryValue)) {
                countryValue = (String)record.get('ShippingCountry');
            }
        }
        String derivedMarket = mapCountryToMarket(countryValue);
        if (derivedMarket != null) {
            return derivedMarket;
        }
        if (isSupportedMarket(explicitMarket)) {
            return explicitMarket;
        }
        return explicitMarket;
    }
    
    private Boolean isSupportedMarket(String marketUnit) {
        return !String.isBlank(marketUnit) && SUPPORTED_MARKETS.contains(marketUnit);
    }
    
    private String mapCountryToMarket(String countryValue) {
        if (String.isBlank(countryValue)) {
            return null;
        }
        String normalized = countryValue.trim().toLowerCase();
        if (normalized.startsWith('denmark') || normalized == 'dk') {
            return MARKET_DK;
        }
        if (normalized.startsWith('sweden') || normalized == 'se' || normalized.startsWith('sverige')) {
            return MARKET_SE;
        }
        if (normalized.startsWith('ireland') || normalized == 'ie' || normalized == 'eir' || normalized.startsWith('eire')) {
            return MARKET_IE;
        }
        return null;
    }
}