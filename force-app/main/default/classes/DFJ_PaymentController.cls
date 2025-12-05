/**
* @File Name : DFJ_PaymentController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 20, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 10, 2025 |   | Initial Version
**/

public with sharing class DFJ_PaymentController {
    public static final String customerCreationURL = 'https://api.reepay.com/v1/customer';
    public static final String invoiceCreationURL = 'https://api.reepay.com/v1/invoice';
    public static final String settleInvoiceURL = 'https://api.reepay.com/v1/invoice/';
    public static final String createSubscriptionURL = 'https://api.reepay.com/v1/subscription';
    public static final String chargeSessionURL = 'https://checkout-api.reepay.com/v1/session/charge';
    public static final String reoccuringSessionURL = 'https://checkout-api.reepay.com/v1/session/recurring';
    public static final String subscriptionSessionURL = 'https://checkout-api.reepay.com/v1/session/subscription';
    public static final String cancelInvoiceURL = 'https://api.reepay.com/v1/invoice/';
    public static final String cancelSubscriptionURL = 'https://api.reepay.com/v1/subscription/';
    public static String refundApiEndpoint = 'https://api.reepay.com/v1/refund';
    public static String expireSubscriptionApiEndpoint = 'https://api.reepay.com/v1/subscription/{handle}/expire';
    public static String cancelSubscriptionApiEndpoint = 'https://api.reepay.com/v1/subscription/{handle}/cancel';
    public static String offlineManualSettleEndpoint = 'https://api.reepay.com/v1/invoice/{id}/manual_settle';

    // Test context variable for mocking private key
    @TestVisible
    private static String testPrivateKey = null;

    /**
     * @description Gets the Reepay private key based on the Pricebook's Internal_Identifier__c.
     *              Returns the test key when not in production org (00D1t000000w9f2).
     * @param pricebookId The Pricebook2 Id to lookup the configuration for
     * @return The Base64 encoded private key for Reepay API authentication
     */
    public static String getReepayPrivateKeyByPricebook(Id pricebookId) {
        System.debug('=== getReepayPrivateKeyByPricebook START ===');
        System.debug('PricebookId received: ' + pricebookId);
        System.debug('Current Org ID: ' + UserInfo.getOrganizationId());
        System.debug('Production Org ID: ' + PS_PaymentUtility.PRODUCTION_ORG_ID);
        System.debug('isProductionOrg: ' + PS_PaymentUtility.isProductionOrg());
        System.debug('shouldUseTestMode: ' + PS_PaymentUtility.shouldUseTestMode());
        
        // In test context, return the test private key if set
        if (Test.isRunningTest() && testPrivateKey != null) {
            System.debug('Returning test context key');
            return testPrivateKey;
        }
        
        if (pricebookId == null) {
            System.debug('ERROR: pricebookId is null');
            throw new AuraHandledException('Pricebook is required for payment processing.');
        }
        
        List<Pricebook2> pricebooks = [SELECT Id, Internal_Identifier__c, Name FROM Pricebook2 WHERE Id = :pricebookId LIMIT 1];
        System.debug('Pricebook query result: ' + pricebooks);
        if (pricebooks.isEmpty() || String.isBlank(pricebooks[0].Internal_Identifier__c)) {
            System.debug('ERROR: Pricebook not found or missing Internal_Identifier__c');
            throw new AuraHandledException('Pricebook not found or missing Internal Identifier.');
        }
        System.debug('Pricebook Name: ' + pricebooks[0].Name);
        System.debug('Internal_Identifier__c: ' + pricebooks[0].Internal_Identifier__c);
        
        List<Price_Book__mdt> priceBookConfigs = [
            SELECT Encoded_Private_Key__c, Test_Encoded_Private_Key__c, Internal_Identifier__c 
            FROM Price_Book__mdt 
            WHERE Internal_Identifier__c = :pricebooks[0].Internal_Identifier__c 
            LIMIT 1
        ];
        System.debug('Price_Book__mdt query result count: ' + priceBookConfigs.size());
        
        if (priceBookConfigs.isEmpty() || String.isBlank(priceBookConfigs[0].Encoded_Private_Key__c)) {
            System.debug('ERROR: Price_Book__mdt config not found or missing Encoded_Private_Key__c');
            throw new AuraHandledException('Reepay configuration not found for Pricebook: ' + pricebooks[0].Name);
        }
        
        System.debug('Has Encoded_Private_Key__c: ' + String.isNotBlank(priceBookConfigs[0].Encoded_Private_Key__c));
        System.debug('Has Test_Encoded_Private_Key__c: ' + String.isNotBlank(priceBookConfigs[0].Test_Encoded_Private_Key__c));
        
        // Return test key when not in production, otherwise return production key
        if (PS_PaymentUtility.shouldUseTestMode() && String.isNotBlank(priceBookConfigs[0].Test_Encoded_Private_Key__c)) {
            System.debug('>>> USING TEST KEY for Reepay API <<<');
            System.debug('=== getReepayPrivateKeyByPricebook END (test key) ===');
            return priceBookConfigs[0].Test_Encoded_Private_Key__c;
        }
        
        System.debug('>>> USING PRODUCTION KEY for Reepay API <<<');
        System.debug('=== getReepayPrivateKeyByPricebook END (prod key) ===');
        return priceBookConfigs[0].Encoded_Private_Key__c;
    }
    
    public static String getReepayPrivateKeyFromPayment(Payments__c payment) {
        return getReepayPrivateKeyByPricebook(payment.Pricebook2Id__c);
    }

public class CustomerResponseWrapper{
        public String error;
        public String message;
        public Integer http_status;
        public String http_reason;
       
    }

    /**
     * @description Wrapper class to hold Account and Opportunity data along with Opportunity Line Items.
     */
    public class ProductsWrapper {
        @AuraEnabled public Account accountRecordInstance; // Account related to the Opportunity
        @AuraEnabled public Opportunity opportunityRecordInstance; // Opportunity record
        @AuraEnabled public List<OpportunityLineItem> opportunityProductsData; // List of Opportunity Line Items
    }



	public class SubscriptionCancelWrapper{
        public String expire_at;
    }

	@AuraEnabled
	public static String cancelPayment(String recordId, String paymentRecordId){
		 String messageToReturn = '';
		try {

			 // Find subscription lead product
            List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();
            List<Payments__c> paymentToCancel = new List<Payments__c>();
            List<LeadProducts__c> leadProductToCreate = new List<LeadProducts__c>();
            List<LeadProducts__c> leadProductToDelete = new List<LeadProducts__c>();
            String subscriptionToCancel = '';

			paymentToCancel = [SELECT Id, CurrencyIsoCode, Pricebook2Id__c, Status__c, Cancellation_date__c, Amount__c, Lead__c, Order__c, Opportunity__c FROM Payments__c WHERE Id = :paymentRecordId LIMIT 1];
            if (paymentToCancel.isEmpty()) {
                DFJ_ErrorLogController.addErrorLogs('', 'Cancelling the invoice in reepay', 'Payment record not found with Id : ' + paymentRecordId, 'Error', 'PS_PaymentService.cancelPayment', '', '');
                return 'Payment record not found.';
            }
			if (String.isNotBlank(paymentToCancel[0].Lead__c)) {
                leadProducts = [SELECT Id, Sub_Total__c, Discount__c, Is_subscription__c, Plan_handle__c, Item_Price__c, Lead__c, Name, Pricebook_Id__c, CurrencyIsoCode, PricebookEntry_Id__c, Product_Id__c, Product_Name__c, Quantity__c, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c FROM LeadProducts__c WHERE Lead__c = :recordId LIMIT 10000];
                for (LeadProducts__c leadProduct : leadProducts) {
                    if (leadProduct.Is_subscription__c) {
                        subscriptionToCancel = leadProduct.Id;
                        LeadProducts__c newLeadProduct = new LeadProducts__c();
                        newLeadProduct = leadProduct.clone(false, false, true, false);
                        leadProductToCreate.add(newLeadProduct);
                        leadProductToDelete.add(leadProduct);
                    }
                }
            }

			if (String.isNotBlank(subscriptionToCancel)) {
                cancelSubscriptionFromId(subscriptionToCancel, paymentToCancel[0].Pricebook2Id__c);
            }

			messageToReturn = paymentToCancel[0].Amount__c > 0 ? cancelInvoiceFromId(paymentRecordId, paymentToCancel[0].Pricebook2Id__c) : 'Success : 0 amount invoice not in reepay.';
            if (messageToReturn.contains('Success')) {
                paymentToCancel[0].Status__c = 'Cancelled';
                paymentToCancel[0].Cancellation_date__c = Datetime.now();
            }
            if (!leadProductToCreate.isEmpty() && !leadProductToDelete.isEmpty()) {
                delete leadProductToDelete;
                insert leadProductToCreate;
            }
			update paymentToCancel;
			return messageToReturn;

        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Cancel payment.', ex.getMessage(), 'Error', 'DFJ_PaymentController.cancelPayment', '', String.valueOf(ex.getLineNumber()));
            return ' Something went Wrong';
        }
	}

	 public static Boolean cancelSubscriptionFromId(String subscriptionToCancel, Id pricebookId) {
        try {
            String reepayPrivateKey = getReepayPrivateKeyByPricebook(pricebookId);
            HttpRequest request = new HttpRequest();

            String endpointUrl = cancelSubscriptionURL + subscriptionToCancel + '/cancel';//cancelSubscriptionURL.replaceAll('{handle}', subscriptionToCancel);
            SubscriptionCancelWrapper subsCancelInstance = new SubscriptionCancelWrapper();
            subsCancelInstance.expire_at = System.today().year() + '-' + System.today().month() + '-' + System.today().day();

            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + reepayPrivateKey);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200 && !String.isBlank(response.getBody())) {
                return true;
            }

        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Cancelling the subscription.', ex.getMessage(), 'Error', 'DFJ_PaymentController.cancelSubscriptionFromId', '', String.valueOf(ex.getLineNumber()));
        }
        return false;
    }

	  public static String cancelInvoiceFromId(String invoiceToCancel, Id pricebookId) {
        try {
            String reepayPrivateKey = getReepayPrivateKeyByPricebook(pricebookId);
            HttpRequest request = new HttpRequest();

            String endpointUrl = settleInvoiceURL + invoiceToCancel + '/cancel';
            SubscriptionCancelWrapper subsCancelInstance = new SubscriptionCancelWrapper();
            subsCancelInstance.expire_at = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
            String requestBody = JSON.serialize(subsCancelInstance);

            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + reepayPrivateKey);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);
            request.setBody(requestBody);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() != 200) {
                CustomerResponseWrapper customerResponse = (CustomerResponseWrapper) JSON.deserialize(response.getBody(), DFJ_PaymentController.CustomerResponseWrapper.class);

                return customerResponse.error;
            }
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Cancelling the Invoice.', ex.getMessage(), 'Error', 'DFJ_PaymentController.cancelInvoiceFromId', '', String.valueOf(ex.getLineNumber()));
            return 'Something went wrong.';
        }
        return 'Successfully cancelled';
    }
  


     /**
     * @description Retrieves data for the Confirm Order page based on the given Opportunity record Id.
     * @param recordId The Id of the Opportunity record.
     * @return ProductsWrapper containing Account, Opportunity, and Opportunity Line Item data.
     */
    @AuraEnabled
    public static ProductsWrapper getDataForConfirmOrderPage(String recordId) {
        try {
            // Check if recordId is not blank
            if (String.isNotBlank(recordId)) {
                ProductsWrapper productsWrapperInstance = new ProductsWrapper(); // Initialize wrapper
                
                // Fetch Opportunity records based on recordId
                List<Opportunity> opportunityRecords = fetchRecordsDynamically(
                    'Id = \'' + recordId + '\'',
                new List<String>{'Id', 'Name', 'AccountId', 'Order_Total__c','Opportunity_Total__c','Fixed_Discount_Type__c'},
                'Opportunity',
                ' LIMIT 1 '
                    );
                
                // If Opportunity records exist, set the instance
                if (!opportunityRecords.isEmpty()) {
                    productsWrapperInstance.opportunityRecordInstance = opportunityRecords[0];
                    System.debug('opportunityRecordInstance--->'+ productsWrapperInstance.opportunityRecordInstance);

                }
                
                // Fetch Account related to the Opportunity
                if (!opportunityRecords.isEmpty() && opportunityRecords[0].AccountId != null) {
                    List<Account> accountRecord = fetchRecordsDynamically(
                        'Id = \'' + opportunityRecords[0].AccountId + '\'',
                    new List<String>{'Id', 'Name', 'PersonEmail', 'Phone', 'BillingCity', 'BillingCountry', 'BillingState', 'BillingPostalCode', 'BillingStreet'},
                    'Account',
                    ' LIMIT 1 '
                        );
                    
                    // Set the Account instance
                    if (!accountRecord.isEmpty()) {
                        productsWrapperInstance.accountRecordInstance = accountRecord[0];
                    }
                }
                
                // Fetch Opportunity Line Items associated with the Opportunity
                List<OpportunityLineItem> oppProducts = [
                    SELECT Id, Name, Discount, TotalPrice,UnitPrice,Net_Total_Price__c, ListPrice, Product2.Name, Pricebook_Id__c, Is_subscription__c, Plan_handle__c,
                    PricebookEntryId, PricebookEntry_Id__c, Product2Id, Quantity, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c 
                    FROM OpportunityLineItem 
                    WHERE OpportunityId = :recordId WITH SECURITY_ENFORCED
                ];
                
                // Set the Opportunity Line Items in the wrapper
                productsWrapperInstance.opportunityProductsData = oppProducts;
                
                return productsWrapperInstance; // Return the populated wrapper
            }
            
            // Return empty wrapper if no recordId is provided
            return new ProductsWrapper();
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', ' Getting data for Confirm Order page. ', e.getMessage(), 'Error', 'DFJ_PaymentCreatorForOpportunity_Apex.getDataForConfirmOrderPage', '', String.valueOf(e.getLineNumber()));

            // Handle exceptions and return empty wrapper
            return new ProductsWrapper();
        }
    }
    
    /**
     * @description Fetches records dynamically based on the given parameters.
     * @param condition The condition for the query.
     * @param fields The fields to select in the query.
     * @param objectName The name of the object to query.
     * @param queryLimit The limit for the query.
     * @return List of SObjects matching the query criteria.
     */
    public static List<SObject> fetchRecordsDynamically(String condition, List<String> fields, String objectName, String queryLimit) {
        try {
            if (String.isBlank(objectName) || fields.isEmpty() || String.isBlank(queryLimit)) {
                return null;
            }
            String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName +
                    (!String.isBlank(condition) ? ' WHERE ' + condition : '') + queryLimit;
            return Database.query(query); // Execute the dynamic query and return results

        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Getting Records.', e.getMessage(), 'Error', 'DFJ_PaymentCreatorForOpportunity_Apex.fetchRecordsDynamically', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }


  // payment btn changes

  @AuraEnabled
     public static PS_PaymentUtility.PaymentWrapper createPaymentRecord(Id recordId) {
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        try {


            //Changes TCS-16
            List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();
            List<LeadProducts__c> leadProductsForSubscription = new List<LeadProducts__c>();
            String sObjectType = PS_PaymentUtility.getSobjectTypeFromRecordId_Apex(recordId);
            List<String> fieldList = new List<String>();
            // Check payment if payment record is already created for the lead
            List<Lead> currentLead = new List<Lead>();
            List<Order> currentOrder = new List<Order>();

            // Changes for DFJ-273
            // Start
            List<Opportunity> currentOpportunity = new List<Opportunity>();
            List<OpportunityLineItem> oppProductsForSubscription = new List<OpportunityLineItem>();
            List<Account> accountRelatedToOpportunity = new List<Account>();
            // End

            if (sObjectType.equalsIgnoreCase('Lead')) {
                // fieldList = new List<String>{'Id','Name','Status__c','Type__c'};
                currentLead = PS_PaymentUtility.fetchRecordsDynamically('Id = \'' + recordId + '\'', new List<String>{
                        'Id', 'Name', 'Email', 'Phone', 'Address', 'Company', 'FirstName', 'LastName', 'Street', 'State', 'City', 'PostalCode', 'Country', 'Fixed_discount_Type__c', 'CurrencyIsoCode', 'Market_Unit__c'
                }, sObjectType);
                if (currentLead == null || currentLead.isEmpty() || String.isBlank(currentLead[0].Email)) {
                    paymentRelatedWrapperInstance.errorMessage = 'Please populate the email';
                    return paymentRelatedWrapperInstance;
                }

                //Changes TCS-16
                //Start
                leadProducts = [SELECT Id, Sub_Total__c, Discount__c, Is_subscription__c, Plan_handle__c, Item_Price__c, Lead__c, Name, Pricebook_Id__c, CurrencyIsoCode, PricebookEntry_Id__c, Product_Id__c, Product_Name__c, Quantity__c, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c FROM LeadProducts__c WHERE Lead__c = :recordId];
                for (LeadProducts__c leadProduct : leadProducts) {
                    if (leadProduct.Is_subscription__c) {
                        leadProductsForSubscription.add(leadProduct);
                    }
                }
                //End
                //query = 'SELECT Id,Lead__c FROM Payments__c WHERE Lead__c = \''+ recordId +'\' LIMIT 10000';
            } else if (sObjectType.equalsIgnoreCase('Order')) { //DIN-337
                String orderCondition = 'Id = \'' + recordId + '\'';
                List<String> orderFieldList = new List<String>{
                        'Id', 'AccountId', 'Lead__c', 'TotalAmount', 'Name', 'Order_Price__c', 'Account.Name', 'Account.PersonEmail', 'ShippingAddress', 'BillingAddress', 'ShippingCity', 'ShippingCountry', 'ShippingPostalCode', 'ShippingState', 'ShippingStreet', 'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry', 'CurrencyIsoCode', 'Fixed_discount_Type__c', 'Account.Market_Unit__c'
                };
                // Get current order

                currentOrder = PS_PaymentUtility.fetchRecordsDynamically(orderCondition, orderFieldList, sObjectType);

                if (currentOrder == null || currentOrder.isEmpty() || String.isBlank(currentOrder[0].Account.PersonEmail)) {
                    paymentRelatedWrapperInstance.errorMessage = 'Please populate the email';
                    return paymentRelatedWrapperInstance;
                }
            }
            // Changes for DFJ-273
            // Start
            else if (sObjectType.equalsIgnoreCase('Opportunity')) {
                String oppCondition = 'Id = \'' + recordId + '\'';
                List<String> oppFieldList = new List<String>{
                        'Id', 'AccountId', 'Opportunity_Total__c', 'Fixed_Discount_Type__c', 'Pricebook2Id'
                };

                currentOpportunity = PS_PaymentUtility.fetchRecordsDynamically(oppCondition, oppFieldList, sObjectType);

                if (currentOpportunity.isEmpty()) {
                    paymentRelatedWrapperInstance.errorMessage = 'Error fetching Opportunity';
                    return paymentRelatedWrapperInstance;
                } else {

                    List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
                    oppProducts = [
                            SELECT Id, Name, Subtotal, Discount, Is_subscription__c, Plan_handle__c, ListPrice, OpportunityId, Pricebook_Id__c,
                                    CurrencyIsoCode, PricebookEntry_Id__c, Product2Id, Quantity, Partner_Provision_Value__c, Partner_Sales_Value__c,
                                    Provision_Base__c
                            FROM OpportunityLineItem
                            WHERE OpportunityId = :recordId
                    ];

                    for (OpportunityLineItem oppProduct : oppProducts) {
                        if (oppProduct.Is_subscription__c) {
                            oppProductsForSubscription.add(oppProduct);
                        }
                    }

                    if (currentOpportunity[0].AccountId == null) {
                        paymentRelatedWrapperInstance.errorMessage = 'No related AccountId in Opportunity.';
                        return paymentRelatedWrapperInstance;
                    } else {
                        String actCondition = 'Id = \'' + currentOpportunity[0].AccountId + '\'';
                        List<String> actFieldList = new List<String>{
                                'Id', 'Name', 'PersonEmail', 'CurrencyIsoCode', 'Market_Unit__c', 'BillingAddress', 'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry'
                        };
                        accountRelatedToOpportunity = PS_PaymentUtility.fetchRecordsDynamically(
                                actCondition, actFieldList, 'Account'
                        );

                        if (accountRelatedToOpportunity.isEmpty()) {
                            paymentRelatedWrapperInstance.errorMessage = 'Problem in fetching related Account.';
                            return paymentRelatedWrapperInstance;
                        }
                        if (accountRelatedToOpportunity[0].PersonEmail == null) {
                            paymentRelatedWrapperInstance.errorMessage = 'Please populate the email in the related Account of Opportunity.';
                            return paymentRelatedWrapperInstance;
                        }
                    }
                }


            }

            else {
                paymentRelatedWrapperInstance.errorMessage = 'Component not placed on Lead, Order or Opportunity';
                return paymentRelatedWrapperInstance;
            }
            // End

            // Changes for DFJ-273
            // Start
            // Modified previously existing paymentCondition variable,
            // Added Condition for Opportunity in same manner as was previously written for Lead and Order
            String paymentCondition = sObjectType.equalsIgnoreCase('Lead') ?
                    ('Lead__c = \'' + recordId + '\' AND Status__c Not In (\'Cancelled\',\'Refunded\')') :
                    sObjectType.equalsIgnoreCase('Order') ?
                            ('Order__c = \'' + recordId + '\' AND Status__c Not In (\'Cancelled\',\'Refunded\')') :
                            sObjectType.equalsIgnoreCase('Opportunity') ?
                                    ('Opportunity__c = \'' + recordId + '\' AND Status__c Not In (\'Cancelled\',\'Refunded\')') :
                                    '';


            // Added Opportunity__c in the paymentFieldList
            List<String> paymentFieldList = new List<String>{
                    'OwnerId', 'CurrencyISOCode', 'Id', 'Name', 'Billing_email__c', 'Opportunity__c', 'Lead__c', 'Status__c', 'Type__c', 'Order__c', 'Subscription_status__c', 'Subscription_link__c', 'Invoice_created__c', 'BillingStreet__c', 'BillingState__c', 'Billing_PostalCode__c', 'BillingCity__c', 'BillingCountry__c', 'Fixed_discount_Type__c', 'Amount__c'
            }; //DIN-337

            // End

            List<Payments__c> recordListToCheckIfAlreadyPresent = PS_PaymentUtility.fetchRecordsDynamically(paymentCondition, paymentFieldList, 'Payments__c');


            if (!recordListToCheckIfAlreadyPresent.isEmpty()) {


                if (recordListToCheckIfAlreadyPresent[0].Invoice_created__c) {
                    paymentRelatedWrapperInstance.errorMessage = 'Payment already present.';
                    return paymentRelatedWrapperInstance;
                }

                List<Payment_order_line__c> polItemList = new List<Payment_order_line__c>();
                String polItemCondition = 'Payments__c =\'' + recordListToCheckIfAlreadyPresent[0].Id + '\'';
                List<String> polItemFieldList = new List<String>{
                        'Payments__c', 'Amount__c', 'Quantity__c', 'Vat__c', 'Id', 'CurrencyIsoCode', 'Name'
                };

                polItemList = PS_PaymentUtility.fetchRecordsDynamically(polItemCondition, polItemFieldList, 'Payment_order_line__c');

                paymentRelatedWrapperInstance.payment = recordListToCheckIfAlreadyPresent[0];
                paymentRelatedWrapperInstance.paymentOrderLines = polItemList;
                paymentRelatedWrapperInstance.successMessage = 'Created successfully.';

                // Changes for DFJ-273
                // Start
                if (sObjectType.equalsIgnoreCase('Opportunity')) {
                    paymentRelatedWrapperInstance.subscriptionOpportunityProducts = oppProductsForSubscription;
                } else {
                    paymentRelatedWrapperInstance.subscriptionLeadProducts = leadProductsForSubscription;
                }
                // End


                // paymentRelatedWrapperInstance.successMessage
                // For now returning the payment record id if payment rec is already present for the lead.
                return paymentRelatedWrapperInstance;
            }
            // Create payment ans payment order item
            //  Database.insert(list<sObject,true);

            // Changes for DFJ-273
            // Only Added condition for Opportunity
            // Start
            if (sObjectType.equalsIgnoreCase('Opportunity')) {
                paymentRelatedWrapperInstance = createPaymentAndOrderItemsForOpportunity(recordId, sObjectType, currentOpportunity, accountRelatedToOpportunity);
            } 
            // End

            // Make callout to create the customer and invoice
            return paymentRelatedWrapperInstance;

        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Creating payment and payment order lines', ex.getMessage(), 'Error', 'PS_PaymentService.createPaymentRecord', '', String.valueOf(ex.getLineNumber()));
            paymentRelatedWrapperInstance.errorMessage = ex.getMessage();
        }
        return paymentRelatedWrapperInstance;
    }

   // Start
   public static PS_PaymentUtility.PaymentWrapper createPaymentAndOrderItemsForOpportunity(Id recordId, String sObjectType, List<Opportunity> currentOpp, List<Account> accountRelatedToOpportunity) {

        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        try {
            Id currOppId = currentOpp[0].Id;

            List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oppProductsForSubscription = new List<OpportunityLineItem>();


            String paymentCurrency = '';
            Boolean isProductsCurrencyChanged = false;


            oppProducts = [
                    SELECT
                            Id, Name, Quantity, ListPrice,unitPrice,product2.name, CurrencyIsoCode, Subtotal, Discount, TotalPrice, Is_subscription__c
                    FROM
                            OpportunityLineItem
                    WHERE
                            OpportunityId = :currOppId
            ];//unitPrice,product2.name added for DFJ-350

            if (oppProducts.isEmpty()) {
                paymentRelatedWrapperInstance.errorMessage = 'Please add the OpportunityId Products first';
                return paymentRelatedWrapperInstance;
            }

            for (OpportunityLineItem currOppProd : oppProducts) {
                if (currOppProd.Is_subscription__c) {
                    oppProductsForSubscription.add(currOppProd);
                }

                isProductsCurrencyChanged = (String.isBlank(paymentCurrency) || paymentCurrency == currOppProd.CurrencyIsoCode) ? false : true;
                paymentCurrency = currOppProd.CurrencyIsoCode;

                if (isProductsCurrencyChanged) {
                    paymentRelatedWrapperInstance.errorMessage = 'Some product have not same currency.';
                    return paymentRelatedWrapperInstance;
                }
            }

            Payments__c paymentRecord = new Payments__c();
            paymentRecord.Opportunity__c = currOppId;
            paymentRecord.Pricebook2Id__c = currentOpp[0].Pricebook2Id;

            if (String.isBlank(paymentCurrency)) {
                paymentCurrency = (!accountRelatedToOpportunity.isEmpty()) ?
                        accountRelatedToOpportunity[0].CurrencyIsoCode : '';
            }

            paymentRecord.Type__c = 'Onetime';
           
           paymentRecord.Amount__c = currentOpp[0].Opportunity_Total__c;

            paymentRecord.CurrencyIsoCode = paymentCurrency;
            paymentRecord.BillingStreet__c = accountRelatedToOpportunity[0].BillingStreet;

            paymentRecord.BillingState__c = accountRelatedToOpportunity[0].BillingState;

            paymentRecord.Billing_PostalCode__c = accountRelatedToOpportunity[0].BillingPostalCode;

            paymentRecord.BillingCity__c = accountRelatedToOpportunity[0].BillingCity;

            paymentRecord.BillingCountry__c = PS_PaymentUtility.getCountryCodeFromMarketUnit(accountRelatedToOpportunity[0].Market_Unit__c);

            paymentRecord.Billing_name__c = accountRelatedToOpportunity[0].Name;

            paymentRecord.Billing_email__c = accountRelatedToOpportunity[0].PersonEmail;

            paymentRecord.Fixed_discount_Type__c = currentOpp[0].Fixed_Discount_Type__c;

            List<Payments__c> isPaymentInserted = new List<Payments__c>();

           system.debug('if condition before called,amount-->'+ paymentRecord.Amount__c);
            if (paymentRecord.Amount__c >= 0) {
                system.debug('if condition called');
                isPaymentInserted = PS_PaymentUtility.dmlHelper(new List<Payments__c>{
                        paymentRecord
                }, 'INSERT');
            }

            if (isPaymentInserted.isEmpty()) {
                paymentRelatedWrapperInstance.errorMessage = 'Unable to create payment.';
                return paymentRelatedWrapperInstance;
            }

            List<Payment_order_line__c> isPaymentOrderItemInserted = new List<Payment_order_line__c>();

            List<Payment_order_line__c> paymentOrderItemListToCreate = new List<Payment_order_line__c>();

            paymentOrderItemListToCreate = PS_PaymentUtility.createPaymentOrderItemFromOpportunity(oppProducts, isPaymentInserted);

            isPaymentOrderItemInserted = PS_PaymentUtility.dmlHelper(paymentOrderItemListToCreate, 'INSERT');

            if (isPaymentOrderItemInserted == null) {

                paymentRelatedWrapperInstance.errorMessage = 'Unable to create the payment order items';
                return paymentRelatedWrapperInstance;
            }

            if (!isPaymentInserted.isEmpty()) {

                paymentRelatedWrapperInstance.payment = isPaymentInserted[0];

            }


            paymentRelatedWrapperInstance.paymentOrderLines = isPaymentOrderItemInserted;
            paymentRelatedWrapperInstance.subscriptionOpportunityProducts = oppProductsForSubscription;
            paymentRelatedWrapperInstance.successMessage = 'Created successfully.';

        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Creating payment and payment order lines.', e.getMessage(), 'Error', 'PS_PaymentService.createPaymentAndOrderItemsForOpportunity', '', String.valueOf(e.getLineNumber()));
        }

        return paymentRelatedWrapperInstance;

    }
  
     /*
    * @Description  method to create the invoice record.
    * @Param        recordId
    * @Return       String
    */
     public static PS_PaymentUtility.CustomerResponseWrapper createReepayCustomerInvoice(String currentEmail, Payments__c payment, List<Payment_order_line__c> paymentOrderLines, List<sObject> subscriptionProducts) {
        PS_PaymentUtility.CustomerResponseWrapper responseWrapperIns = new PS_PaymentUtility.CustomerResponseWrapper();

        try {
            String reepayPrivateKey = getReepayPrivateKeyFromPayment(payment);


            //Changes TCS-35 start
            if (payment.Amount__c > 0) {
                HttpRequest request = new HttpRequest();

                String endpointUrl = invoiceCreationURL + '/' + currentEmail + '/invoice';


                String requestBody = PS_PaymentUtility.constructInvoiceRequestBody(payment, paymentOrderLines, subscriptionProducts); //TCS-16 Chnages Add LeadProducts in invoice body


                request.setEndpoint(endpointUrl);
                request.setMethod('POST');
                request.setHeader('Authorization', 'Basic ' + reepayPrivateKey);
                request.setHeader('Accept', 'application/json');
                request.setHeader('Content-Type', 'application/json');
                request.setTimeout(120000);
                request.setBody(requestBody);

                Http http = new Http();
                HttpResponse response = http.send(request);


                if (response.getStatusCode() == 200 && !String.isBlank(response.getBody())) {

                    // Parse the invoice wrapper on the creation of hte invoice
                    PS_PaymentUtility.GetInvoiceWrapper getInvoiceWrapperInstance = PS_PaymentUtility.parseReepayInvoice(response.getBody());

                    if (String.isBlank(getInvoiceWrapperInstance.errorMessage)) {
                        // Call method to update

                        payment.Invoice_unique_handle__c = getInvoiceWrapperInstance.handle;
                        payment.Status__c = getInvoiceWrapperInstance.state;
                        payment.Invoice_id__c = getInvoiceWrapperInstance.id;
                    }
                    payment.Invoice_created__c = true;
                    responseWrapperIns.message = 'Created invoice';
                } else {

                    // Changes for DFJ-273
                    // Start
                    if (!String.isBlank(response.getBody())) {
                        PS_PaymentUtility.CustomerResponseWrapper customerResponse = (PS_PaymentUtility.CustomerResponseWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.CustomerResponseWrapper.class);
                        payment.Error_message__c = String.isNotBlank(customerResponse.error) ? customerResponse.error : customerResponse.message;
                        payment.Invoice_created__c = false;
                        responseWrapperIns.error = String.isNotBlank(customerResponse.error) ? customerResponse.error : customerResponse.message;
                    } else {
                        String errorMsg = 'Error in Class: PS_PaymentService, Method:createReepayCustomerInvoice(), Response code not 200 and got an empty response body.';
                        payment.Error_message__c = errorMsg;
                        payment.Invoice_created__c = false;
                        responseWrapperIns.error = errorMsg;
                    }
                    // End
                }

                PS_PaymentUtility.PS_PlanInfokWrapper getPlanInfo = new PS_PaymentUtility.PS_PlanInfokWrapper();
                if (!subscriptionProducts.isEmpty()) {
                    payment.Subscription_status__c = 'Subscription included';
                    //Changes TCS-43 Start
                    getPlanInfo = getCurrentPlanInformation(payment, subscriptionProducts);
                    payment.Plan_Name__c = getPlanInfo.name;
                    //Changes DFJ-191
                    payment.Plan_Amount__c = Decimal.valueOf(getPlanInfo.amount) / 100;
                    payment.Plan_Version__c = getPlanInfo.version;
                    //End


                } else {
                    payment.Subscription_status__c = 'No subscription included';
                }
                //Changes TCS-16
                //Start
                //End
                if (payment.Invoice_created__c) {
                    //TCS-43
                    Boolean isRecurringSettle = (!subscriptionProducts.isEmpty() ? true : false);
                    // call method for the payment link
                    PS_PaymentUtility.PaymentLinkWrapper linkStatus = generatePaymentLink(payment, 'charge', getPlanInfo, isRecurringSettle);
                    //End
                    if (String.isNotBlank(linkStatus.error)) {
                        payment.Error_message__c = linkStatus.error;
                    } else {
                        payment.Payment_link__c = linkStatus.url;
                        payment.Reepay_ID__c = linkStatus.id;
                    }
                }
            } else if (!subscriptionProducts.isEmpty() && payment.Amount__c == 0) {
                PS_PaymentUtility.PS_PlanInfokWrapper getPlanInfo = new PS_PaymentUtility.PS_PlanInfokWrapper();
                //DFJ-128 Changes
                getPlanInfo = getCurrentPlanInformation(payment, subscriptionProducts);
                payment.Plan_Name__c = getPlanInfo.name;
                //End
                //DFJ-191 Changes
                payment.Plan_Amount__c = Decimal.valueOf(getPlanInfo.amount) / 100;
                payment.Plan_Version__c = getPlanInfo.version;
                //End

                PS_PaymentUtility.PS_SubscriptionWrapper subscriptionResponseWrapperIns = createSubscriptionWithFullDiscount(payment, subscriptionProducts);

                if (String.isBlank(subscriptionResponseWrapperIns.error)) {
                    PS_PaymentUtility.PS_hosted_page_links hostedpageLink = new PS_PaymentUtility.PS_hosted_page_links();
                    hostedpageLink = subscriptionResponseWrapperIns.hosted_page_links;
                    payment.Subscription_link__c = hostedpageLink.payment_info;
                    payment.Subscription_status__c = 'Subscription created';
                    payment.Subscription_id__c = subscriptionResponseWrapperIns.handle;
                    // Changes for DIN-349
                    if (paymentOrderLines.isEmpty()) {
                        responseWrapperIns.error = '';
                        responseWrapperIns.message = 'Subscription created';
                    }
                } else {
                    payment.Subscription_status__c = 'Error in subscription.';
                }
            } else {
                payment.Subscription_status__c = 'No subscription included';
            }
            //end
            
            // Rollback: If invoice creation failed, delete the Payment and related Payment Order Lines
            if (String.isNotBlank(responseWrapperIns.error)) {
                try {
                    // Delete related Payment Order Lines first (child records)
                    List<Payment_order_line__c> relatedOrderLines = [SELECT Id FROM Payment_order_line__c WHERE Payments__c = :payment.Id];
                    if (!relatedOrderLines.isEmpty()) {
                        delete relatedOrderLines;
                    }
                    // Delete the Payment record
                    delete payment;
                    DFJ_ErrorLogController.addErrorLogs('', 'Reepay invoice creation failed - rolled back Payment record', responseWrapperIns.error, 'Warning', 'DFJ_PaymentController.createReepayCustomerInvoice', '', '');
                } catch (Exception rollbackEx) {
                    DFJ_ErrorLogController.addErrorLogs('', 'Failed to rollback Payment record after Reepay error', rollbackEx.getMessage(), 'Error', 'DFJ_PaymentController.createReepayCustomerInvoice', '', String.valueOf(rollbackEx.getLineNumber()));
                }
            } else {
                update payment;
            }
        } catch (Exception ex) {
            responseWrapperIns.error = ex.getMessage();
            DFJ_ErrorLogController.addErrorLogs('', 'Creating ReepayCustomerInvoice', ex.getMessage(), 'Error', 'PS_PaymentService.createReepayCustomerInvoice', '', String.valueOf(ex.getLineNumber()));
        }
        return responseWrapperIns;
    }

  /*
    * @Description  make callout and create customer and invoice.
    * @Param        recordId
    * @Return       String
    */
    public static PS_PaymentUtility.PaymentWrapper makeCalloutToCreateCustomerInvoice(Id recordId, String payment, String paymentOrderLines, List<SObject> subscriptionProducts) {
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        try {
            String sObjectType = PS_PaymentUtility.getSobjectTypeFromRecordId_Apex(recordId);
            List<Lead> currentLead = new List<Lead>();
            List<Order> currentOrder = new List<Order>();
            List<Account> currentAccount = new List<Account>();
            if (sObjectType.equalsIgnoreCase('Lead')) {
                String leadCondition = 'Id = \'' + recordId + '\'';
                List<String> leadFieldList = new List<String>{
                        'Id', 'Name', 'Email', 'Phone', 'Address', 'Company', 'Country', 'FirstName', 'LastName', 'City', 'PostalCode', 'Street', 'State', 'Fixed_discount_Type__c', 'Market_Unit__c'
                };

                currentLead = PS_PaymentUtility.fetchRecordsDynamically(leadCondition, leadFieldList, sObjectType);

                if (currentLead.isEmpty() || String.isBlank(currentLead[0].Email)) {
                    paymentRelatedWrapperInstance.errorMessage = 'Unable to fetch lead record';
                    return paymentRelatedWrapperInstance;
                }
            }
            // Changes for DFJ-273
            // Start
            else if (sObjectType.equalsIgnoreCase('Opportunity')) {
                // fetch opportunity record with accountId of related Account
                List<Opportunity> currOpp = PS_PaymentUtility.fetchRecordsDynamically(
                        'Id = \'' + recordId + '\'',
                        new List<String>{
                                'Id', 'AccountId'
                        },
                        'Opportunity'
                );

                if (currOpp[0].AccountId == null) {
                    paymentRelatedWrapperInstance.errorMessage = 'Unable to fetch related account record.';
                    return paymentRelatedWrapperInstance;
                }

                // fetch account record related to Opportunity
                Id idOfActRelatedToOpp = currOpp[0].AccountId;
                String accountCondition = 'Id = \'' + idOfActRelatedToOpp + '\'';
                List<String> accountFieldList = new List<String>{
                        'Id', 'phone', 'ShippingCity', 'ShippingPostalCode', 'BillingStreet', 'BillingState', 'BillingPostalCode', 'BillingCity', 'BillingCountry', 'Market_Unit__c', 'Name', 'PersonEmail'
                };

                currentAccount = PS_PaymentUtility.fetchRecordsDynamically(accountCondition, accountFieldList, 'Account');

                if (currentAccount.isEmpty()) {
                    paymentRelatedWrapperInstance.errorMessage = 'Unable to fetch account record';

                    return paymentRelatedWrapperInstance;
                }

                if (String.isBlank(currentAccount[0].PersonEmail)) {
                    paymentRelatedWrapperInstance.errorMessage = 'Please populate Email in the Related Account.';

                    return paymentRelatedWrapperInstance;
                }

            }
            // End

            else if (sObjectType.equalsIgnoreCase('Order')) {
                String orderCondition = 'Id = \'' + recordId + '\'';
                List<String> orderFieldList = new List<String>{
                        'Id', 'Account.Name', 'Account.Phone', 'Account.PersonEmail', 'ShippingAddress', 'BillingAddress', 'ShippingCity', 'ShippingCountry', 'ShippingPostalCode', 'ShippingState', 'ShippingStreet', 'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry', 'Fixed_discount_Type__c', 'Account.Market_Unit__c'
                };

                currentOrder = PS_PaymentUtility.fetchRecordsDynamically(orderCondition, orderFieldList, sObjectType);

                if (currentOrder.isEmpty() || String.isBlank(currentOrder[0].Account.PersonEmail)) {
                    paymentRelatedWrapperInstance.errorMessage = 'Unable to fetch order record';

                    return paymentRelatedWrapperInstance;
                }
            } else if (sObjectType.equalsIgnoreCase('Account')) {//Changes DFJ-80
                String accountCondition = 'Id = \'' + recordId + '\'';
                List<String> accountFieldList = new List<String>{
                        'Id', 'phone', 'ShippingCity', 'ShippingPostalCode', 'BillingStreet', 'BillingState', 'BillingPostalCode', 'BillingCity', 'BillingCountry', 'Market_Unit__c', 'Name', 'PersonEmail'
                };

                currentAccount = PS_PaymentUtility.fetchRecordsDynamically(accountCondition, accountFieldList, sObjectType);

                if (currentAccount.isEmpty() || String.isBlank(currentAccount[0].PersonEmail)) {
                    paymentRelatedWrapperInstance.errorMessage = 'Unable to fetch account record';

                    return paymentRelatedWrapperInstance;
                }//End
            }
            Payments__c paymentOrder = new Payments__c();
            paymentOrder = (Payments__c) JSON.deserialize(payment, Payments__c.class);


            // Changes for DFJ-273
            // Added condition for Opportunity
            // Start
            String customerPresentString = checkCustomerAlreadyCreated(
                    sObjectType.equalsIgnoreCase('Lead') ?
                            currentLead[0].Email : sObjectType.equalsIgnoreCase('Order') ?
                            currentOrder[0].Account.PersonEmail :
                            (sObjectType.equalsIgnoreCase('Account') || sObjectType.equalsIgnoreCase('Opportunity')) ?
                                    currentAccount[0].PersonEmail : '',
                    paymentOrder.Pricebook2Id__c
            );
            // End

            if (customerPresentString.contains('Error :')) {
                paymentRelatedWrapperInstance.errorMessage = customerPresentString;
                return paymentRelatedWrapperInstance;
            } else if (customerPresentString.equalsIgnoreCase('Not found') || customerPresentString.equalsIgnoreCase('Deleted')) {
                // createCustomer - also recreate if customer was deleted in Reepay
                if (customerPresentString.equalsIgnoreCase('Deleted')) {
                    System.debug('Customer was deleted in Reepay - will recreate with same handle');
                }
                PS_PaymentUtility.CustomerResponseWrapper responseWrapperIns = new PS_PaymentUtility.CustomerResponseWrapper();
                List<Payment_order_line__c> paymentOrderItems = new List<Payment_order_line__c>();
                paymentOrderItems = (List<Payment_order_line__c>) JSON.deserialize(paymentOrderLines, List<Payment_order_line__c>.class);
                // Changes DFJ-80 :: Added param currentAccount in createReepayCustomer class
                PS_PaymentUtility.CustomerResponseWrapper isCustomerCreated = createReepayCustomer(currentAccount, currentLead, currentOrder, paymentOrder.Pricebook2Id__c, sObjectType);
                if (String.isNotBlank(isCustomerCreated.error)) {
                    paymentRelatedWrapperInstance.errorMessage = isCustomerCreated.error;
                    return paymentRelatedWrapperInstance;
                }


                // Changes DFJ-80 :: Added param currentAccount in createReepayCustomerInvoice class

                // Changes for DFJ-273
                // Only Added condition for Opportunity
                // Start
                responseWrapperIns = createReepayCustomerInvoice(
                        sObjectType.equalsIgnoreCase('Lead') ?
                                currentLead[0].Email : sObjectType.equalsIgnoreCase('Order') ?
                                currentOrder[0].Account.PersonEmail :
                                (sObjectType.equalsIgnoreCase('Account') || sObjectType.equalsIgnoreCase('Opportunity')) ?
                                        currentAccount[0].PersonEmail : '',
                        paymentOrder,
                        paymentOrderItems,
                        subscriptionProducts
                );

                // End
                if (String.isNotBlank(responseWrapperIns.error)) {
                    paymentRelatedWrapperInstance.errorMessage = responseWrapperIns.error;
                    return paymentRelatedWrapperInstance;
                }

            } else if (customerPresentString.equalsIgnoreCase('Found')) {
                // Create invoice
                List<Payment_order_line__c> paymentOrderItems = new List<Payment_order_line__c>();
                PS_PaymentUtility.CustomerResponseWrapper responseWrapperIns = new PS_PaymentUtility.CustomerResponseWrapper();

                paymentOrder = (Payments__c) JSON.deserialize(payment, Payments__c.class);
                paymentOrderItems = (List<Payment_order_line__c>) JSON.deserialize(paymentOrderLines, List<Payment_order_line__c>.class);

                // Changes DFJ-80 :: Added param currentAccount in createReepayCustomerInvoice class
                responseWrapperIns = createReepayCustomerInvoice(
                        sObjectType.equalsIgnoreCase('Lead') ?
                                currentLead[0].Email : sObjectType.equalsIgnoreCase('Order') ?
                                currentOrder[0].Account.PersonEmail :
                                (sObjectType.equalsIgnoreCase('Account') || sObjectType.equalsIgnoreCase('Opportunity')) ?
                                        currentAccount[0].PersonEmail : '',
                        paymentOrder,
                        paymentOrderItems,
                        subscriptionProducts
                );

                if (String.isNotBlank(responseWrapperIns.error)) {
                    paymentRelatedWrapperInstance.errorMessage = responseWrapperIns.error;
                    return paymentRelatedWrapperInstance;
                }

            }

            paymentRelatedWrapperInstance.successMessage = 'Invoice created successfully';
            return paymentRelatedWrapperInstance;
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', ' Callout to create customer invoice. ', ex.getMessage(), 'Error', 'PS_PaymentService.makeCalloutToCreateCustomerInvoice', '', String.valueOf(ex.getLineNumber()));
            paymentRelatedWrapperInstance.errorMessage = ex.getMessage();
        }
        return paymentRelatedWrapperInstance;
    }

     /*
    * @Description  method to check for the customer record .
    * @Param        recordId
    * @Return       String - 'Found', 'Not Found', 'Deleted', or 'Error: ...'
    */
     public static String checkCustomerAlreadyCreated(String currentEmail, Id pricebookId) {
        String reepayPrivateKey = getReepayPrivateKeyByPricebook(pricebookId);
        Boolean customerFound = false;
        String endpointUrl = customerCreationURL;
        PS_PaymentUtility.CustomerWrapper customerWrapper = new PS_PaymentUtility.CustomerWrapper();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl + '/' + currentEmail);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Basic ' + reepayPrivateKey);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);

        Http http = new Http();
        HttpResponse response = http.send(request);

        if ((response.getStatusCode() == 200 && !String.isBlank(response.getBody()))) {
            // Check if customer is deleted - if so, treat as Not Found so it will be recreated
            try {
                PS_PaymentUtility.CustomerWrapper existingCustomer = (PS_PaymentUtility.CustomerWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.CustomerWrapper.class);
                if (String.isNotBlank(existingCustomer.deleted)) {
                    System.debug('Customer exists but is deleted (deleted: ' + existingCustomer.deleted + '). Will recreate.');
                    return 'Deleted';
                }
            } catch (Exception e) {
                System.debug('Error parsing customer response: ' + e.getMessage());
            }
            return 'Found';
        } else if (response.getStatusCode() == 404 && !String.isBlank(response.getBody())) {
            PS_PaymentUtility.CustomerResponseWrapper customerResponse = (PS_PaymentUtility.CustomerResponseWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.CustomerResponseWrapper.class);
            return (customerResponse.error.equals('Customer not found') && customerResponse.http_status == 404 ? 'Not Found' : 'Error :' + customerResponse.error);
        } else {
            PS_PaymentUtility.CustomerResponseWrapper customerResponse = (PS_PaymentUtility.CustomerResponseWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.CustomerResponseWrapper.class);
            return 'Error :' + customerResponse.error ;
        }
    }
      /*
    * @Description  method to create the customer record.
    * @Param        recordId
    * @Return       String
    */
     public static PS_PaymentUtility.CustomerResponseWrapper createReepayCustomer(List<Account> currentAccount, List<Lead> currentLead, List<Order> currentOrder, Id pricebookId, String sObjectType) {
        System.debug('=== createReepayCustomer START ===');
        System.debug('sObjectType: ' + sObjectType);
        System.debug('pricebookId: ' + pricebookId);
        System.debug('currentLead: ' + (currentLead != null && !currentLead.isEmpty() ? currentLead[0].Id : 'null/empty'));
        System.debug('currentAccount: ' + (currentAccount != null && !currentAccount.isEmpty() ? currentAccount[0].Id : 'null/empty'));
        System.debug('currentOrder: ' + (currentOrder != null && !currentOrder.isEmpty() ? currentOrder[0].Id : 'null/empty'));
        
        PS_PaymentUtility.CustomerResponseWrapper customerResponseWrapperInstance = new PS_PaymentUtility.CustomerResponseWrapper();
        String reepayPrivateKey = getReepayPrivateKeyByPricebook(pricebookId);
        System.debug('Got Reepay private key (first 20 chars): ' + (reepayPrivateKey != null ? reepayPrivateKey.substring(0, Math.min(20, reepayPrivateKey.length())) + '...' : 'null'));
        
        String endpointUrl = customerCreationURL;
        System.debug('Endpoint URL: ' + endpointUrl);
        // Changes DFJ-80 :: Added class buildCustomerRequestBodyFromAccount to created request body

        // Changes for DFJ-273
        // Added condition for Opportunity
        // Start
        String requestBody = sObjectType.equalsIgnoreCase('Lead') ?
                PS_PaymentUtility.buildCustomerRequestBodyFromLead(currentLead) :
                sObjectType.equalsIgnoreCase('Order') ? PS_PaymentUtility.buildCustomerRequestBodyFromOrder(currentOrder) :
                        (sObjectType.equalsIgnoreCase('Account') || sObjectType.equalsIgnoreCase('Opportunity')) ? PS_PaymentUtility.buildCustomerRequestBodyFromAccount(currentAccount) : '';

        // End
        System.debug('Request Body: ' + requestBody);

        HttpRequest request = new HttpRequest();
        // String requestBody = constructRequestBody();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Basic ' + reepayPrivateKey);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        request.setBody(requestBody);
        
        System.debug('Sending HTTP request to Reepay...');
        Http http = new Http();
        HttpResponse response = http.send(request);
        System.debug('Response Status Code: ' + response.getStatusCode());
        System.debug('Response Body: ' + response.getBody());
        if ((response.getStatusCode() == 200 || response.getStatusCode() == 400) && !String.isBlank(response.getBody())) {
            if (response.getStatusCode() == 200) {
                customerResponseWrapperInstance.message = 'Customer created successfully';
                return customerResponseWrapperInstance;
            } else if (response.getStatusCode() == 400) {
                PS_PaymentUtility.CustomerResponseWrapper customerResponse = (PS_PaymentUtility.CustomerResponseWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.CustomerResponseWrapper.class);
                if (customerResponse.message != null && customerResponse.message.equals('customer already exists') && customerResponse.http_status == 400) {
                    customerResponseWrapperInstance.message = customerResponse.message;
                    return customerResponseWrapperInstance;
                } else {
                    customerResponseWrapperInstance.error = customerResponse.error;
                }
                return customerResponseWrapperInstance;
            }
        }
        DFJ_ErrorLogController.addErrorLogs('', 'Creating reepayCustomer', JSON.serialize(response.getBody()), 'Error', 'PS_PaymentService.createReepayCustomer', '', '');
        customerResponseWrapperInstance.error = 'Unable to create the customer';
        return customerResponseWrapperInstance;
    }
    

     /*
    * @Description  method create the subscription record.
    * @Param        invoicePayment,subscriptionLeadProducts
    * @Return       PS_PaymentUtility.PaymentStatusWrapper
    */
     public static PS_PaymentUtility.PS_SubscriptionWrapper createSubscriptionWithFullDiscount(Payments__c invoicePayment, List<SObject> subscriptionLeadProducts) {
        PS_PaymentUtility.PS_SubscriptionWrapper responseWrapperIns = new PS_PaymentUtility.PS_SubscriptionWrapper();
        List<Payments__c> getUpdatedPayment = new List<Payments__c>();
        try {

            // Get Reepay private key based on Pricebook
            String reepayPrivateKey = getReepayPrivateKeyFromPayment(invoicePayment);
            HttpRequest request = new HttpRequest();

            String endpointUrl = createSubscriptionURL;
            String requestBody = PS_PaymentUtility.constructSubscriptionRequestBodyWith0Amount(invoicePayment, subscriptionLeadProducts);


            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + reepayPrivateKey);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);
            request.setBody(requestBody);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200 && !String.isBlank(response.getBody())) {
                responseWrapperIns = (PS_PaymentUtility.PS_SubscriptionWrapper) JSON.deserialize((response.getBody()), PS_PaymentUtility.PS_SubscriptionWrapper.class);
                //DFJ-128 Starts
                try {
                    // DFJ-191 Changes
                    List<Subscriptions__c> getSubscriptionsList = [SELECT Id FROM Subscriptions__c WHERE Subscription_handle__c = :responseWrapperIns.handle LIMIT 1];
                    if (getSubscriptionsList.isEmpty()) {//End
                        //DFJ-191 Added params Plan_Amount__c,Plan_Version__c in getUpdatedPayment query
                        getUpdatedPayment = [SELECT Id, Lead__c, Order__r.Lead__c, OwnerId, Lead__r.ConvertedAccountId, Order__r.AccountId, Plan_Name__c, Plan_Amount__c, Plan_Version__c FROM Payments__c WHERE Id = :invoicePayment.Id LIMIT 1];
                        //End
                        Subscriptions__c subRecord = new Subscriptions__c();
                        subRecord.OwnerId = UserInfo.getUserId();
                        subRecord.Account__c = (getUpdatedPayment[0].Lead__r.ConvertedAccountId != null ? getUpdatedPayment[0].Lead__r.ConvertedAccountId : getUpdatedPayment[0].Order__r.AccountId != null ? getUpdatedPayment[0].Order__r.AccountId : null);
                        subRecord.Subscriptions_Status__c = responseWrapperIns.in_trial == true ? 'Trial' : responseWrapperIns.state == 'active' ? 'Active' : null ;//responseWrapperIns.state;
                        subRecord.Trial_Start_Date__c = responseWrapperIns.trial_start;
                        subRecord.Trial_End_Date__c = responseWrapperIns.trial_end;
                        //DFJ-168 Changes
                        subRecord.Next_Renewal_Date__c = responseWrapperIns.next_period_start;
                        subRecord.Total_Subscription_Amount__c = Decimal.valueOf(responseWrapperIns.settled_amount) / 100;//responseWrapperIns.settled_amount;
                        //End
                        subRecord.Plan_Name__c = invoicePayment.Plan_Name__c;
                        //DFJ-191 Changes
                        subRecord.Plan_Amount__c = (invoicePayment.Plan_Amount__c != null ? invoicePayment.Plan_Amount__c : null);
                        subRecord.Plan_Version__c = (invoicePayment.Plan_Version__c != null ? invoicePayment.Plan_Version__c : null);
                        subRecord.Current_Subscription_Period_Start__c = responseWrapperIns.current_period_start;//DFJ-191 Changes
                        subRecord.Plan_Has_Trial__c = responseWrapperIns.in_trial == true ? true : false;
                        subRecord.Subscription_Created_Date__c = responseWrapperIns.created;
                        //End

                        subRecord.Plan_ID__c = String.valueOf(subscriptionLeadProducts[0].get('Plan_handle__c'));
                        subRecord.Subscription_handle__c = String.valueOf(subscriptionLeadProducts[0].get('Id'));
                        subRecord.Lead__c = getUpdatedPayment[0].Lead__c != null ? getUpdatedPayment[0].Lead__c : getUpdatedPayment[0].Order__r.Lead__c != null ? getUpdatedPayment[0].Order__r.Lead__c : null ;
                        //subRecord.Trial_Status__c = responseWrapperIns.in_trial == true ? 'Active' : null;
                        subRecord.Renewals__c = responseWrapperIns.renewal_count;
                        insert subRecord;
                        //DFJ-168 Changes
                        getUpdatedPayment[0].Subscriptions__c = subRecord.Id;
                        update getUpdatedPayment;
                        //End
                    }

                } catch (Exception ex) {
                    DFJ_ErrorLogController.addErrorLogs('', 'Create Subscription With Full Discount' + getUpdatedPayment[0].Id + ' ', ex.getMessage(), 'Error', 'PS_PaymentService.createSubscriptionWithFullDiscount', '', String.valueOf(ex.getLineNumber()));
                }
                //End
            }
            //ChnagesDIN-330
            //Start
            else if (response.getStatusCode() == 400 && !String.isBlank(response.getBody())) {
                responseWrapperIns.error = 'Add new Subscription Lead Products';
            }
            //End
        } catch (Exception ex) {
            responseWrapperIns.error = ex.getMessage();
            DFJ_ErrorLogController.addErrorLogs('', 'Creating create Subscription callout', ex.getMessage(), 'Error', 'PS_PaymentService.createSubscriptionWithFullDiscount', '', String.valueOf(ex.getLineNumber()));
        }
        return responseWrapperIns;
    }


 /*
    * @Description  method to get Plan Info.
    * @Param        SubscriptionLeadProducts
    * @Return       PS_PaymentUtility.PaymentPlanWrapper
    */
     public static PS_PaymentUtility.PS_PlanInfokWrapper getCurrentPlanInformation(Payments__c payment, List<SObject> subscriptionProducts) {
        PS_PaymentUtility.PS_PlanInfokWrapper planInfoInstance = new PS_PaymentUtility.PS_PlanInfokWrapper();
        try {

            // Get Reepay config based on pricebook
            String privateKey = getReepayPrivateKeyFromPayment(payment);
            HttpRequest request = new HttpRequest();

            String endpointUrl = 'https://api.reepay.com/v1/plan/' + subscriptionProducts[0].get('Plan_handle__c') + '/current' ;
            request.setEndpoint(endpointUrl);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Basic ' + privateKey);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);


            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200 || String.isBlank(response.getBody())) {
                planInfoInstance = (PS_PaymentUtility.PS_PlanInfokWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.PS_PlanInfokWrapper.class);
                return planInfoInstance;
            } else if (response.getStatusCode() == 404 && !String.isBlank(response.getBody())) {
                planInfoInstance.error = 'Current Subscription Plan not found';
                DFJ_ErrorLogController.addErrorLogs('', 'PS_PlanInfokWrapper not 200', String.valueOf(planInfoInstance), 'Error', 'PS_PaymentService.PS_PlanInfokWrapper', '', '');
            } else {
                planInfoInstance.error = 'Somethong went wrong.';
            }
        } catch (Exception ex) {
            planInfoInstance.error = ex.getMessage();
            DFJ_ErrorLogController.addErrorLogs('', 'PS_PlanInfokWrapper', ex.getMessage(), 'Error', 'PS_PaymentService.PS_PlanInfokWrapper', '', String.valueOf(ex.getLineNumber()));
        }
        return planInfoInstance;
    }

     /*
    * @Description  method to genereate the payment link.
    * @Param        invoicePayment
    * @Return       PS_PaymentUtility.PaymentStatusWrapper
    */
     public static PS_PaymentUtility.PaymentLinkWrapper generatePaymentLink(Payments__c payment, String sessionType, PS_PaymentUtility.PS_PlanInfokWrapper getPlanInfo, Boolean isRecurringSettle) {
        PS_PaymentUtility.PaymentLinkWrapper linkStatusInstance = new PS_PaymentUtility.PaymentLinkWrapper();


        try {
            // Get Reepay config based on pricebook
            String privateKey = getReepayPrivateKeyFromPayment(payment);
            HttpRequest request = new HttpRequest();


            String endpointUrl = sessionType.equalsIgnoreCase('charge') ? chargeSessionURL : sessionType.equalsIgnoreCase('reoccuring') ? reoccuringSessionURL : sessionType.equalsIgnoreCase('subscription') ? subscriptionSessionURL : chargeSessionURL;

            String requestBody = PS_PaymentUtility.constructPaymentLinkBody(payment, true, getPlanInfo, isRecurringSettle);
            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + privateKey);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);
            request.setBody(requestBody);
            Http http = new Http();
            HttpResponse response = http.send(request);

            linkStatusInstance = (PS_PaymentUtility.PaymentLinkWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.PaymentLinkWrapper.class);
            if (response.getStatusCode() != 200 || !String.isBlank(response.getBody())) {
                linkStatusInstance.success = 'Link generated';
                return linkStatusInstance;
            } else {
                DFJ_ErrorLogController.addErrorLogs('', 'generatePaymentLink not 200', String.valueOf(linkStatusInstance), 'Error', 'PS_PaymentService.generatePaymentLink', '', '');
            }
        } catch (Exception ex) {
            linkStatusInstance.error = ex.getMessage();
            DFJ_ErrorLogController.addErrorLogs('', 'Generate Payment Link', ex.getMessage(), 'Error', 'PS_PaymentService.generatePaymentLink', '', String.valueOf(ex.getLineNumber()));
        }
        return linkStatusInstance;
    }


}