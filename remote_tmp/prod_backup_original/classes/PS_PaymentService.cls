/*
   * @ Version : 1.0
   * @ Created Date : 2022-06-29
   * @Description : Handle the reepay operations.
*/
public with sharing class PS_PaymentService {
    public static final String customerCreationURL = 'https://api.reepay.com/v1/customer';
    public static final String invoiceCreationURL = 'https://api.reepay.com/v1/customer';
    public static final String settleInvoiceURL = 'https://api.reepay.com/v1/invoice/';
    public static final String createSubscriptionURL = 'https://api.reepay.com/v1/subscription';
    public static final String chargeSessionURL = 'https://checkout-api.reepay.com/v1/session/charge';
    public static final String reoccuringSessionURL = 'https://checkout-api.reepay.com/v1/session/recurring';
    public static final String subscriptionSessionURL = 'https://checkout-api.reepay.com/v1/session/subscription';
    public static final String cancelInvoiceURL = 'https://api.reepay.com/v1/invoice/';
    public static final String cancelSubscriptionURL = 'https://api.reepay.com/v1/subscription/';

    //    DFJ-318 changes start
    public static String refundApiEndpoint = 'https://api.reepay.com/v1/refund';
    public static String expireSubscriptionApiEndpoint = 'https://api.reepay.com/v1/subscription/{handle}/expire';
    public static String cancelSubscriptionApiEndpoint = 'https://api.reepay.com/v1/subscription/{handle}/cancel';
    //    DFJ-318 changes end

    //    DFJ-319 changes start
    public static String offlineManualSettleEndpoint = 'https://api.reepay.com/v1/invoice/{id}/manual_settle';
    //    DFJ-319 changes end

    /*
    * @Description  method to create the payment record.
    * @Param        recordId
    * @Return       String
    */
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
                        'Id', 'AccountId', 'Order_Total__c', 'Fixed_Discount_Type__c'
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
            } else {
                paymentRelatedWrapperInstance = createPaymentAndOrderItems(recordId, sObjectType, currentLead, currentOrder);
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

//     Changes for DFJ-273
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

            if (String.isBlank(paymentCurrency)) {
                paymentCurrency = (!accountRelatedToOpportunity.isEmpty()) ?
                        accountRelatedToOpportunity[0].CurrencyIsoCode : '';
            }

            paymentRecord.Type__c = 'Onetime';
            paymentRecord.Amount__c = currentOpp[0].Order_Total__c;

            paymentRecord.CurrencyIsoCode = paymentCurrency;
            paymentRecord.BillingStreet__c = accountRelatedToOpportunity[0].BillingStreet;

            paymentRecord.BillingState__c = accountRelatedToOpportunity[0].BillingState;

            paymentRecord.Billing_PostalCode__c = accountRelatedToOpportunity[0].BillingPostalCode;

            paymentRecord.BillingCity__c = accountRelatedToOpportunity[0].BillingCity;

            paymentRecord.BillingCountry__c = (accountRelatedToOpportunity[0].Market_Unit__c.equals('DFJ_DK') || accountRelatedToOpportunity[0].Market_Unit__c.equals('Testamente_DK') ? 'DK' : 'SE');

            paymentRecord.Billing_name__c = accountRelatedToOpportunity[0].Name;

            paymentRecord.Billing_email__c = accountRelatedToOpportunity[0].PersonEmail;

            paymentRecord.Fixed_discount_Type__c = currentOpp[0].Fixed_Discount_Type__c;

            List<Payments__c> isPaymentInserted = new List<Payments__c>();

            if (paymentRecord.Amount__c >= 0) {
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
    // End


//DFJ-80
    public static PS_PaymentUtility.PaymentWrapper createPaymentRecordOnAccount(Id recordId, Order orderRecord, String orderProductList, Decimal orderFixedDisc, Decimal totalOrder, String selectedJournal) {
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        List<Journal_Address_Configration__mdt> recordFormConfigurationInstance = new List<Journal_Address_Configration__mdt>();
        try {


            List<OrderItem> orderItemForSubscription = new List<OrderItem>();
            List<OrderItem> orderItems = new List<OrderItem>();
            List<String> fieldList = new List<String>();
            String paymentCurrency = '';
            Boolean isCurrencyChanged = false;
            Decimal amount = 0;
            List<Account> getAccountRec = new List<Account>();
            Payments__c paymentRecord = new Payments__c();

            List<Journal__c> getAddresInfoFromJournal = new List<Journal__c>();
            String sObjectType = PS_PaymentUtility.getSobjectTypeFromRecordId_Apex(recordId);
            if (sObjectType.equalsIgnoreCase('Account')) {
                // fieldList = new List<String>{'Id','Name','Status__c','Type__c'};
                getAccountRec = PS_PaymentUtility.fetchRecordsDynamically('Id = \'' + recordId + '\'', new List<String>{
                        'Id', 'Name', 'PersonEmail', 'Market_Unit__c'
                }, sObjectType);
                if (getAccountRec == null || getAccountRec.isEmpty() || String.isBlank(getAccountRec[0].PersonEmail)) {
                    paymentRelatedWrapperInstance.errorMessage = 'Please populate the email on Account';
                    return paymentRelatedWrapperInstance;
                }
            }
            //get address from selected journal
            getAddresInfoFromJournal = [SELECT Id, DocFab_Record_Model_ID__c, External_record_uuid__c, Type__c FROM Journal__c WHERE Id = :selectedJournal AND Account__c = :getAccountRec[0].Id LIMIT 1];


            if (!getAddresInfoFromJournal.isEmpty()) {


                recordFormConfigurationInstance = [
                        SELECT Id,

                                Market_unit_name__c,
                                Journal_type__c,
                                Journal_Object__c,
                                Address_Configuration_Fields__c
                        FROM
                                Journal_Address_Configration__mdt
                        WHERE
                                Market_unit_name__c = :getAccountRec[0].Market_Unit__c
                                AND
                                Journal_type__c = :getAddresInfoFromJournal[0].Type__c
                                AND
                                Default_Record_model_id__c = :getAddresInfoFromJournal[0].DocFab_Record_Model_ID__c
                        LIMIT 1
                ];

                if (!recordFormConfigurationInstance.isEmpty() && String.isNotBlank(recordFormConfigurationInstance[0].Journal_Object__c) && String.isNotBlank(recordFormConfigurationInstance[0].Address_Configuration_Fields__c)) {
                    Map<String, String> mapOfAddressFieldsConfig = (Map<String, String>) JSON.deserialize(recordFormConfigurationInstance[0].Address_Configuration_Fields__c, Map<String, String>.class);

                    String addressFields = '';
                    String fromObject = recordFormConfigurationInstance[0].Journal_Object__c;
                    String addressObjectCond = 'Journal__c';
                    if (fromObject == 'df_160_person__c') {
                        addressObjectCond = 'journal_dk_new__r.Journal__c';
                    }
                    for (String addressField : mapOfAddressFieldsConfig.keySet()) {
                        addressFields = addressFields + mapOfAddressFieldsConfig.get(addressField) + ',';
                    }

                    addressFields = addressFields.removeEnd(',');
                    String query = 'SELECT uuid__c, Id, version__c' + (String.isNotBlank(addressFields) ? ',' + addressFields : '') + ' FROM ' + recordFormConfigurationInstance[0].Journal_Object__c + ' WHERE ' + addressObjectCond + ' = \'' + getAddresInfoFromJournal[0].Id + '\' ORDER BY CreatedDate DESC LIMIT 1';
                    List<SObject> journalRecord = Database.query(query);
                    if (!journalRecord.isEmpty()) {
                        paymentRecord.BillingStreet__c = !String.isBlank((String) journalRecord[0].get(mapOfAddressFieldsConfig.get('Street'))) ? (String) journalRecord[0].get(mapOfAddressFieldsConfig.get('Street')) : '' ;
                        paymentRecord.Billing_PostalCode__c = !String.isBlank(String.valueOf(journalRecord[0].get(mapOfAddressFieldsConfig.get('PostalCode')))) ? String.valueOf(journalRecord[0].get(mapOfAddressFieldsConfig.get('PostalCode'))) : null;
                        paymentRecord.BillingCity__c = !String.isBlank((String) journalRecord[0].get(mapOfAddressFieldsConfig.get('City'))) ? (String) journalRecord[0].get(mapOfAddressFieldsConfig.get('City')) : '';
                    }

                }
            }
            List<OrderItem> orderItemList = (List<OrderItem>) JSON.deserialize(orderProductList, List<OrderItem>.class);

            if (orderItemList.isEmpty()) {
                paymentRelatedWrapperInstance.errorMessage = 'Please add the order products first';
                return paymentRelatedWrapperInstance;
            }
            for (OrderItem paymentOrderLoop : orderItemList) {
                if (paymentOrderLoop.Is_subscription__c) {
                    orderItemForSubscription.add(paymentOrderLoop);
                }
                isCurrencyChanged = String.isBlank(paymentCurrency) || paymentCurrency == paymentOrderLoop.CurrencyIsoCode ? false : true;
                paymentCurrency = paymentOrderLoop.CurrencyIsoCode;
            }

            if (isCurrencyChanged) {
                paymentRelatedWrapperInstance.errorMessage = 'Some product have not same currency';
                return paymentRelatedWrapperInstance;
            }
            paymentRecord.Account__c = recordId;
            paymentRecord.Type__c = 'Onetime';
            paymentRecord.Amount__c = totalOrder ;
            paymentRecord.CurrencyIsoCode = paymentCurrency ;
            /* paymentRecord.BillingStreet__c = getAccountRec[0].BillingStreet;
             paymentRecord.BillingState__c = getAccountRec[0].BillingState;
             paymentRecord.Billing_PostalCode__c= getAccountRec[0].BillingPostalCode;
             paymentRecord.BillingCity__c = getAccountRec[0].BillingCity;*/
            //Order Fields
            paymentRecord.Pricebook2Id__c = orderRecord.Pricebook2Id;
            // paymentRecord.Lead__c = orderRecord.Lead__c;
            paymentRecord.Order_Status__c = orderRecord.Status;
            paymentRecord.Check_Payment_On_Account__c = true;
            //paymentRecord.EffectiveDate__c = orderRecord.EffectiveDate;
            paymentRecord.Market_Unit__c = orderRecord.Market_Unit__c;
            paymentRecord.Related_Event_ID__c = !String.isBlank(orderRecord.Related_Event_ID__c) ? orderRecord.Related_Event_ID__c : '' ;
            paymentRecord.Fixed_discount_Type__c = (orderRecord.Fixed_discount_Type__c != null) ? orderRecord.Fixed_discount_Type__c : 0 ;
            paymentRecord.Campaign__c = !String.isBlank(orderRecord.Campaign__c) ? orderRecord.Campaign__c : null ;
            paymentRecord.Journal__c = !String.isBlank(orderRecord.Journal__c) ? orderRecord.Journal__c : null ;
            paymentRecord.IsInsertOrder__c = true;
            //End
            paymentRecord.BillingCountry__c = (getAccountRec[0].Market_Unit__c == 'DFJ_DK' || getAccountRec[0].Market_Unit__c == 'Testamente_DK' ? 'DK' : 'SE');
            paymentRecord.Billing_name__c = getAccountRec[0].Name;
            paymentRecord.Billing_email__c = getAccountRec[0].PersonEmail;
            // paymentRecord.Fixed_discount_Type__c = orderFixedDisc; //DIN-337
            List<Payments__c> isPaymentInserted = new List<Payments__c>();
            if (paymentRecord.Amount__c >= 0) {
                isPaymentInserted = PS_PaymentUtility.dmlHelper(new List<Payments__c>{
                        paymentRecord
                }, 'INSERT');
            }

            List<Payment_order_line__c> isPaymentOrderItemInserted = new List<Payment_order_line__c>();

            if (!isPaymentInserted.isEmpty()) {
                List<Payment_order_line__c> paymentOrderItemlistToCreate = new List<Payment_order_line__c>();

                paymentOrderItemlistToCreate = PS_PaymentUtility.createPaymentOrderItemOnAccount(orderItemList, isPaymentInserted);
                isPaymentOrderItemInserted = PS_PaymentUtility.dmlHelper(paymentOrderItemlistToCreate, 'INSERT');

            }
            if (isPaymentOrderItemInserted == null) {
                paymentRelatedWrapperInstance.errorMessage = 'Unable to create the payment order items';
                return paymentRelatedWrapperInstance;
            }
            if (!isPaymentInserted.isEmpty()) {
                paymentRelatedWrapperInstance.payment = isPaymentInserted[0];
            }
            paymentRelatedWrapperInstance.paymentOrderLines = isPaymentOrderItemInserted;
            paymentRelatedWrapperInstance.subscriptionOrderItemProducts = orderItemForSubscription;
            paymentRelatedWrapperInstance.successMessage = 'Created successfully.';
            return paymentRelatedWrapperInstance;
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Creating payment and payment order lines', ex.getMessage(), 'Error', 'PS_PaymentService.createPaymentRecordOnAccount', '', String.valueOf(ex.getLineNumber()));
            paymentRelatedWrapperInstance.errorMessage = ex.getMessage();
        }
        return paymentRelatedWrapperInstance;

    }

//End

//DFJ-80
    public static PS_PaymentUtility.PaymentWrapper getUpdatedPayment(Id recordId) {
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        try {
            List<Payments__c> getPayment = [SELECT Id, Status__c, BillingStreet__c, Billing_PostalCode__c, BillingCity__c, CurrencyIsoCode, BillingCountry__c, Billing_name__c, Subscription_status__c, Amount__c, Payment_link__c FROM Payments__c WHERE Id = :recordId LIMIT 1];
            if (!getPayment.isEmpty()) {
                paymentRelatedWrapperInstance.payment = getPayment[0];
            }

            return paymentRelatedWrapperInstance;
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Fetching payment ', ex.getMessage(), 'Error', 'PS_PaymentService.getUpdatedPayment', '', String.valueOf(ex.getLineNumber()));
            paymentRelatedWrapperInstance.errorMessage = ex.getMessage();
        }
        return paymentRelatedWrapperInstance;

    }
//End

    /*
    * @Description  method to create the payment record.
    * @Param        recordId
    * @Return       String
    */
    public static PS_PaymentUtility.PaymentWrapper createPaymentAndOrderItems(Id recordId, String sObjectType, List<Lead> currentLead, List<Order> currentOrder) {

        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        try {
            List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();
            List<LeadProducts__c> leadProductsForSubscription = new List<LeadProducts__c>();
            List<OrderItem> orderItemForSubscription = new List<OrderItem>();
            List<OrderItem> orderItems = new List<OrderItem>();
            List<String> fieldList = new List<String>();
            String paymentCurrency = '';
            Boolean isCurrencyChanged = false;
            Decimal amount = 0;

            if (sObjectType.equalsIgnoreCase('Lead')) {
                leadProducts = [SELECT Id, Sub_Total__c, Discount__c, Is_subscription__c, Plan_handle__c, Item_Price__c, Lead__c, Name, Pricebook_Id__c, CurrencyIsoCode, PricebookEntry_Id__c, Product_Id__c, Product_Name__c, Quantity__c, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c FROM LeadProducts__c WHERE Lead__c = :recordId];
                if (leadProducts.isEmpty()) {
                    paymentRelatedWrapperInstance.errorMessage = 'Please add the lead product first';
                    return paymentRelatedWrapperInstance;
                }
            } else if (sObjectType.equalsIgnoreCase('Order')) {
                String orderItemCondition = 'OrderId = \'' + recordId + '\'';
                List<String> orderItemFieldList = new List<String>{
                        'Id', 'Effective_price__c', 'Quantity', 'UnitPrice', 'ListPrice', 'TotalPrice', 'Product_Name__c', 'Is_subscription__c', 'Plan_handle__c', 'CurrencyIsoCode', 'Discount__c'
                };

                orderItems = PS_PaymentUtility.fetchRecordsDynamically(orderItemCondition, orderItemFieldList, 'OrderItem');

                if (orderItems.isEmpty()) {
                    paymentRelatedWrapperInstance.errorMessage = 'Please add the order products first';
                    return paymentRelatedWrapperInstance;
                }
            }

            if (sObjectType.equalsIgnoreCase('Lead')) {
                for (LeadProducts__c leadProductIteration : leadProducts) {
                    // Added condition for subscription creation.
                    // DFJ-191 Changes Changed the !leadProductIteration.Is_subscription__c to show the correct amount on Payment status component

                    Payment_order_line__c paymentOrderItem = new Payment_order_line__c(); //leadProductIteration.Sub_Total__c > 0 ?
                    amount += (leadProductIteration.Item_Price__c - (leadProductIteration.Item_Price__c * leadProductIteration.Discount__c / 100)) * leadProductIteration.Quantity__c ;//: 0;
                    isCurrencyChanged = String.isBlank(paymentCurrency) || paymentCurrency == leadProductIteration.CurrencyIsoCode ? false : true;
                    paymentCurrency = leadProductIteration.CurrencyIsoCode;
                    if (leadProductIteration.Is_subscription__c) {
                        leadProductsForSubscription.add(leadProductIteration);
                    }//End

                }
                if (isCurrencyChanged) {
                    paymentRelatedWrapperInstance.errorMessage = 'Some product have not same currency';
                    return paymentRelatedWrapperInstance;
                }
            }
            if (sObjectType.equalsIgnoreCase('Order')) {
                for (OrderItem orderLoop : orderItems) {
                    if (orderLoop.Is_subscription__c) {
                        orderItemForSubscription.add(orderLoop);
                    }
                }
            }
            Payments__c paymentRecord = new Payments__c();
            if (sObjectType.equalsIgnoreCase('Lead')) {
                paymentRecord.Lead__c = recordId;
            } else if (sObjectType.equalsIgnoreCase('Order')) {
                paymentRecord.Order__c = recordId;
            }

            //Start TCS-36 Changes
            if (String.isBlank(paymentCurrency)) {
                paymentCurrency = (!leadProductsForSubscription.isEmpty() ? leadProductsForSubscription[0].CurrencyIsoCode : '');
            }
            //End
            paymentRecord.Type__c = 'Onetime';
            paymentRecord.Amount__c = sObjectType.equalsIgnoreCase('Lead') ? (currentLead[0].Fixed_discount_Type__c <= amount ? (amount - currentLead[0].Fixed_discount_Type__c) : (currentLead[0].Fixed_discount_Type__c == null ? amount : 0)) : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].Order_Price__c : 0);

            paymentRecord.CurrencyIsoCode = sObjectType.equalsIgnoreCase('Lead') ? (String.isNotBlank(paymentCurrency) ? paymentCurrency : currentLead[0].CurrencyIsoCode) : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].CurrencyIsoCode : '');
            paymentRecord.BillingStreet__c = sObjectType.equalsIgnoreCase('Lead') ? currentLead[0].Street : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].BillingStreet : '');
            paymentRecord.BillingState__c = sObjectType.equalsIgnoreCase('Lead') ? currentLead[0].State : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].BillingState : '');
            paymentRecord.Billing_PostalCode__c = sObjectType.equalsIgnoreCase('Lead') ? currentLead[0].PostalCode : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].BillingPostalCode : '');
            paymentRecord.BillingCity__c = sObjectType.equalsIgnoreCase('Lead') ? currentLead[0].City : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].BillingCity : '');
            //Chnages TCS-50 Start
            //paymentRecord.BillingCountry__c = sObjectType.equalsIgnoreCase('Lead') ? currentLead[0].CurrencyIsoCode : ( sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].BillingCountry : '' );
            paymentRecord.BillingCountry__c = sObjectType.equalsIgnoreCase('Lead') ? (currentLead[0].Market_Unit__c == 'DFJ_DK' || currentLead[0].Market_Unit__c == 'Testamente_DK' ? 'DK' : 'SE') : (sObjectType.equalsIgnoreCase('Order') ? (currentOrder[0].Account.Market_Unit__c == 'DFJ_DK' || currentOrder[0].Account.Market_Unit__c == 'Testamente_DK' ? 'DK' : 'SE') : '');
            //End
            paymentRecord.Billing_name__c = sObjectType.equalsIgnoreCase('Lead') ? currentLead[0].Name : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].Account.Name : '');
            paymentRecord.Billing_email__c = sObjectType.equalsIgnoreCase('Lead') ? currentLead[0].Email : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].Account.PersonEmail : '');
            paymentRecord.Fixed_discount_Type__c = sObjectType.equalsIgnoreCase('Lead') ? currentLead[0].Fixed_discount_Type__c : (sObjectType.equalsIgnoreCase('Order') ? currentOrder[0].Fixed_discount_Type__c : 0); //DIN-337

            List<Payments__c> isPaymentInserted = new List<Payments__c>();
            //Changes TCS-35 Start
            if (paymentRecord.Amount__c >= 0) {
                isPaymentInserted = PS_PaymentUtility.dmlHelper(new List<Payments__c>{
                        paymentRecord
                }, 'INSERT');
            }

            //End
            List<Payment_order_line__c> isPaymentOrderItemInserted = new List<Payment_order_line__c>();

            if (!isPaymentInserted.isEmpty()) {
                List<Payment_order_line__c> paymentOrderItemlistToCreate = new List<Payment_order_line__c>();

                paymentOrderItemlistToCreate = PS_PaymentUtility.createPaymentOrderItemBySobject(sObjectType, leadProducts, orderItems, isPaymentInserted);
                isPaymentOrderItemInserted = PS_PaymentUtility.dmlHelper(paymentOrderItemlistToCreate, 'INSERT');
            }
            if (isPaymentOrderItemInserted == null) {

                paymentRelatedWrapperInstance.errorMessage = 'Unable to create the payment order items';
                return paymentRelatedWrapperInstance;
            }
            if (!isPaymentInserted.isEmpty()) {

                paymentRelatedWrapperInstance.payment = isPaymentInserted[0];

            }

            paymentRelatedWrapperInstance.paymentOrderLines = isPaymentOrderItemInserted;
            paymentRelatedWrapperInstance.subscriptionLeadProducts = leadProductsForSubscription;
            paymentRelatedWrapperInstance.subscriptionOrderItemProducts = orderItemForSubscription;
            paymentRelatedWrapperInstance.successMessage = 'Created successfully.';

        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Create Payment and Order Items.', e.getMessage(), 'Error', 'PS_PaymentService.createPaymentAndOrderItems', '', String.valueOf(e.getLineNumber()));
        }

        return paymentRelatedWrapperInstance;
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
                    paymentOrder.CurrencyISOCode
            );
            // End

            if (customerPresentString.contains('Error :')) {
                paymentRelatedWrapperInstance.errorMessage = customerPresentString;
                return paymentRelatedWrapperInstance;
            } else if (customerPresentString.equalsIgnoreCase('Not found')) {
                // createCustomer
                PS_PaymentUtility.CustomerResponseWrapper responseWrapperIns = new PS_PaymentUtility.CustomerResponseWrapper();
                List<Payment_order_line__c> paymentOrderItems = new List<Payment_order_line__c>();
                paymentOrderItems = (List<Payment_order_line__c>) JSON.deserialize(paymentOrderLines, List<Payment_order_line__c>.class);
                // Changes DFJ-80 :: Added param currentAccount in createReepayCustomer class
                PS_PaymentUtility.CustomerResponseWrapper isCustomerCreated = createReepayCustomer(currentAccount, currentLead, currentOrder, paymentOrder.CurrencyIsoCode, sObjectType);
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
//DFJ-80
    public static PS_PaymentUtility.PaymentWrapper showPaymentStatusOnAccount(Id recordId) {
        PS_PaymentUtility.PaymentWrapper paymentRelatedWrapperInstance = new PS_PaymentUtility.PaymentWrapper();
        try {
            List<Payments__c> updatedPayment = new List<Payments__c>();

            String paymentCondition = 'Id = \'' + recordId + '\'';
            List<String> paymentFieldList = new List<String>{
                    'Id', 'Status__c', 'CurrencyIsoCode', 'BillingStreet__c', 'BillingState__c', 'Billing_PostalCode__c', 'BillingCity__c', 'BillingCountry__c', 'Billing_name__c', 'Subscription_status__c', 'Amount__c', 'Payment_link__c'
            };

            updatedPayment = PS_PaymentUtility.fetchRecordsDynamically(paymentCondition, paymentFieldList, 'Payments__c');

            if (!updatedPayment.isEmpty()) {
                paymentRelatedWrapperInstance.payment = updatedPayment[0];
                return paymentRelatedWrapperInstance;
            }


        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Fetching updated payment record.', ex.getMessage(), 'Error', 'PS_PaymentService.showPaymentStatusOnAccount', '', String.valueOf(ex.getLineNumber()));
            paymentRelatedWrapperInstance.errorMessage = ex.getMessage();
        }
        return paymentRelatedWrapperInstance;
    }
    //End
    /*
    * @Description  method to check for the customer record .
    * @Param        recordId
    * @Return       String
    */
    public static String checkCustomerAlreadyCreated(String currentEmail, String paymentCurrency) {
        Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(paymentCurrency);
        Boolean customerFound = false;
        String endpointUrl = customerCreationURL;
        PS_PaymentUtility.CustomerWrapper customerWrapper = new PS_PaymentUtility.CustomerWrapper();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl + '/' + currentEmail);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);

        Http http = new Http();
        HttpResponse response = http.send(request);

        if ((response.getStatusCode() == 200 && !String.isBlank(response.getBody()))) {
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
    public static PS_PaymentUtility.CustomerResponseWrapper createReepayCustomer(List<Account> currentAccount, List<Lead> currentLead, List<Order> currentOrder, String metaCurrency, String sObjectType) {
        PS_PaymentUtility.CustomerResponseWrapper customerResponseWrapperInstance = new PS_PaymentUtility.CustomerResponseWrapper();
        Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(metaCurrency);
        String endpointUrl = customerCreationURL;
        // Changes DFJ-80 :: Added class buildCustomerRequestBodyFromAccount to created request body

        // Changes for DFJ-273
        // Added condition for Opportunity
        // Start
        String requestBody = sObjectType.equalsIgnoreCase('Lead') ?
                PS_PaymentUtility.buildCustomerRequestBodyFromLead(currentLead) :
                sObjectType.equalsIgnoreCase('Order') ? PS_PaymentUtility.buildCustomerRequestBodyFromOrder(currentOrder) :
                        (sObjectType.equalsIgnoreCase('Account') || sObjectType.equalsIgnoreCase('Opportunity')) ? PS_PaymentUtility.buildCustomerRequestBodyFromAccount(currentAccount) : '';

        // End

        HttpRequest request = new HttpRequest();
        // String requestBody = constructRequestBody();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        request.setBody(requestBody);
        Http http = new Http();
        HttpResponse response = http.send(request);
        if ((response.getStatusCode() == 200 || response.getStatusCode() == 400) && !String.isBlank(response.getBody())) {
            if (response.getStatusCode() == 200) {
                customerResponseWrapperInstance.message = 'Customer created successfully';
                return customerResponseWrapperInstance;
            } else if (response.getStatusCode() == 400) {
                PS_PaymentUtility.CustomerResponseWrapper customerResponse = (PS_PaymentUtility.CustomerResponseWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.CustomerResponseWrapper.class);
                if (customerResponse.message.equals('customer already exists') && customerResponse.http_status == 400) {
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
    * @Description  method to create the invoice record.
    * @Param        recordId
    * @Return       String
    */
    public static PS_PaymentUtility.CustomerResponseWrapper createReepayCustomerInvoice(String currentEmail, Payments__c payment, List<Payment_order_line__c> paymentOrderLines, List<sObject> subscriptionProducts) {
        PS_PaymentUtility.CustomerResponseWrapper responseWrapperIns = new PS_PaymentUtility.CustomerResponseWrapper();

        try {
            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(payment.CurrencyISOCode);


            //Changes TCS-35 start
            if (payment.Amount__c > 0) {
                HttpRequest request = new HttpRequest();

                String endpointUrl = invoiceCreationURL + '/' + currentEmail + '/invoice';


                String requestBody = PS_PaymentUtility.constructInvoiceRequestBody(payment, paymentOrderLines, subscriptionProducts); //TCS-16 Chnages Add LeadProducts in invoice body


                request.setEndpoint(endpointUrl);
                request.setMethod('POST');
                request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
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
            update payment;
        } catch (Exception ex) {
            responseWrapperIns.error = ex.getMessage();
            DFJ_ErrorLogController.addErrorLogs('', 'Creating ReepayCustomerInvoice', ex.getMessage(), 'Error', 'PS_PaymentService.createReepayCustomerInvoice', '', String.valueOf(ex.getLineNumber()));
        }
        return responseWrapperIns;
    }

    /*
    * @Description  method to genereate the payment link.
    * @Param        invoicePayment
    * @Return       PS_PaymentUtility.PaymentStatusWrapper
    */
    public static PS_PaymentUtility.PaymentLinkWrapper generatePaymentLink(Payments__c payment, String sessionType, PS_PaymentUtility.PS_PlanInfokWrapper getPlanInfo, Boolean isRecurringSettle) {
        PS_PaymentUtility.PaymentLinkWrapper linkStatusInstance = new PS_PaymentUtility.PaymentLinkWrapper();


        try {
            // getting the metadata record according to the currency.
            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(payment.CurrencyISOCode);
            HttpRequest request = new HttpRequest();


            String endpointUrl = sessionType.equalsIgnoreCase('charge') ? chargeSessionURL : sessionType.equalsIgnoreCase('reoccuring') ? reoccuringSessionURL : sessionType.equalsIgnoreCase('subscription') ? subscriptionSessionURL : chargeSessionURL;

            String requestBody = PS_PaymentUtility.constructPaymentLinkBody(payment, true, getPlanInfo, isRecurringSettle);
            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
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

    /*
    * @Description  method create the subscription record.
    * @Param        invoicePayment,subscriptionLeadProducts
    * @Return       PS_PaymentUtility.PaymentStatusWrapper
    */
    public static PS_PaymentUtility.PS_SubscriptionWrapper createSubscriptionWithFullDiscount(Payments__c invoicePayment, List<SObject> subscriptionLeadProducts) {
        PS_PaymentUtility.PS_SubscriptionWrapper responseWrapperIns = new PS_PaymentUtility.PS_SubscriptionWrapper();
        List<Payments__c> getUpdatedPayment = new List<Payments__c>();
        try {

            // getting the metadata record according to the currency.
            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(invoicePayment.CurrencyISOCode);
            HttpRequest request = new HttpRequest();

            String endpointUrl = createSubscriptionURL;
            String requestBody = PS_PaymentUtility.constructSubscriptionRequestBodyWith0Amount(invoicePayment, subscriptionLeadProducts);


            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
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
    * @Description  method to create the invoice record.
    * @Param        recordId
    * @Return       String
    */
    public static PS_PaymentUtility.PaymentStatusWrapper getPaymentRecords(Id recordId) {
        PS_PaymentUtility.PaymentStatusWrapper paymentStatusWrapperInstance = new PS_PaymentUtility.PaymentStatusWrapper();
        try {
            String sObjectType = PS_PaymentUtility.getSobjectTypeFromRecordId_Apex(recordId);
            List<Payments__c> paymentList = new List<Payments__c>();
            Debug_log_Configuration__mdt loggingConfigurations = Debug_log_Configuration__mdt.getInstance('Turn_Debug_On');


            // Changes for DFJ-273
            // Start
            String paymentCondition = sObjectType.equalsIgnoreCase('Lead') ?
                    ('Lead__c = \'' + recordId + '\' AND Status__c Not In (\'Cancelled\',\'Refunded\')') :
                    sObjectType.equalsIgnoreCase('Order') ?
                            ('Order__c = \'' + recordId + '\' AND Status__c Not In (\'Cancelled\',\'Refunded\')') :
                            sObjectType.equalsIgnoreCase('Opportunity') ?
                                    ('Opportunity__c = \'' + recordId + '\' AND Status__c Not In (\'Cancelled\',\'Refunded\')') :
                                    '';

            List<String> paymentFieldList = new List<String>{
                    'Id', 'Name', 'Payment_link__c', 'Subscription_status__c', 'Subscription_link__c', 'Status__c', 'Type__c', 'CurrencyIsoCode', 'Lead__c', 'Order__c', 'Amount__c', 'Invoice_created__c', 'BillingStreet__c', 'BillingState__c', 'Billing_PostalCode__c', 'BillingCity__c', 'BillingCountry__c', 'Billing_name__c', 'Fixed_discount_Type__c',
                    'Billing_email__c', 'Opportunity__c'
            };

            // End

            paymentList = PS_PaymentUtility.fetchRecordsDynamically(paymentCondition, paymentFieldList, 'Payments__c');

            //DIN-330 Changes Start 
            Boolean deleteAndCloneLeadOrderProduct = deleteAndCloneSubscriptionLeadProduct(recordId);
            //DIN-330 Changes End
            paymentStatusWrapperInstance.paymentList = paymentList;
            paymentStatusWrapperInstance.logEnabledUserIds = loggingConfigurations.User_Id_s__c;
            paymentStatusWrapperInstance.successMessage = paymentList.isEmpty() ? 'No payment found' : 'Found the payments';

        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Get Payment Records', ex.getMessage(), 'Error', 'PS_PaymentService.getPaymentRecords', '', String.valueOf(ex.getLineNumber()));
            paymentStatusWrapperInstance.errorMessage = ex.getMessage();
        }
        return paymentStatusWrapperInstance;
    }

    // DIN-344 changes
    /*
    * @Description  method to cancel the invoice and subscription
    * @Param        recordId, paymentRecordId
    * @Return       String
    */
    @AuraEnabled
    public static String cancelPayment(String recordId, String paymentRecordId) {
        String messageToReturn = '';


        try {

            // Find subscription lead product
            List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();
            List<OrderItem> orderItemsForOrder = new List<OrderItem>();
            List<Payments__c> paymentToCancel = new List<Payments__c>();
            List<LeadProducts__c> leadProductToCreate = new List<LeadProducts__c>();
            List<LeadProducts__c> leadProductToDelete = new List<LeadProducts__c>();
            List<OrderItem> orderItemToCreate = new List<OrderItem>();
            List<OrderItem> orderItemctToDelete = new List<OrderItem>();
            String subscriptionToCancel = '';

            // Changes for DFJ-273
            // Start

            List<OpportunityLineItem> oppProds = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oppProdsToCreate = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oppProdsToDelete = new List<OpportunityLineItem>();

            paymentToCancel = [SELECT Id, CurrencyIsoCode, Status__c, Cancellation_date__c, Amount__c, Lead__c, Order__c, Opportunity__c FROM Payments__c WHERE Id = :paymentRecordId LIMIT 1];
            // End

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
            // Changes for DFJ-273
            // Added condition for Opportunity__c in the 'same manner' as was done for LeadProducts__c
            // Start
            else if(String.isNotBlank(paymentToCancel[0].Opportunity__c)){
                oppProds = [
                        SELECT Id, Name, OpportunityId, PricebookEntryId, Quantity, TotalPrice, Subtotal, Discount, Is_subscription__c, Plan_handle__c, ListPrice, Pricebook_Id__c,
                                CurrencyIsoCode, PricebookEntry_Id__c, Product2Id,
                                Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c FROM OpportunityLineItem WHERE OpportunityId = :recordId LIMIT 10000
                ];

                for (OpportunityLineItem oppProd : oppProds){
                    if (oppProd.Is_subscription__c) {
                        subscriptionToCancel = oppProd.Id;
                        OpportunityLineItem newOppProd = new OpportunityLineItem();
                        newOppProd = oppProd.clone(false, false, true, false);

                        oppProdsToCreate.add(newOppProd);
                        oppProdsToDelete.add(oppProd);
                    }
                }
            }
                // End
            else {
                orderItemsForOrder = [SELECT Id, Product2Id, IsDeleted, OrderId, PricebookEntryId, OriginalOrderItemId, QuoteLineItemId, AvailableQuantity, Quantity, CurrencyIsoCode, UnitPrice, ListPrice, TotalPrice, ServiceDate, EndDate, Description, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, OrderItemNumber, Discount__c, Effective_price__c, Old_Order__c, Partner_provision_value__c, Partner_sales_value__c, Provision_base__c, DiscountGiven__c, Effective_Provision_Base__c, DiscountGivenProductLine__c, UnitPriceCon__c, EffectivePriceDKR__c, Effective_Partner_Provision_Value__c, Effective_Partner_Sales_Value__c, Effective_Provision_Base_Product_Line__c, ProvisionCheck__c, PriceBookCheck__c, Product_Name__c, TaxMoms__c, Plan_handle__c, Is_subscription__c FROM OrderItem WHERE orderId = :recordId LIMIT 10000];
                for (OrderItem itemLoop : orderItemsForOrder) {
                    if (itemLoop.Is_subscription__c) {
                        subscriptionToCancel = itemLoop.Id;
                        OrderItem newProduct = new OrderItem();
                        newProduct = itemLoop.clone(false, true, true, false);
                        // newProduct.OrderId = itemLoop.OrderId;
                        orderItemToCreate.add(newProduct);
                        orderItemctToDelete.add(itemLoop);
                    }
                }
            }


            if (String.isNotBlank(subscriptionToCancel)) {
                cancelSubscriptionFromId(subscriptionToCancel, paymentToCancel[0].CurrencyIsoCode);
            }

            messageToReturn = paymentToCancel[0].Amount__c > 0 ? cancelInvoiceFromId(paymentRecordId, paymentToCancel[0].CurrencyIsoCode) : 'Success : 0 amount invoice not in reepay.';
            if (messageToReturn.contains('Success')) {
                paymentToCancel[0].Status__c = 'Cancelled';
                paymentToCancel[0].Cancellation_date__c = Datetime.now();
            }
            if (!leadProductToCreate.isEmpty() && !leadProductToDelete.isEmpty()) {
                delete leadProductToDelete;
                insert leadProductToCreate;
            }
            // Changes for DFJ-273
                // Added condition for oppProdsToCreate and oppProdsToDelete in the 'same manner' as was done above
            // Start
                else if (!oppProdsToCreate.isEmpty() && !oppProdsToDelete.isEmpty()) {
                    delete oppProdsToDelete;
                    insert oppProdsToCreate;
                }
                // End
            else if (!orderItemToCreate.isEmpty() && !orderItemctToDelete.isEmpty()) {
                delete orderItemctToDelete;
                insert orderItemToCreate;
            }
            update paymentToCancel;
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Cancel payment.', ex.getMessage(), 'Error', 'PS_PaymentController.cancelPayment', '', String.valueOf(ex.getLineNumber()));
            messageToReturn = 'Something went wrong.';
        }
        return messageToReturn;
    }

    public static Boolean cancelSubscriptionFromId(String subscriptionToCancel, String CurrencyInSubscription) {
        try {
            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(CurrencyInSubscription);
            HttpRequest request = new HttpRequest();

            String endpointUrl = cancelSubscriptionURL + subscriptionToCancel + '/cancel';//cancelSubscriptionURL.replaceAll('{handle}', subscriptionToCancel);
            PS_PaymentUtility.SubscriptionCancleWrapper subsCancelInstance = new PS_PaymentUtility.SubscriptionCancleWrapper();
            subsCancelInstance.expire_at = System.today().year() + '-' + System.today().month() + '-' + System.today().day();

            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200 && !String.isBlank(response.getBody())) {
                return true;
            }

        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Cancelling the subscription.', ex.getMessage(), 'Error', 'PS_PaymentService.cancelSubscriptionFromId', '', String.valueOf(ex.getLineNumber()));
        }
        return false;
    }

    public static String cancelInvoiceFromId(String invoiceToCancel, String CurrencyInSubscription) {
        try {
            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(CurrencyInSubscription);
            HttpRequest request = new HttpRequest();

            String endpointUrl = settleInvoiceURL + invoiceToCancel + '/cancel';
            PS_PaymentUtility.SubscriptionCancleWrapper subsCancelInstance = new PS_PaymentUtility.SubscriptionCancleWrapper();
            subsCancelInstance.expire_at = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
            String requestBody = JSON.serialize(subsCancelInstance);

            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);
            request.setBody(requestBody);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() != 200) {
                PS_PaymentUtility.CustomerResponseWrapper customerResponse = (PS_PaymentUtility.CustomerResponseWrapper) JSON.deserialize(response.getBody(), PS_PaymentUtility.CustomerResponseWrapper.class);

                return customerResponse.error;
            }
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Cancelling the Invoice.', ex.getMessage(), 'Error', 'PS_PaymentService.cancelInvoiceFromId', '', String.valueOf(ex.getLineNumber()));
            return 'Something went wrong.';
        }
        return 'Successfully cancelled';
    }
    // DIN-344 changes End

    //DIN-330 Changes Start
    /*
    * @Description  delete and clone subscription Lead Product in case of Refund.
    * @Param        paymentRecordId
    * @Return       boolean
    */
    public static boolean deleteAndCloneSubscriptionLeadProduct(String recordId) {
        try {
            List<Payments__c> checkStatusOfPaymentRecord = new List<Payments__c>();
            List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();
            List<OrderItem> orderItemsForOrder = new List<OrderItem>();
            List<LeadProducts__c> leadProductToCreate = new List<LeadProducts__c>();
            List<LeadProducts__c> leadProductToDelete = new List<LeadProducts__c>();
            List<OrderItem> orderItemToCreate = new List<OrderItem>();
            List<OrderItem> orderItemctToDelete = new List<OrderItem>();
            //Changes Start TCS-35
            checkStatusOfPaymentRecord = [SELECT Id, Lead__c, Order__c, Status__c, Name, CreatedDate FROM Payments__c WHERE (Order__c = :recordId OR Lead__c = :recordId) ORDER BY CreatedDate DESC LIMIT 1];
            if (!checkStatusOfPaymentRecord.isEmpty() && checkStatusOfPaymentRecord[0].Status__c == 'Refunded') {
                //End
                leadProducts = [SELECT Id, Sub_Total__c, Discount__c, Is_subscription__c, Plan_handle__c, Item_Price__c, Lead__c, Name, Pricebook_Id__c, CurrencyIsoCode, PricebookEntry_Id__c, Product_Id__c, Product_Name__c, Quantity__c, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c FROM LeadProducts__c WHERE Lead__c = :recordId LIMIT 10000];
                if (!leadProducts.isEmpty()) {
                    for (LeadProducts__c leadProduct : leadProducts) {
                        if (leadProduct.Is_subscription__c) {
                            //subscriptionToCancel = leadProduct.Id;
                            LeadProducts__c newLeadProduct = new LeadProducts__c();
                            newLeadProduct = leadProduct.clone(false, false, true, false);
                            leadProductToCreate.add(newLeadProduct);
                            leadProductToDelete.add(leadProduct);
                        }
                    }
                } else {
                    orderItemsForOrder = [SELECT Id, Product2Id, IsDeleted, OrderId, PricebookEntryId, OriginalOrderItemId, QuoteLineItemId, AvailableQuantity, Quantity, CurrencyIsoCode, UnitPrice, ListPrice, TotalPrice, ServiceDate, EndDate, Description, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, OrderItemNumber, Discount__c, Effective_price__c, Old_Order__c, Partner_provision_value__c, Partner_sales_value__c, Provision_base__c, DiscountGiven__c, Effective_Provision_Base__c, DiscountGivenProductLine__c, UnitPriceCon__c, EffectivePriceDKR__c, Effective_Partner_Provision_Value__c, Effective_Partner_Sales_Value__c, Effective_Provision_Base_Product_Line__c, ProvisionCheck__c, PriceBookCheck__c, Product_Name__c, TaxMoms__c, Plan_handle__c, Is_subscription__c FROM OrderItem WHERE orderId = :recordId LIMIT 10000];
                    for (OrderItem itemLoop : orderItemsForOrder) {
                        if (itemLoop.Is_subscription__c) {
                            //subscriptionToCancel = itemLoop.Id;
                            OrderItem newProduct = new OrderItem();
                            newProduct = itemLoop.clone(false, true, true, false);
                            // newProduct.OrderId = itemLoop.OrderId;
                            orderItemToCreate.add(newProduct);
                            orderItemctToDelete.add(itemLoop);
                        }
                    }
                }
                if (!leadProductToCreate.isEmpty() && !leadProductToDelete.isEmpty()) {
                    delete leadProductToDelete;
                    insert leadProductToCreate;
                } else if (!orderItemToCreate.isEmpty() && !orderItemctToDelete.isEmpty()) {
                    delete orderItemctToDelete;
                    insert orderItemToCreate;
                }
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Delete And Clone Subscription Lead Product', e.getMessage(), 'Error', 'PS_PaymentService.deleteAndCloneSubscriptionLeadProduct', '', String.valueOf(e.getLineNumber()));
            return null;
        }

    }
    //DIN-330 Changes End
    //DIN-385  Changes Start

    /*
  * @Description  get and update the Address Info From Journal to Lead
  * @Param        RecordId
  * @Return       PS_AddressInfoWraaper
  */
    //Changes Start DFJ-27
    public static PS_PaymentUtility.PS_AddressInfoWrapper getAddressInfoFromLeadOROrder(String recordId) {
        try {
            PS_PaymentUtility.PS_AddressInfoWrapper addressInfoWrapper = new PS_PaymentUtility.PS_AddressInfoWrapper();
            List<Record_form_configuration__mdt> recordFormConfigurationInstance = new List<Record_form_configuration__mdt>();
            List<Journal__c> journalRecordList = new List<Journal__c>();
            List<Lead> getAddresInfoFromLead = new List<Lead>();
            List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();

            getAddresInfoFromLead = [
                    SELECT
                            Name,
                            FirstName,
                            LastName,
                            Phone,
                            Email,
                            Market_Unit__c,
                            Street,
                            City,
                            Country,
                            Fixed_discount_Type__c,
                            Phone_Formatted__c,
                            PostalCode
                    FROM
                            Lead
                    WHERE
                            Id = :recordId
                    LIMIT 1
            ];

            journalRecordList = [
                    SELECT Id,
                            Lead__c,
                            External_record_uuid__c,
                            Type__c
                    FROM
                            Journal__c
                    WHERE
                            Lead__c = :recordId
                    LIMIT 1
            ];
            if (!getAddresInfoFromLead.isEmpty() && !journalRecordList.isEmpty()) {

                recordFormConfigurationInstance = [
                        SELECT Id,
                                MasterLabel,
                                Market_unit_name__c,
                                Record_modal_id__c,
                                Journal_type__c,
                                Docfab_Journal_Object__c,
                                Address_Configuration_Fields__c
                        FROM
                                Record_form_configuration__mdt
                        WHERE
                                Market_unit_name__c = :getAddresInfoFromLead[0].Market_Unit__c
                                AND
                                Journal_type__c = :journalRecordList[0].Type__c
                        LIMIT 1
                ];

                if (!recordFormConfigurationInstance.isEmpty() && String.isNotBlank(recordFormConfigurationInstance[0].Docfab_Journal_Object__c) && String.isNotBlank(recordFormConfigurationInstance[0].Address_Configuration_Fields__c) && String.isNotBlank(journalRecordList[0].External_record_uuid__c)) {
                    Map<String, String> mapOfAddressFieldsConfig = (Map<String, String>) JSON.deserialize(recordFormConfigurationInstance[0].Address_Configuration_Fields__c, Map<String, String>.class);

                    String addressFields = '';
                    for (String addressField : mapOfAddressFieldsConfig.keySet()) {
                        addressFields = addressFields + mapOfAddressFieldsConfig.get(addressField) + ',';
                    }

                    addressFields = addressFields.removeEnd(',');
                    String query = 'SELECT uuid__c, Id, version__c,Journal__c' + (String.isNotBlank(addressFields) ? ',' + addressFields : '') + ' FROM ' + recordFormConfigurationInstance[0].Docfab_Journal_Object__c + ' WHERE Id =\'' + journalRecordList[0].Id + '\'' + ' OR uuid__c =\'' + journalRecordList[0].External_record_uuid__c + '\' LIMIT 1';

                    List<SObject> journalRecord = Database.query(query);
                    if (!journalRecord.isEmpty()) {
                        SObject journalRecordToUpdate = journalRecord[0]; // Getting the record of Journal DK OR SE
                        if (journalRecordToUpdate != null) {
                            getAddresInfoFromLead[0].FirstName = String.isBlank(getAddresInfoFromLead[0].FirstName) ? (String) journalRecordToUpdate.get(mapOfAddressFieldsConfig.get('FirstName')) : getAddresInfoFromLead[0].FirstName;
                            getAddresInfoFromLead[0].LastName = getAddresInfoFromLead[0].Name.contains('Unknown') ? (String) journalRecordToUpdate.get(mapOfAddressFieldsConfig.get('LastName')) : getAddresInfoFromLead[0].LastName;
                            getAddresInfoFromLead[0].Street = String.isBlank(getAddresInfoFromLead[0].Street) ? (String) journalRecordToUpdate.get(mapOfAddressFieldsConfig.get('Street')) : getAddresInfoFromLead[0].Street;
                            getAddresInfoFromLead[0].City = String.isBlank(getAddresInfoFromLead[0].City) ? (String) journalRecordToUpdate.get(mapOfAddressFieldsConfig.get('City')) : getAddresInfoFromLead[0].City;
                            getAddresInfoFromLead[0].PostalCode = String.isBlank(getAddresInfoFromLead[0].PostalCode) ? (String) journalRecordToUpdate.get(mapOfAddressFieldsConfig.get('PostalCode')) : getAddresInfoFromLead[0].PostalCode;
                            getAddresInfoFromLead[0].Email = String.isBlank(getAddresInfoFromLead[0].Email) ? (String) journalRecordToUpdate.get(mapOfAddressFieldsConfig.get('Email')) : getAddresInfoFromLead[0].Email;

                            String fieldType = getFieldDescription(recordFormConfigurationInstance[0].Docfab_Journal_Object__c, String.valueof(mapOfAddressFieldsConfig.get('Phone')));
                            getAddresInfoFromLead[0].Phone = String.isBlank(getAddresInfoFromLead[0].Phone) ? (fieldType == 'STRING' ? (String) journalRecordToUpdate.get(mapOfAddressFieldsConfig.get('Phone')) : String.valueof((Decimal) journalRecordToUpdate.get(mapOfAddressFieldsConfig.get('Phone')))) : getAddresInfoFromLead[0].Phone;
                            upsert getAddresInfoFromLead;
                        }
                    }
                }
            }
            addressInfoWrapper.leadAddressInfo = fetchUpdatedLead(recordId);
            leadProducts = [SELECT Id, Sub_Total__c, Discount__c, Is_subscription__c, Plan_handle__c, Item_Price__c, Lead__c, Name, Pricebook_Id__c, CurrencyIsoCode, PricebookEntry_Id__c, Product_Id__c, Product_Name__c, Quantity__c, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c FROM LeadProducts__c WHERE Lead__c = :recordId LIMIT 10000];
            addressInfoWrapper.leadProductsList = leadProducts;
            addressInfoWrapper.DefaultCurrencyIsoCode = UserInfo.getDefaultCurrency();
            return addressInfoWrapper;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', ' Getting Address Info From Lead OR Order ', e.getMessage(), 'Error', 'PS_PaymentService.getAddressInfoFromLeadOROrder', '', String.valueOf(e.getLineNumber()));

            return null;
        }

    }

    //DFJ-80 Starts
    public static PS_PaymentUtility.PS_AddressInfoWrapper getAddressInfoFromAccount_Apex(String recordId, String selectedJournal) {
        try {
            PS_PaymentUtility.PS_AddressInfoWrapper addressInfoWrapper = new PS_PaymentUtility.PS_AddressInfoWrapper();
            List<Journal_Address_Configration__mdt> recordFormConfigurationInstance = new List<Journal_Address_Configration__mdt>();
            List<Account> getdetailsFromAccount = new List<Account>();
            List<Journal__c> getAddresInfoFromJournal = new List<Journal__c>();

            getdetailsFromAccount = [
                    SELECT
                            Name,
                            PersonEmail,
                            Phone,
                            Market_Unit__c
                    FROM
                            Account
                    WHERE
                            Id = :recordId
                    LIMIT 1
            ];

            getAddresInfoFromJournal = [
                    SELECT Id,
                            Account__r.Market_Unit__c,
                            External_record_uuid__c,
                            DocFab_Record_Model_ID__c,
                            Type__c
                    FROM
                            Journal__c
                    WHERE
                            Id = :selectedJournal
                            AND Account__c = :recordId
                    LIMIT 1
            ];


            if (!getAddresInfoFromJournal.isEmpty()) {


                recordFormConfigurationInstance = [
                        SELECT Id,

                                Market_unit_name__c,
                                Journal_type__c,
                                Journal_Object__c,
                                Address_Configuration_Fields__c
                        FROM
                                Journal_Address_Configration__mdt
                        WHERE
                                Market_unit_name__c = :getdetailsFromAccount[0].Market_Unit__c
                                AND
                                Journal_type__c = :getAddresInfoFromJournal[0].Type__c
                                AND
                                Default_Record_model_id__c = :getAddresInfoFromJournal[0].DocFab_Record_Model_ID__c
                        LIMIT 1
                ];

                if (!recordFormConfigurationInstance.isEmpty() && String.isNotBlank(recordFormConfigurationInstance[0].Journal_Object__c) && String.isNotBlank(recordFormConfigurationInstance[0].Address_Configuration_Fields__c)) {
                    Map<String, String> mapOfAddressFieldsConfig = (Map<String, String>) JSON.deserialize(recordFormConfigurationInstance[0].Address_Configuration_Fields__c, Map<String, String>.class);

                    String addressFields = '';
                    for (String addressField : mapOfAddressFieldsConfig.keySet()) {
                        addressFields = addressFields + mapOfAddressFieldsConfig.get(addressField) + ',';
                    }

                    addressFields = addressFields.removeEnd(',');
                    String fromObject = recordFormConfigurationInstance[0].Journal_Object__c;
                    String addressObjectCond = 'Journal__c';
                    if (fromObject == 'df_160_person__c') {
                        addressObjectCond = 'journal_dk_new__r.Journal__c';
                    }
                    String query = 'SELECT Id ' + (String.isNotBlank(addressFields) ? ',' + addressFields : '') + ' FROM ' + recordFormConfigurationInstance[0].Journal_Object__c + ' WHERE ' + addressObjectCond + ' = \'' + getAddresInfoFromJournal[0].Id + '\' LIMIT 1';
                    List<SObject> journalRecord = Database.query(query);

                    if (!journalRecord.isEmpty()) {
                        addressInfoWrapper.addressInfo = journalRecord[0];
                        addressInfoWrapper.sObjectName = recordFormConfigurationInstance[0].Journal_Object__c;
                    }

                }
            }
            addressInfoWrapper.accountInfo = getdetailsFromAccount[0];
            addressInfoWrapper.DefaultCurrencyIsoCode = UserInfo.getDefaultCurrency();
            return addressInfoWrapper;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', ' Get Address Info From Account ', e.getMessage(), 'Error', 'PS_PaymentService.getAddressInfoFromAccount_Apex', '', String.valueOf(e.getLineNumber()));

            return null;
        }

    }
    //End

    /*
    * @Description  method to get Field DataType
    * @Param       ObjectName, FieldAPiNam
    * @Return     String of Field data type
    */
    public static String getFieldDescription(String objectName, String fieldapiname) {

        Map<String, Schema.SObjectField> ObjectSchemaField = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldDescription = ObjectSchemaField.get(fieldapiname).getDescribe();
        return String.valueOf(fieldDescription.type);

    }

    public static Lead fetchUpdatedLead(String recordId) {
        Lead leadRecord = new Lead();
        leadRecord = [
                SELECT Name, FirstName, LastName, Phone, Email, Market_Unit__c, Street, City, Country, Fixed_discount_Type__c, Phone_Formatted__c,
                        PostalCode
                FROM
                        Lead
                WHERE
                        Id = :recordId
                LIMIT 1
        ];
        return leadRecord;

    }
    //End
    //Changes start TCS-43
    /*
    * @Description  method to get Plan Info.
    * @Param        SubscriptionLeadProducts
    * @Return       PS_PaymentUtility.PaymentPlanWrapper
    */
    public static PS_PaymentUtility.PS_PlanInfokWrapper getCurrentPlanInformation(Payments__c payment, List<SObject> subscriptionProducts) {
        PS_PaymentUtility.PS_PlanInfokWrapper planInfoInstance = new PS_PaymentUtility.PS_PlanInfokWrapper();
        try {

            // For now getting the metadata record according to the currency.
            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(payment.CurrencyISOCode);
            HttpRequest request = new HttpRequest();

            String endpointUrl = 'https://api.reepay.com/v1/plan/' + subscriptionProducts[0].get('Plan_handle__c') + '/current' ;
            request.setEndpoint(endpointUrl);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
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
    //End

    //    DFJ-318 Changes Start
    @AuraEnabled(cacheable=true)
    public static PS_PaymentUtility.PaymentInfo getPaymentInfo(String myRecordId, String myObjectApiName) {
        
        try {
             if (String.isBlank(myRecordId) || String.isBlank(myObjectApiName)) {
                return null;
            }
            if (myObjectApiName.equals('Payments__c')) {
                List<Payment_order_line__c> paymentOrderLines = [
                        SELECT Id, Name, Quantity__c, Amount__c,
                                Payments__r.Payment_type__c,
                                Payments__r.CurrencyIsoCode,
                                Payments__r.Amount__c,
                                Payments__r.Refunded_Amount__c, Payments__r.Invoice_unique_handle__c

                        FROM Payment_order_line__c
                        WHERE Payments__c = :myRecordId
                ];
                List<Payments__c> paymentList = [SELECT Id,Type__c,Subscription_status__c,Status__c,Amount__c,Refunded_Amount__c,CurrencyIsoCode,
                                                    Invoice_unique_handle__c,Payment_type__c FROM Payments__c WHERE Id = :myRecordId];//DFJ-318-V2

                if(!paymentList.isEmpty()){
                    PS_PaymentUtility.PaymentInfo paymentInfoObject = new PS_PaymentUtility.PaymentInfo();
                    paymentInfoObject.currencyIsoCode = paymentList[0].CurrencyIsoCode;
                    paymentInfoObject.invoiceUniqueHandle = paymentList[0].Invoice_unique_handle__c;
                    paymentInfoObject.paymentType = paymentList[0].Payment_type__c;
                    paymentInfoObject.refundedAmount = paymentList[0].Refunded_Amount__c;
                    if(!paymentOrderLines.isEmpty()){
                        paymentInfoObject.paymentOrderLines = paymentOrderLines;
                    }
                    paymentInfoObject.totalPaymentAmount = paymentList[0].Amount__c;
                    paymentInfoObject.subscriptionStatus = paymentList[0].Subscription_status__c;
                    paymentInfoObject.type = paymentList[0].Type__c;
                    paymentInfoObject.status = paymentList[0].Status__c;
                    return paymentInfoObject;
                }
               

                return null;
            }

            return null;
        } catch (Exception e) {
             DFJ_ErrorLogController.addErrorLogs('', 'Error occurred while getting payment info.', e.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.getPaymentInfo', '', String.valueOf(e.getLineNumber()));
             return null;
        }
    }

    @AuraEnabled
    public static String refundHandler(String currencyIsoCode, String calloutBody) {
        try {
            if (String.isBlank(calloutBody) || String.isBlank(currencyIsoCode)) {
                return 'Either calloutBody or currencyIsoCode is blank.';
            }

            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(currencyIsoCode);
            if (Test.isRunningTest()) {
                reepayConfigurationSetting = Reepay_configuration__mdt.getInstance('Test');
            }

            HttpRequest httpRequestObj = new HttpRequest();

            httpRequestObj.setEndpoint(refundApiEndpoint);
            httpRequestObj.setMethod('POST');
            httpRequestObj.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
            httpRequestObj.setHeader('Accept', 'application/json');
            httpRequestObj.setHeader('Content-Type', 'application/json');
            httpRequestObj.setBody(calloutBody);

            HttpResponse response = new Http().send(httpRequestObj);

            if (response.getStatusCode() == 200) {
                return String.valueOf(response.getStatusCode());
            } else {
                DFJ_ErrorLogController.addErrorLogs('', 'Response status code not 200.', response.getBody(), 'Error', 'PS_InvoiceWebhookHelper.refundHandler', '', null);
                return String.valueOf(response.getStatusCode());
            }
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Error while creating refund', e.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.refundHandler', '', String.valueOf(e.getLineNumber()));
            return 'An error occurred';
        }


    }

//    DFJ-318 changes end

    // DFJ-329 changes start

    @AuraEnabled
    public static String handleExpireOfSubscription(Id recordId, String objectApiName){
        try{
            if (String.isBlank(recordId) || String.isBlank(objectApiName)) {
                return 'Either recordId or objectApiName is blank.';
            }

            if (objectApiName.equals('Subscriptions__c')) {
                //get currencyIsoCode of payment

                Subscriptions__c subscriptionRecord = [
                        SELECT Id,CurrencyIsoCode,Subscription_handle__c FROM Subscriptions__c
                        WHERE Id =:recordId
                        LIMIT 1
                ]??null;

                String currencyIsoCode = subscriptionRecord?.CurrencyIsoCode;

                String subscriptionHandle = subscriptionRecord?.Subscription_handle__c;

                if (String.isBlank(currencyIsoCode)) {
                    return 'CurrencyIsoCode is blank on associate payment.';
                }
                else {
                    String msgFromCalloutMethod = makeCalloutToExpireSubscription( currencyIsoCode,subscriptionHandle);

                    return msgFromCalloutMethod;
                }
            }
            else {
                return 'Component is not placed on Subscriptions__c record page.';
            }

        }
        catch(Exception e){
            DFJ_ErrorLogController.addErrorLogs('', 'Error while handling expire of subscription', e.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.handleExpireOfSubscription', '', String.valueOf(e.getLineNumber()));
            return 'An Error occurred.';
        }
    }

    public static String makeCalloutToExpireSubscription( String currencyIsoCode, String subscriptionHandle){
        try{

            if ( String.isBlank(currencyIsoCode) || String.isBlank(subscriptionHandle) ) {
                return 'Either calloutBody or subscriptionHandle is blank.';
            }

            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(currencyIsoCode);
            if (Test.isRunningTest()) {
                reepayConfigurationSetting = Reepay_configuration__mdt.getInstance('Test');
            }

            HttpRequest httpRequestObj = new HttpRequest();

            String expireSubscriptionEndpointToSet = expireSubscriptionApiEndpoint.replace('{handle}',subscriptionHandle);

            httpRequestObj.setEndpoint(expireSubscriptionEndpointToSet);
            httpRequestObj.setMethod('POST');
            httpRequestObj.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
            httpRequestObj.setHeader('Accept', 'application/json');
            httpRequestObj.setHeader('Content-Type', 'application/json');

            HttpResponse response = new Http().send(httpRequestObj);

            if (response.getStatusCode() == 200) {
                return String.valueOf(response.getStatusCode());
            } else {
                DFJ_ErrorLogController.addErrorLogs('', 'Response status code not 200.', response.getBody(), 'Error', 'PS_InvoiceWebhookHelper.expireSubscription', '', null);
                return String.valueOf(response.getStatusCode());
            }
        }
        catch (Exception e){
            DFJ_ErrorLogController.addErrorLogs('', '', e.getMessage(), 'Error', 'PS_PaymentService.expireSubscription', '', String.valueOf(e.getLineNumber()));
            return 'Error occurred while doing callout for expireSubscription.';
        }
    }

    @AuraEnabled
    public static String handleCancellationOfSubscription(Id recordId, String objectApiName){
        try{
            if (String.isBlank(recordId) || String.isBlank(objectApiName)) {
                return 'Either recordId or objectApiName is blank.';
            }

            if (objectApiName.equals('Subscriptions__c')) {
                //get currencyIsoCode 

                Subscriptions__c subscriptionRecord = [
                        SELECT Id,CurrencyIsoCode,Subscription_handle__c FROM Subscriptions__c
                        WHERE Id =:recordId
                        LIMIT 1
                ]??null;

                String currencyIsoCode = subscriptionRecord?.CurrencyIsoCode;

                String subscriptionHandle = subscriptionRecord?.Subscription_handle__c;

                if (String.isBlank(currencyIsoCode)) {
                    return 'CurrencyIsoCode is blank on associate payment.';
                }
                else {
                    String msgFromCalloutMethod = makeCalloutToCancelSubscription( currencyIsoCode,subscriptionHandle);

                    return msgFromCalloutMethod;
                }
            }
            else {
                return 'Component is not placed on Subscriptions__c record page.';
            }

        }
        catch(Exception e){
            DFJ_ErrorLogController.addErrorLogs('', '', e.getMessage(), 'Error', 'PS_PaymentService.handleCancellationOfSubscription', '', String.valueOf(e.getLineNumber()));
            return 'An Error occurred.';
        }
    }

    public static String makeCalloutToCancelSubscription( String currencyIsoCode, String subscriptionHandle){
        try{

            if ( String.isBlank(currencyIsoCode) || String.isBlank(subscriptionHandle) ) {
                return 'Either calloutBody or subscriptionHandle is blank.';
            }

            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(currencyIsoCode);
            if (Test.isRunningTest()) {
                reepayConfigurationSetting = Reepay_configuration__mdt.getInstance('Test');
            }

            HttpRequest httpRequestObj = new HttpRequest();

            String expireSubscriptionEndpointToSet = cancelSubscriptionApiEndpoint.replace('{handle}',subscriptionHandle);

            httpRequestObj.setEndpoint(expireSubscriptionEndpointToSet);
            httpRequestObj.setMethod('POST');
            httpRequestObj.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
            httpRequestObj.setHeader('Accept', 'application/json');
            httpRequestObj.setHeader('Content-Type', 'application/json');

            HttpResponse response = new Http().send(httpRequestObj);

            if (response.getStatusCode() == 200) {
                return String.valueOf(response.getStatusCode());
            } else {
                DFJ_ErrorLogController.addErrorLogs('', 'Response status code not 200.', response.getBody(), 'Error', 'PS_InvoiceWebhookHelper.makeCalloutToCancelSubscription', '', null);
                return String.valueOf(response.getStatusCode());
            }
        }
        catch (Exception e){
            DFJ_ErrorLogController.addErrorLogs('', '', e.getMessage(), 'Error', 'PS_PaymentService.makeCalloutToCancelSubscription', '', String.valueOf(e.getLineNumber()));
            return 'Error occurred while doing callout to cancel Subscription.';
        }
    }
    // DFJ-329 changes end

    //    DFJ-319 changes start

    @AuraEnabled
    public static String handleOfflineManualSettle( String invoiceUniqueHandle, String calloutBody) {

        try {
            if (String.isBlank(invoiceUniqueHandle) || String.isBlank(calloutBody)) {
                return 'Either invoiceUniqueHandle or calloutBody is blank.';
            }

            String currencyISOCode = ([SELECT Id, CurrencyIsoCode FROM Payments__c WHERE Id = :invoiceUniqueHandle]?.CurrencyIsoCode) ?? null;

            if (currencyISOCode != null) {
                Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(currencyISOCode);
                if (Test.isRunningTest()) {
                    reepayConfigurationSetting = Reepay_configuration__mdt.getInstance('Test');
                }

                HttpRequest request = new HttpRequest();

                String endpointUrl = offlineManualSettleEndpoint.replace('{id}', invoiceUniqueHandle);
                request.setEndpoint(endpointUrl);
                request.setMethod('POST');
                request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
                request.setHeader('Content-Type', 'application/json');
                request.setBody(calloutBody);
                request.setTimeout(120000);

                Http http = new Http();
                HttpResponse response = http.send(request);
                if (response.getStatusCode() == 200) {
                    return String.valueOf(response.getStatusCode());
                } else {
                    DFJ_ErrorLogController.addErrorLogs('', 'Response code not 200 in callout done in PS_InvoiceWebhookHelper.handleOfflineManualSettle.', '', 'Error', 'PS_InvoiceWebhookHelper.handleOfflineManualSettle', '', null);
                    return String.valueOf(response.getStatusCode());
                }
            }
            else {
                return 'CurrencyISOCode is null.';
            }
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Error while doing callout for offline manual settle.', e.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.handleOfflineManualSettle', '', String.valueOf(e.getLineNumber()));
            return 'Offline Manual Settle failed.';
        }
    }

    //    DFJ-319 changes end
    //DFJ-318-V2 Starts
    @AuraEnabled(cacheable=true)
    public static Payments__c getPlanInfo(Id recordId){
        try{
        List<Payments__c> subscriptionList = [SELECT Id,subscriptions__r.Plan_Name__c, subscriptions__r.Plan_Amount__c FROM Payments__c WHERE id = :recordId];
        return subscriptionList[0];
        }
         catch ( Exception e ){
            DFJ_ErrorLogController.addErrorLogs('', 'Error while getting subscription Plans.', e.getMessage(), 'Error', 'SubscriptionHandlerApex.getPlanInfo', '', String.valueOf(e.getLineNumber()));
            return null;
        }

    }
    //DFJ-318-V2 Ends
}