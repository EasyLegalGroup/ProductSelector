/*
   * @ Version : 1.0
   * @ Created Date : 2022-06-29
   * @Description : Handle the reepay operations.
*/
public with sharing class PS_PaymentUtility {

    public static String getSobjectTypeFromRecordId_Apex(Id recordId){
        Schema.sObjectType sObjType = recordId.getSObjectType();
        Schema.DescribeSObjectResult sObjDescribeResult = sObjType.getDescribe();        
        return sObjDescribeResult.getName();
    }

    /**
     * @Description  Method to perform the DML based on the http methods.
     * @Param        recordsToDML, Method
     * @Return       buildReturnResponse
    */
    public static List<SObject> dmlHelper(List<SObject> recordsToDML, String method){
        try {
            if (method.equals('DELETE')) {
                Database.delete(recordsToDML);
            }else{
                Database.upsert(recordsToDML);
            }
            return recordsToDML;
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Performing DML operations.',ex.getMessage(), '', 'PS_PaymentUtility.dmlHelper apex class.', '', String.valueOf(ex.getLineNumber()));
            return null;
        }
    }

    /**
     * @Description  Method to check the record is already present or not.
     * @Param        parentObjectAPIName, parentObjDetails
     * @Return       List<SObject>
    */
    public static List<SObject> fetchRecordsDynamically(String condition, List<String> fields, String objectName){
        String query = 'SELECT '+String.join(fields,',') + ' FROM '+ objectName + (!String.isBlank(condition) ? ' WHERE '+ condition : '') +' LIMIT 10000';
        return Database.query(query);
    }

    public static List<SObject> createPaymentOrderItemBySobject(String sObjectType , List<LeadProducts__c> leadProductsItems,List<OrderItem> orderItems, List<Payments__c> paymentInserted){
        List<Payment_order_line__c> paymentOrderItemlistToCreate = new List<Payment_order_line__c>();
        if (sObjectType.equalsIgnoreCase('Lead')) {
            for (LeadProducts__c leadProductIteration : leadProductsItems) {
                if (!leadProductIteration.Is_subscription__c) {
                    Payment_order_line__c paymentOrderItem = new Payment_order_line__c();
                    paymentOrderItem.Amount__c =  (leadProductIteration.Item_Price__c -  (leadProductIteration.Item_Price__c*  leadProductIteration.Discount__c/100));     //(1-leadProductIteration.Discount__c) * leadProductIteration.Item_Price__c; //leadProductIteration.Item_Price__c;
                    paymentOrderItem.Quantity__c = leadProductIteration.Quantity__c;
                    paymentOrderItem.Vat__c = 0;
                    paymentOrderItem.Name = leadProductIteration.Product_Name__c;
                    paymentOrderItem.Payments__c = paymentInserted[0].Id;
                    paymentOrderItem.CurrencyIsoCode = leadProductIteration.CurrencyIsoCode;
        
                    paymentOrderItemlistToCreate.add(paymentOrderItem);
                }
            }
        } else if (sObjectType.equalsIgnoreCase('Order')) {
            for (OrderItem orderItemIteration : orderItems) {
                Payment_order_line__c paymentOrderItem = new Payment_order_line__c(); //DIN-337
                paymentOrderItem.Amount__c = (orderItemIteration.UnitPrice -  (orderItemIteration.UnitPrice*  orderItemIteration.Discount__c/100));
                paymentOrderItem.Quantity__c = orderItemIteration.Quantity;
                paymentOrderItem.Vat__c = 0;
                paymentOrderItem.Name = orderItemIteration.Product_Name__c;
                paymentOrderItem.Payments__c = paymentInserted[0].Id;
    
                paymentOrderItemlistToCreate.add(paymentOrderItem);
            }
        }

        return paymentOrderItemlistToCreate;
    }

    // Changes for DFJ-273
    // Start
    public static List<SObject> createPaymentOrderItemFromOpportunity(List<OpportunityLineItem> oppProducts, List<Payments__c> paymentInserted){
        try{
            List<Payment_order_line__c> paymentOrderItemListToCreate = new List<Payment_order_line__c>();

            for(OpportunityLineItem oppProd : oppProducts){
                if(!oppProd.Is_subscription__c){
                    Payment_order_line__c paymentOrderItem = new Payment_order_line__c();

                 //   paymentOrderItem.Amount__c = oppProd.ListPrice;
                    paymentOrderItem.Amount__c = oppProd.unitPrice; //DFJ-350
                    paymentOrderItem.Quantity__c = oppProd.Quantity;
                    paymentOrderItem.Vat__c = 0;
                    paymentOrderItem.Name = oppProd.Product2.Name;//DFJ-350
                    paymentOrderItem.Payments__c = paymentInserted[0].Id;
                    paymentOrderItem.CurrencyIsoCode = oppProd.CurrencyIsoCode;
                    paymentOrderItemListToCreate.add(paymentOrderItem);
                }
            }

            return paymentOrderItemListToCreate;
        }
        catch (Exception e){

            DFJ_ErrorLogController.addErrorLogs('', ' Creating a list that contains payment order lines to be created. ', e.getMessage(), 'Error', 'PS_PaymentUtility.createPaymentOrderItemFromOpportunity', '', String.valueOf(e.getLineNumber()));
            return new List<Payment_order_line__c>{};
        }
    }
    // End

//Changes DFJ-80
    public static List<SObject> createPaymentOrderItemOnAccount(List<OrderItem> orderItems, List<Payments__c> paymentInserted){
        List<Payment_order_line__c> paymentOrderItemlistToCreate = new List<Payment_order_line__c>();
        
            for (OrderItem orderItemIteration : orderItems) {
                Payment_order_line__c paymentOrderItem = new Payment_order_line__c();
                //for OrderItems
                paymentOrderItem.Provision_base__c = orderItemIteration.Provision_base__c;
                paymentOrderItem.Discount__c = orderItemIteration.Discount__c;
                paymentOrderItem.UnitPrice__c = orderItemIteration.UnitPrice;
                paymentOrderItem.Product2Id__c = orderItemIteration.Product2Id;
                paymentOrderItem.PricebookEntryId__c = orderItemIteration.PricebookEntryId;
                paymentOrderItem.CurrencyIsoCode = orderItemIteration.CurrencyIsoCode;
                //End
                paymentOrderItem.Amount__c = orderItemIteration.Discount__c == null ? orderItemIteration.UnitPrice :( orderItemIteration.UnitPrice -  (orderItemIteration.UnitPrice*  orderItemIteration.Discount__c/100)); 
                paymentOrderItem.Quantity__c = orderItemIteration.Quantity;
                paymentOrderItem.Vat__c = 0;
                paymentOrderItem.Name = orderItemIteration.Product_Name__c;
                paymentOrderItem.Effective_price__c = orderItemIteration.Effective_price__c;
                paymentOrderItem.Is_subscription__c = orderItemIteration.Is_subscription__c;
                paymentOrderItem.Plan_handle__c = orderItemIteration.Plan_handle__c;
                paymentOrderItem.Payments__c = paymentInserted[0].Id;
    
                paymentOrderItemlistToCreate.add(paymentOrderItem);
            }
        return paymentOrderItemlistToCreate;
    }
    //End

    /**
     * @Description  Method to construct the request body.
     * @Param        
     * @Return       String
    */
    public static String buildCustomerRequestBodyFromLead(List<Lead> leadList){
        //String body = '';

        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        PS_PaymentUtility.CustomerWrapper customerWrapper = new PS_PaymentUtility.CustomerWrapper();
        customerWrapper.email = leadList[0].Email;
        //Changes start TCS-50
        customerWrapper.address = leadList[0].Street;
        //End
        customerWrapper.city = leadList[0].City;
        //Changes start TCS-50
        customerWrapper.country = (leadList[0].Market_Unit__c == 'DFJ_DK' || leadList[0].Market_Unit__c == 'Testamente_DK' ? 'DK' : 'SE');
        //End
        customerWrapper.phone = leadList[0].Phone;
        customerWrapper.handle = leadList[0].Email;
        customerWrapper.test = testConfigurations.Use_test_account__c;// For now true
        customerWrapper.postal_code = leadList[0].PostalCode;
        customerWrapper.first_name = leadList[0].FirstName;
        customerWrapper.last_name = leadList[0].LastName;
        customerWrapper.generate_handle = false;
        // customerWrapper
        return JSON.serialize(customerWrapper);
    }

    /**
     * @Description  Method to construct the request body to create subscription.
     * @Param        
     * @Return       String
    */
    public static String constructSubscriptionRequestBody(Payments__c invoicePayment, List<SObject> subscriptionLeadProducts, String recurringPaymentMethod){
        //String recurringPaymentMethod = '';
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        String requestBody = '';
        requestBody = '{"customer":"'+ invoicePayment.Billing_email__c +'","plan":"'+ subscriptionLeadProducts[0].get('Plan_handle__c') +'","test": '+testConfigurations.Use_test_account__c+',"grace_duration": 1800,"signup_method": "source","source":"'+recurringPaymentMethod+'","handle":"'+ subscriptionLeadProducts[0].get('Id')+'"}';// "trial_period": "P1D","no_trial": false,"no_setup_fee": true,"amount_incl_vat": true,
        System.debug('SubscriptionRequestBody-->'+JSON.serialize(requestBody));
        return requestBody;
    }

    //Chnages Start TCS-35
       /**
     * @Description  Method to construct the request body to create subscription.
     * @Param        
     * @Return       String
    */
    public static String constructSubscriptionRequestBodyWith0Amount(Payments__c invoicePayment, List<SObject> subscriptionLeadProducts){
        //String recurringPaymentMethod = '';
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        String requestBody = '';
        requestBody = '{"customer":"'+ invoicePayment.Billing_email__c +'","plan":"'+ subscriptionLeadProducts[0].get('Plan_handle__c') +'","test": '+testConfigurations.Use_test_account__c+',"grace_duration": 1800,"signup_method": "email","handle":"'+ subscriptionLeadProducts[0].Id +'"}';// "trial_period": "P1D","no_trial": false,"no_setup_fee": true,"amount_incl_vat": true,
        System.debug('SubscriptionRequestBodyWith0Amount-->'+JSON.serialize(requestBody));
        return requestBody;
    }
    //End
    /**
     * @Description  Method to construct the request body from order.
     * @Param        
     * @Return       String
    */ 
    public static String buildCustomerRequestBodyFromOrder(List<Order> OrderList){
        //String body = '';
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        PS_PaymentUtility.CustomerWrapper customerWrapper = new PS_PaymentUtility.CustomerWrapper();
        customerWrapper.email = OrderList[0].Account.PersonEmail;
        customerWrapper.city = OrderList[0].ShippingCity;
        customerWrapper.country = (OrderList[0].Account.Market_Unit__c == 'DFJ_DK' || OrderList[0].Account.Market_Unit__c == 'Testamente_DK' ? 'DK' : 'SE');
        customerWrapper.phone = OrderList[0].Account.Phone;
        customerWrapper.handle = OrderList[0].Account.PersonEmail;
        customerWrapper.test = testConfigurations.Use_test_account__c;// For now true
        customerWrapper.postal_code = OrderList[0].ShippingPostalCode;
        customerWrapper.first_name = OrderList[0].Account.Name;
        customerWrapper.last_name = OrderList[0].Account.Name;
        customerWrapper.generate_handle = false;// For now true
        // customerWrapper
        return JSON.serialize(customerWrapper);
    }
    //Changes DFJ-80 Starts
    public static String buildCustomerRequestBodyFromAccount(List<Account> accountList){
        //String body = '';
        ReepayTestingConfiguration__c testConfigurations = ReepayTestingConfiguration__c.getOrgDefaults();
        PS_PaymentUtility.CustomerWrapper customerWrapper = new PS_PaymentUtility.CustomerWrapper();
        customerWrapper.email = accountList[0].PersonEmail;
        customerWrapper.city = accountList[0].ShippingCity;
        customerWrapper.country = (accountList[0].Market_Unit__c == 'DFJ_DK' || accountList[0].Market_Unit__c == 'Testamente_DK' ? 'DK' : 'SE');
        customerWrapper.phone = accountList[0].Phone;
        customerWrapper.handle = accountList[0].PersonEmail;
        customerWrapper.test = testConfigurations.Use_test_account__c;// For now true
        customerWrapper.postal_code = accountList[0].ShippingPostalCode;
        customerWrapper.first_name = accountList[0].Name;
        customerWrapper.last_name = accountList[0].Name;
        customerWrapper.generate_handle = false;// For now true
        // customerWrapper
        return JSON.serialize(customerWrapper);
    }
    //End

    /**
     * @Description  Method to construct the invoice requestbody
     * @Param        payment, paymentOrderLines
     * @Return       String
    */
    public static String constructInvoiceRequestBody(Payments__c payment, List<Payment_order_line__c> paymentOrderLines , List<SObject> subscriptionProducts){

        InvoiceWrapper invoiceWrapperInstance = new InvoiceWrapper();


        List<PaymentOrderLineWrapper> paymentOrderItems = new List<PaymentOrderLineWrapper>();
        Integer count = 0;
        for (Payment_order_line__c polLoop : paymentOrderLines) {



            PaymentOrderLineWrapper singlePaymentOrderItem = new PaymentOrderLineWrapper();
            singlePaymentOrderItem.amount = polLoop.Amount__c * 100;
            singlePaymentOrderItem.quantity = polLoop.Quantity__c;
            singlePaymentOrderItem.ordertext = polLoop.Name;
            paymentOrderItems.add(singlePaymentOrderItem);
           
        }


        //TCS-16 changes
        //Start
        if (subscriptionProducts == null) {
            subscriptionProducts = new List<SObject>();
        }
        if(!subscriptionProducts.isEmpty()){


            for (SObject subscriptionProduct : subscriptionProducts){

                PaymentOrderLineWrapper singlePaymentOrderItem = new PaymentOrderLineWrapper();

                // Changes for DFJ-273
                // Start
                // Check whether subscription product belongs to OpportunityLineItem object or not
                Id recordIdOfsubscriptionProduct = (Id) subscriptionProduct.get('Id');

                if(recordIdOfsubscriptionProduct != null){
                    String sObjectTypeName = getSobjectTypeFromRecordId_Apex(recordIdOfsubscriptionProduct);

                    if (sObjectTypeName.equals('OpportunityLineItem')) {
                        singlePaymentOrderItem.amount = (Decimal) subscriptionProduct.get('TotalPrice') * 100;
                        singlePaymentOrderItem.quantity = (Decimal) subscriptionProduct.get('Quantity');
                        singlePaymentOrderItem.ordertext = (String) subscriptionProduct.get('Name');

                        paymentOrderItems.add(singlePaymentOrderItem);
                    }
                }

                else {

                    // End

                    if (String.isNotBlank(payment.Lead__c)) {
                        //  singlePaymentOrderItem.amount = 0;
                        //DFJ-191

                        singlePaymentOrderItem.amount = (Decimal) subscriptionProduct.get('Sub_Total__c') * 100;
                        //End
                        singlePaymentOrderItem.quantity = (Decimal) subscriptionProduct.get('Quantity__c');
                        singlePaymentOrderItem.ordertext = (String) subscriptionProduct.get('Product_Name__c');
                        paymentOrderItems.add(singlePaymentOrderItem);
                    }
                }
            }
        }

        if(payment.Fixed_discount_Type__c > 0){
            PaymentOrderLineWrapper singlePaymentItem = new PaymentOrderLineWrapper();
            singlePaymentItem.amount = payment.Fixed_discount_Type__c * 100 * (-1);
            singlePaymentItem.quantity = 1 ;
            singlePaymentItem.ordertext = 'Discount';
            paymentOrderItems.add(singlePaymentItem);
        }
        //End


        BillingInfo billInfo = new BillingInfo();
        //Chnages DIN-385 Start
        // Add Street Information in billing address
        billInfo.address = payment.BillingStreet__c;
        //End
        billInfo.city = payment.BillingCity__c;
        billInfo.country = payment.BillingCountry__c;
        billInfo.email = payment.Billing_email__c;
        //Chnages DIN-385 Start
        // Update the First && Last Name in billing address

        billInfo.first_name = ( String.isNotBlank(payment.Billing_name__c) && String.isNotBlank(payment.Billing_name__c.substringBefore(' ') ) )? payment.Billing_name__c.substringBefore(' ') : payment.Billing_name__c;
        billInfo.last_name = ( String.isNotBlank(payment.Billing_name__c) && String.isNotBlank(payment.Billing_name__c.substringBefore(' ') ) ) ? payment.Billing_name__c.substringAfter(' ') : payment.Billing_name__c;
        //end
        billInfo.postal_code = payment.Billing_PostalCode__c;
        billInfo.state_or_province = payment.BillingState__c;
        invoiceWrapperInstance.billing_address = billInfo;
        invoiceWrapperInstance.handle = payment.Id;
        invoiceWrapperInstance.order_lines = paymentOrderItems;
        System.debug('invoiceWrapperInstance-->'+JSON.serialize(invoiceWrapperInstance));
        return JSON.serialize(invoiceWrapperInstance);
    }

    //Changes Start TCS-43
    /**
     * @Description  Method to construct payment link request body.
     * @Param        invoicePayment
     * @Return       String
    */
    public static String constructPaymentLinkBody(Payments__c invoicePayment, Boolean instantSettle, PS_PaymentUtility.PS_PlanInfokWrapper getPlanInfo, Boolean isRecurringSettle){
        // String linkGenerationRequestBody = '';
        //linkGenerationRequestBody = '{"recurring":false,"settle":' + instantSettle + ',"invoice":"'+invoicePayment.Invoice_unique_handle__c+'"}';
        PaymentLinkWrapper pamentLinkWrapper = new PaymentLinkWrapper();
        pamentLinkWrapper.recurring = isRecurringSettle;
        pamentLinkWrapper.settle = instantSettle;
        pamentLinkWrapper.invoice = invoicePayment.Invoice_unique_handle__c;

    //   Changes for DFJ-354
       /* 
        sessionData sessionInfo = new sessionData();
        sessionInfo.mps_amount = getPlanInfo.amount;
        sessionInfo.mps_plan = getPlanInfo.name;
        sessionInfo.mps_description = getPlanInfo.description;
        sessionInfo.mps_frequency = 'yearly';*/
        
         sessionData sessionInfo = new sessionData();
        sessionInfo.vipps_recurring_amount = getPlanInfo.amount;
        sessionInfo.vipps_recurring_product_name = getPlanInfo.name;
        sessionInfo.vipps_recurring_product_description = getPlanInfo.description;
       // sessionInfo.vipps_recurring_interval_count = 'yearly';
        sessionInfo.vipps_recurring_interval_unit = 'year';
        //End
        
        pamentLinkWrapper.session_data = sessionInfo;

        //Chnages TCS-50 Start
        BillingInfo billInfo = new BillingInfo();
        // Add Street Information in billing address
        billInfo.address = invoicePayment.BillingStreet__c;
     
        billInfo.city = invoicePayment.BillingCity__c;
        billInfo.country = invoicePayment.BillingCountry__c;
        billInfo.email = invoicePayment.Billing_email__c;
        billInfo.first_name = String.isNotBlank(invoicePayment.Billing_name__c.substringBefore(' ')) ? invoicePayment.Billing_name__c.substringBefore(' ') : invoicePayment.Billing_name__c;
        billInfo.last_name = String.isNotBlank(invoicePayment.Billing_name__c.substringAfter(' ')) ? invoicePayment.Billing_name__c.substringAfter(' ') : invoicePayment.Billing_name__c;
        billInfo.postal_code = invoicePayment.Billing_PostalCode__c;
        billInfo.state_or_province = invoicePayment.BillingState__c;
        pamentLinkWrapper.billing_address = billInfo;
        //End
        System.debug('pamentLinkWrapper--->'+JSON.serialize(pamentLinkWrapper));
        return JSON.serialize(pamentLinkWrapper);
    }
    //End

     /**
     * @Description  Method to parse the invoice
     * @Param        reepayinvoiceWrapper
     * @Return       String
    */
    public static GetInvoiceWrapper parseReepayInvoice(String reepayinvoiceWrapper){
        GetInvoiceWrapper getInvoiceWrapperInstance = new GetInvoiceWrapper();
        try {            
            getInvoiceWrapperInstance = (GetInvoiceWrapper) JSON.deserialize(reepayinvoiceWrapper, GetInvoiceWrapper.class);
            return getInvoiceWrapperInstance;
        } catch (Exception ex) {
            getInvoiceWrapperInstance.errorMessage = ex.getMessage();
        }
        return getInvoiceWrapperInstance;
    }


    /*Wrapper classes START*/
    // DIN-344 changes
    // Start
    public class SubscriptionCancleWrapper{
        public String expire_at;
    }

    public class InvoiceCancleWrapper{
        public String expire_at;
    }
    // End

    public class PaymentWrapper{
        @AuraEnabled public Payments__c payment;
        @AuraEnabled public List<Payment_order_line__c> paymentOrderLines;

        // Changes for DFJ-273
        // Start
        @AuraEnabled public List<OpportunityLineItem> subscriptionOpportunityProducts;
        // End

        @AuraEnabled public List<LeadProducts__c> subscriptionLeadProducts;
        // DIN-349 changes
        @AuraEnabled public List<OrderItem> subscriptionOrderItemProducts;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String successMessage;
        
    }

    public class PaymentStatusWrapper{
        @AuraEnabled public List<Payments__c> paymentList;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String successMessage;
        @AuraEnabled public String logEnabledUserIds;
    }

    public class PaymentLinkWrapper{
        @AuraEnabled public String error;
        @AuraEnabled public String success;
        @AuraEnabled public String id;
        @AuraEnabled public String url;
        //Changes Start TCS-43
        public Boolean recurring;
        public Boolean settle;
        public String invoice;
        public sessionData session_data;
        //Changes Start TCS-50
        public BillingInfo billing_address;
        //End
    }

    public class CustomerWrapper{
        @AuraEnabled public String email;
        @AuraEnabled public String address;
        @AuraEnabled public String address2;
        @AuraEnabled public String city;
        @AuraEnabled public String country;
        @AuraEnabled public String phone;
        @AuraEnabled public String company;
        @AuraEnabled public String handle;
        @AuraEnabled public String vat;
        @AuraEnabled public Boolean test;
        @AuraEnabled public String postal_code;
        @AuraEnabled public String first_name;
        @AuraEnabled public String last_name;
        @AuraEnabled public Boolean generate_handle;
    }

    public class CustomerResponseWrapper{
        public String error;
        public String message;
        public Integer http_status;
        public String http_reason;
        //DFJ 80 Changes.
        //@AuraEnabled public Payments__c updatedPayment;
    }

    public class InvoiceWrapper{
        public String handle;
        public List<PaymentOrderLineWrapper> order_lines;
        public BillingInfo billing_address;
    }

    public class BillingInfo{
        //chnages DIN-385 start
        public String address;
        public String company;
        public String city;
        public String country;
        public String email;
        public String phone;
        public String first_name;
        public String last_name;
        public String postal_code;
        public String state_or_province;
    }

    public class PaymentOrderLineWrapper{
        @AuraEnabled public String ordertext;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal vat;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Boolean amount_incl_vat;
    }

    /* Wrapper classes */

        public class GetInvoiceWrapper{
        public String id;
        public String handle;
        public String customer;
        public String subscription;
        public String plan;
        public String state;
        public String type;
        public Double amount;
        // public Integer number;
        public Datetime due;
        public Datetime created;
        public Double discount_amount;
        public Double org_amount;
        public Double amount_vat;
        public Double amount_ex_vat;
        public Double settled_amount;
        public Double refunded_amount;
         //Chnages TCS-16
        public String recurring_payment_method;
        //End
        public List<Payment_order_line__c> order_lines;
        public List<PS_transactions> transactions;
        public String errorMessage;

        //    DFJ-318 changes start
        public List<CreditNoteWrapper> credit_notes;
        //    DFJ-318 changes end
    }
    
    // public PS_transactions[] transactions;
    public class PS_transactions {
        public String id;	//dafba2016614418f969fa5697383e47c
        public String state;	//settled
        public String invoice;	//order-1234
        public String type;	//settle
        public Double amount;	//10000
        public String settled;	//2015-04-04T12:40:56.656+00:00
        public Datetime authorized;	//
        public Datetime failed;	//2015-04-04T12:40:56.656+00:00
        public String refunded;	//2015-04-04T12:40:56.656+00:00
        public Datetime created;	//2015-04-04T12:40:56.656+00:00
        public String payment_type;	//card
        public PS_card_transaction card_transaction;
        public PS_mpo_transaction mpo_transaction;
        public PS_manual_transaction manual_transaction;
        public PS_mps_transaction mps_transaction;
        //Start TCS-36 Changes
        public PS_klarna_transaction klarna_transaction;
        //End
        public String payment_context;	//
    }

    public class PS_card_transaction {
        public PS_card card;
        public String error;	//credit_card_expired
        public String fingerprint;	//cst_64e8a26cc0e85bc3f5ce7c5b366b4096
        public String provider;	//clearhaus
        public String ref_transaction;	//a7a7195c54f644369922d0dfe794dd0c
        public String gw_id;	//28fc559a229e4fd3a134297a478a0075
        public Datetime last_failed;	//2015-04-04T12:40:56.656+00:00
        public Datetime first_failed;	//2015-04-04T12:40:56.656+00:00
        public String error_state;	//hard_declined
        public String card_type;	//visa_dk
        public String transaction_card_type;	//visa
        public String exp_date;	//09-18
        public String masked_card;	//457111XXXXXX3777
        public String card_country;	//US
        public String strong_authentication_status;	//secured_by_nets
        public String three_d_secure_status;	//Y
        public String risk_rule;	//
        public String acquirer_code;	//40135
        public String acquirer_message;	//Card expired
        public String acquirer_reference;	//Card expired
        public String text_on_statement;	//myshop.com 123
        public Decimal surcharge_fee;	//123
    }

    public class PS_card {
        public String id;	//ca_fcfac2016614418f969fa5697383e47c
        public String state;	//active
        public String customer;	//customer00069
        public String reference;	//cs_6be90a4babc3c57ef7e6e477ac97ed3b
        public String failed;	//2015-06-04T12:40:56.656+00:00
        public String created;	//2015-04-04T12:40:56.656+00:00
        public String fingerprint;	//cst_64e8a26cc0e85bc3f5ce7c5b366b4096
        public String reactivated;	//2015-05-14T00:00:00.000+00:00
        public String gw_ref;	//657e86162633415a9e6b715248c84da4
        public String card_type;	//visa_dk
        public String transaction_card_type;	//visa
        public String exp_date;	//09-18
        public String masked_card;	//457111XXXXXX3777
        public String last_success;	//2015-05-14T00:00:00.000+00:00
        public String last_failed;	//2015-05-14T00:00:00.000+00:00
        public String first_fail;	//2015-05-14T00:00:00.000+00:00
        public String error_code;	//credit_card_expired
        public String error_state;	//hard_declined
        public String strong_authentication_status;	//secured_by_nets
        public String three_d_secure_status;	//Y
        public String risk_rule;	//
        public String card_country;	//US
    }

    public class PS_mpo_transaction {
        public PS_card card;
        public String error;	//credit_card_expired
        public String fingerprint;	//cst_64e8a26cc0e85bc3f5ce7c5b366b4096
        public String provider;	//clearhaus
        public String ref_transaction;	//a7a7195c54f644369922d0dfe794dd0c
        public String gw_id;	//28fc559a229e4fd3a134297a478a0075
        public String last_failed;	//2015-04-04T12:40:56.656+00:00
        public String first_failed;	//2015-04-04T12:40:56.656+00:00
        public String error_state;	//hard_declined
        public String card_type;	//visa_dk
        public String transaction_card_type;	//visa
        public String exp_date;	//09-18
        public String masked_card;	//457111XXXXXX3777
        public String card_country;	//US
        public String strong_authentication_status;	//secured_by_nets
        public String three_d_secure_status;	//Y
        public String risk_rule;	//
        public String acquirer_code;	//40135
        public String acquirer_message;	//Card expired
        public String acquirer_reference;	//Card expired
        public String text_on_statement;	//myshop.com 123
        public Integer surcharge_fee;	//123
    }

    public class PS_manual_transaction {
        public String method;	//cash
        public String comment;	//Paid by cash in the shop
        public String reference;	//231

        //    DFJ-318 changes start
        public Datetime payment_date;	//2016-07-10
        //    DFJ-318 changes end
    }

    public class PS_mps_transaction {
        public String error;	//credit_card_expired
        public String ref_transaction;	//a7a7195c54f644369922d0dfe794dd0c
        public String error_state;	//hard_declined
        public String acquirer_message;	//Rejected
        public String mps_id;	//
        public PS_mps_subscription mps_subscription;
        public String mps_payment_type;	//
    }

    public class PS_mps_subscription {
        public String id;	//ca_fcfac2016614418f969fa5697383e47c  basically a payment_method Id
        public String state;	//active
        public String customer;	//customer00069
        public String reference;	//cs_6be90a4babc3c57ef7e6e477ac97ed3b
        public Datetime failed;	//2015-06-04T12:40:56.656+00:00
        public Datetime created;	//2015-04-04T12:40:56.656+00:00
        public String external_id;	//mps_sub_001
    }


    public class PS_klarna_transaction {
        public String error;	
        public String type;	//klarna_pay_later
        public String ref_transaction;	//a7a7195c54f644369922d0dfe794dd0c payment_method Id
        public String error_state;	//hard_declined
        public String acquirer_message;	//Rejected
        public String klarna_id;	//28fc559a229e4fd3a134297a478a0075
      
    }
    /*Wrapper End*/

    /**
     * @Description : Wrapper class for the Invoice webhooks
     */
    public class InvoiceWebhookWrapper{
        public String id;
        public Datetime timestamp;
        public String signature;
        public String invoice;
        public String subscription;
        public String customer;
        public String event_type;
        public String event_id;
        //Chnages TCS-16 
        //Start 
        //Description : Parameters add for store payment Information
        public String payment_method;
        public String payment_method_reference;
        //end
    }    

    /**
     * @Description : Wrapper class for the subscription wrapper.
     */
    public class PS_SubscriptionWrapper{
        public String handle;	//sub-0014
        public String customer;	//cust-0003
        public Datetime current_period_start;//DFJ-191 Changes
        public String plan;	//plan-ae5d0
        public String state;	//active
        public boolean test;
        public Integer quantity;	//1
        public String timezone;	//Europe/Copenhagen
        public Datetime created;	//2022-07-20T17:09:52.233+00:00
        public Datetime activated;	//2022-07-20T17:09:52.233+00:00
        public boolean renewing;
        public Integer plan_version;	//1
        public Datetime start_date;	//2022-07-20T17:09:52.233+00:00
        public Integer grace_duration;	//1800
        public Datetime next_period_start;	//2022-07-20T22:00:00.000+00:00
        public Datetime first_period_start;	//2022-07-20T22:00:00.000+00:00
        public Datetime trial_start;	//2022-07-20T17:09:52.233+00:00
        public Datetime trial_end;	//2022-07-20T22:00:00.000+00:00
        public boolean is_cancelled;
        //DFJ-196 Changes
        public Datetime cancelled_date;
        public Datetime expired_date;
        public Datetime on_hold_date;
        public Datetime reactivated;
        //End
        public boolean in_trial;
        public boolean has_started;
        public Integer renewal_count;	//0
        public boolean payment_method_added;
        public Integer failed_invoices;	//0
        public Double failed_amount;	//0
        public Integer cancelled_invoices;	//0
        public Double cancelled_amount;	//0
        public Integer pending_invoices;	//0
        public Double pending_amount;	//0
        public Double dunning_invoices;	//0
        public Double dunning_amount;	//0
        public Double settled_invoices;	//0
        public Double settled_amount;	//0
        public Double refunded_amount;	//0
        public Double pending_additional_costs;	//0
        public Double pending_additional_cost_amount;	//0
        public Double transferred_additional_costs;	//0
        public Double transferred_additional_cost_amount;	//0
        public Double pending_credits;	//0
        public Double pending_credit_amount;	//0
        public Double transferred_credits;	//0
        public Double transferred_credit_amount;	//0
        public PS_hosted_page_links hosted_page_links;
        public String error;
    }

    public class PS_hosted_page_links {
        public String payment_info;	//https://checkout.reepay.com/#/subscription/pay/da_DK/dfc6a242db64dccb1c5ddb838fb50dc3/sub-0014
    }

    //Changes Start DFJ-27
    public class PS_AddressInfoWrapper{
       @AuraEnabled public Lead leadAddressInfo;
      @AuraEnabled public String DefaultCurrencyIsoCode;
       @AuraEnabled public String errorMessage;
       @AuraEnabled public List<LeadProducts__c> leadProductsList;
       //DFJ-80
       @AuraEnabled public Account accountInfo;
       @AuraEnabled public sObject addressInfo;
       @AuraEnabled public String sObjectName;
       ///End

       //@AuraEnabled public String isSubscriptionIncluded;
    }
    //end
    //changes start TCS-43
    /**
     * @Description : Wrapper class for the Plan Info
     */
    public class PS_PlanInfokWrapper{
        public String name;
        public String description;
        public Double amount;
        public String handle;
        public String customer;
        public Double interval_length;
        public String schedule_type;
        public String error;
        //DFJ-191 Changes
        public Integer version;
        //End
    }
  
 /*Changes for DFJ-354
    public class sessionData{
        public Double mps_amount; //vipps_recurring_amount
        public String mps_plan; //vipps_recurring_product_name
        public String mps_description; //vipps_recurring_product_description
        public String mps_frequency; // vipps_recurring_interval_count
    }*/
    //End
       
    public class sessionData{
        public Double vipps_recurring_amount;
        public String vipps_recurring_product_name;
        public String vipps_recurring_product_description;
      //  public String vipps_recurring_interval_count;
        public String vipps_recurring_interval_unit;
    }

    //    DFJ-318 changes start
    public class PaymentInfo{
        @AuraEnabled public String invoiceUniqueHandle;
        @AuraEnabled public String paymentType;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public Decimal refundedAmount;
        @AuraEnabled public Decimal totalPaymentAmount ;
        @AuraEnabled public String subscriptionStatus;//DFJ-318-V2
        @AuraEnabled public String type;//DFJ-318-V2
         @AuraEnabled public String status;//DFJ-318-V2
        @AuraEnabled public List<Payment_order_line__c> paymentOrderLines;
    }

    public class CreditNoteWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String invoice;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public List<CreditNoteLineWrapper> credit_note_lines;
    }

    public class CreditNoteLineWrapper{
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String text;
        @AuraEnabled public Decimal quantity;
    }
    //    DFJ-318 changes end


}