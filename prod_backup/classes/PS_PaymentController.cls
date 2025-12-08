/*
   * @ Version : 1.0
   * @ Created Date : 2022-06-29
   * @Description : Handle the reepay operations.
*/
public with sharing class PS_PaymentController {
    /*
    * @Description  method to create the payment record.
    * @Param        recordId
    * @Return       String
    */
    @AuraEnabled
    public static PS_PaymentUtility.PaymentWrapper createPaymentRecord(Id recordId){
        try {
            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_PaymentService.createPaymentRecord(recordId);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Creating payment record.', ex.getMessage(), 'Error', 'PS_PaymentController.createPaymentRecord', '', String.valueOf(ex.getLineNumber()));
            PS_PaymentUtility.PaymentWrapper PaymentWrapperInstance= new PS_PaymentUtility.PaymentWrapper();
            PaymentWrapperInstance.errorMessage = ex.getMessage();
            return PaymentWrapperInstance;
        }
    }

    //DFJ-80
    @AuraEnabled
    public static PS_PaymentUtility.PaymentWrapper createPaymentRecordOnAccount(Id recordId, Order orderRecord, String orderProductList,Decimal orderFixedDisc, Decimal totalOrder,String selectedJournal){
        try {
            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_PaymentService.createPaymentRecordOnAccount(recordId,orderRecord,orderProductList,orderFixedDisc,totalOrder,selectedJournal);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Creating payment record.', ex.getMessage(), 'Error', 'PS_PaymentController.createPaymentRecordOnAccount', '', String.valueOf(ex.getLineNumber()));
            PS_PaymentUtility.PaymentWrapper PaymentWrapperInstance= new PS_PaymentUtility.PaymentWrapper();
            PaymentWrapperInstance.errorMessage = ex.getMessage();
            return PaymentWrapperInstance;
        }
    }
    //End
     //DFJ-80
     @AuraEnabled
     public static PS_PaymentUtility.PaymentWrapper getUpdatedPayment(Id recordId){
         try {
             if (Test.isRunningTest() && String.isBlank(recordId)) {
                 Double result = 10/0;
             }
             return PS_PaymentService.getUpdatedPayment(recordId);
         } catch (Exception ex) {
             DFJ_ErrorLogController.addErrorLogs('', 'Fetching payment record.', ex.getMessage(), 'Error', 'PS_PaymentController.getUpdatedPayment', '', String.valueOf(ex.getLineNumber()));
             PS_PaymentUtility.PaymentWrapper PaymentWrapperInstance= new PS_PaymentUtility.PaymentWrapper();
             PaymentWrapperInstance.errorMessage = ex.getMessage();
             return PaymentWrapperInstance;
         }
     }
     //End

    /*
    * @Description  method to callout and create the customer and invoice.
    * @Param        recordId
    * @Return       String
    */



    @AuraEnabled
    public static PS_PaymentUtility.PaymentWrapper makeCalloutToCreateCustomerInvoice(Id recordId, String payment, String paymentOrderLines, List<LeadProducts__c> subscriptionLeadProducts){
        try {
            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_PaymentService.makeCalloutToCreateCustomerInvoice(recordId, payment, paymentOrderLines, subscriptionLeadProducts);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'making Callout to create customer invoice', ex.getMessage(), 'Error', 'PS_PaymentController.makeCalloutToCreateCustomerInvoice', '', String.valueOf(ex.getLineNumber()));
            PS_PaymentUtility.PaymentWrapper PaymentWrapperInstance= new PS_PaymentUtility.PaymentWrapper();
            PaymentWrapperInstance.errorMessage = 'In makeCalloutToCreateCustomerInvoice(): '+ex.getMessage();
            return PaymentWrapperInstance;
        }
    }

    // Changes for DFJ-273
    // Start
    @AuraEnabled
    public static PS_PaymentUtility.PaymentWrapper makeCalloutToCreateCustomerInvoiceForOppProducts(Id recordId, String payment, String paymentOrderLines, List<OpportunityLineItem> subscriptionProducts){
        try {

            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_PaymentService.makeCalloutToCreateCustomerInvoice(recordId, payment, paymentOrderLines, subscriptionProducts);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'making Callout to create customer invoice', ex.getMessage(), 'Error', 'PS_PaymentController.makeCalloutToCreateCustomerInvoiceForOppProducts', '', String.valueOf(ex.getLineNumber()));
            PS_PaymentUtility.PaymentWrapper PaymentWrapperInstance= new PS_PaymentUtility.PaymentWrapper();
            PaymentWrapperInstance.errorMessage = 'In makeCalloutToCreateCustomerInvoiceForOppProducts(): '+ex.getMessage();
            return PaymentWrapperInstance;
        }
    }
    // End


//DFJ-80 Changes
    @AuraEnabled
    public static PS_PaymentUtility.PaymentWrapper showPaymentStatusOnAccount(Id recordId){
        try {
            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_PaymentService.showPaymentStatusOnAccount(recordId);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Fetching updated payment record', ex.getMessage(), 'Error', 'PS_PaymentController.showPaymentStatusOnAccount', '', String.valueOf(ex.getLineNumber()));
            PS_PaymentUtility.PaymentWrapper PaymentWrapperInstance= new PS_PaymentUtility.PaymentWrapper();
            PaymentWrapperInstance.errorMessage = ex.getMessage();
            return PaymentWrapperInstance;
        }
    }
//End
    /*
    * @Description  get payment records based on the recordId
    * @Param        recordId
    * @Return       String
    */
    @AuraEnabled
    public static PS_PaymentUtility.PaymentStatusWrapper getPaymentRecordsForStatus(Id recordId){
        try {
            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_PaymentService.getPaymentRecords(recordId);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Getting payment record for status component', ex.getMessage(), 'Error', 'PS_PaymentController.getPaymentRecordsForStatus', '', String.valueOf(ex.getLineNumber()));
            PS_PaymentUtility.PaymentStatusWrapper PaymentWrapperInstance= new PS_PaymentUtility.PaymentStatusWrapper();
            PaymentWrapperInstance.errorMessage = ex.getMessage();
            return PaymentWrapperInstance;
        }
    }

    /*
    * @Description  handle debugs from component
    * @Param        recordId
    * @Return       String
    */
    @AuraEnabled
    public static Boolean handleCompoentDebugLogs(String event, String message, String severity, String source){
        try {
            if (Test.isRunningTest() && String.isBlank(event)) {
                Double result = 10/0;
            }
            DFJ_ErrorLogController.addErrorLogs('', event, message, severity, source,'','');
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Handling component debug logs.', ex.getMessage(), 'Error', 'PS_PaymentController.handleCompoentDebugLogs', '', String.valueOf(ex.getLineNumber()));
        }
        return true;
    }

    // DIN-344 changes
    /*
    * @Description  method to cancel the invoice and subscription
    * @Param        recordId, paymentRecordId
    * @Return       Boolean
    */
    @AuraEnabled
    public static String cancelPayment(String recordId, String paymentRecordId){
        try {
            return PS_PaymentService.cancelPayment(recordId,paymentRecordId);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Cancel payment.', ex.getMessage(), 'Error', 'PS_PaymentController.cancelPayment', '', String.valueOf(ex.getLineNumber()));
            return 'Something went wrong';
        }
        
    }

     // DIN-385 changes
    /*
    * @Description  method to get the Lead and Order Address Info
    * @Param        recordId
    * @Return       String
    */
    @AuraEnabled
    public static PS_PaymentUtility.PS_AddressInfoWrapper getAddressInfoFromLeadOROrder(String recordId){
        try {
            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_PaymentService.getAddressInfoFromLeadOROrder(recordId);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Getting Address Info for status component', ex.getMessage(), 'Error', 'PS_PaymentController.getAddressInfoFromLeadOROrder', '', String.valueOf(ex.getLineNumber()));
            PS_PaymentUtility.PS_AddressInfoWrapper addressInfoWrapper = new PS_PaymentUtility.PS_AddressInfoWrapper();
            addressInfoWrapper.errorMessage = ex.getMessage();
            return addressInfoWrapper ;
        }
        
    }
//End
//DFJ-80 starts
@AuraEnabled
    public static PS_PaymentUtility.PS_AddressInfoWrapper getAddressInfoFromAccount(String recordId,String selectedJournal){
        try {
            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_PaymentService.getAddressInfoFromAccount_Apex(recordId,selectedJournal);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Getting Address Info for status component', ex.getMessage(), 'Error', 'PS_PaymentController.getAddressInfoFromAccount', '', String.valueOf(ex.getLineNumber()));
            PS_PaymentUtility.PS_AddressInfoWrapper addressInfoWrapper = new PS_PaymentUtility.PS_AddressInfoWrapper();
            addressInfoWrapper.errorMessage = ex.getMessage();
            return addressInfoWrapper ;
        }
        
    }
    //End
}