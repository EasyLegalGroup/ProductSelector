import {api, wire, LightningElement} from 'lwc';

import getDataForConfirmOrderPage
    from '@salesforce/apex/DFJ_PaymentController.getDataForConfirmOrderPage';

import getPaymentRecordsForStatus from '@salesforce/apex/PS_PaymentController.getPaymentRecordsForStatus';
import createPaymentRecord from '@salesforce/apex/DFJ_PaymentController.createPaymentRecord';
import makeCalloutToCreateCustomerInvoiceForOppProducts
    from '@salesforce/apex/PS_PaymentController.makeCalloutToCreateCustomerInvoiceForOppProducts';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import {publish, MessageContext, createMessageContext, releaseMessageContext, subscribe, unsubscribe,APPLICATION_SCOPE} from 'lightning/messageService';
import Update_Availability_Status_Of_Payment_Record
    from '@salesforce/messageChannel/Update_Availability_Status_Of_Payment_Record__c';

import cancelPayment from '@salesforce/apex/PS_PaymentController.cancelPayment';
import Payment_Message_Channel from '@salesforce/messageChannel/PaymentEnableMessage__c';
export default class Dfj_Payment_For_Opportunity extends LightningElement {
    @api recordId;
    @api isOnProductSelector = false;
    @api disableCreatePayment;
    @api flowstatus;
    @wire(MessageContext) messageContext;
    oppRecord;
    accRecord;
    oppProducts = [];
    paymentRecord;
    paymentRecords;
    toShowOrderOverviewModal = false;
    isShowStatusPaymentNotCreated = true;
    tempPaymentRecord;
    tempPaymentOrderLineItems;
    //disableCreatePayment = true;
   
    context = createMessageContext();
    subscription = null;

    connectedCallback() {
        console.log('Connected Callback');
        this.subscribeToMessageChannel();
        this.getDataToShowOnConfirmOrderModal();
        this.handleGetPaymentRecordsForStatus();
        console.log('disableCreatePayment : ' + this.disableCreatePayment);
    }
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                Payment_Message_Channel,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE },
            );
        }
    }
    handleMessage(message) {
        console.log('Inside handle message');
        console.log('msg',message);
        this.disableCreatePayment = message.disablePaymentButton;
        console.log('disabled = ' + this.disableCreatePayment);
    }

    // renderedCallback(){
    //     if(!this.flowstatus){
    //     this.disableCreatePayment = false;
    //     }
    // }


    // get subscription status for confirm order page
    get subscriptionStatusValueForConfirmOrderPage() {
        if (this.isThereAnySubscriptionProductInOppProducts) {
            return "Subscription included."
        } else {
            return "No subscription included.";
        }
    }

    // returns true if subscription status is accepted
    get isSubscriptionStatusAccepted() {
        if (this.subscriptionStatusToShow === "Accepted") {
            return true;
        }
        return false;
    }

    // get subscription status from payment record
    get subscriptionStatusToShow() {
        if (this.isThereAnySubscriptionProductInOppProducts) {

            return this.subscriptionStatusFromPaymentRecord;

        } else {
            return "No subscription included.";
        }
    }

    get isSubscriptionStatusNotAcceptedAndOppProdsContainsOnlySubscriptionProds() {
        if (this.doesOppProdsContainsOnlySubscriptionProds && this.subscriptionStatusToShow !== "Accepted") {
            return true;
        }

        return false;
    }

    // returns true if there is any one time product in oppProducts
    get doesOppProdsContainsOneTimeProduct() {
        let result = false;
        if (this.oppProducts.length > 0) {
            for (const oppProduct of this.oppProducts) {
                if (!oppProduct.Is_subscription__c) {
                    result = true;
                    break;
                }
            }
        }

        return result;
    }

    // returns true if there are only subscription products in oppProducts
    get doesOppProdsContainsOnlySubscriptionProds() {
        let result = false;
        if (this.oppProducts.length > 0) {
            result = true;
            for (const oppProduct of this.oppProducts) {
                if (!oppProduct.Is_subscription__c) {
                    result = false;
                    break;
                }
            }
        }

        return result;
    }

    // returns true if there are is at least one subscription products in oppProducts
    get isThereAnySubscriptionProductInOppProducts() {
        for (const oppProduct of this.oppProducts) {
            if (oppProduct.Is_subscription__c) {
                return true;
            }
        }

        return false;
    }

    // get subtotal value to show on confirm order page
    get subTotalForConfirmOrderPage() {
        let result = 0.00;
        for (const oppProduct of this.oppProducts) {
            result += parseFloat(oppProduct.Net_Total_Price__c);
        }

        return result;
    }

    // get subscription status from payment record
    get subscriptionStatusFromPaymentRecord() {

        if (this.isPaymentRecordAvailable && this.paymentRecord.Subscription_status__c) {
            return this.paymentRecord.Subscription_status__c
        } else {
            return null;
        }
    }

    // get subscription link from payment record
    get subscriptionLink() {
        if (this.isPaymentRecordAvailable && this.paymentRecord.Subscription_link__c) {
            return this.paymentRecord.Subscription_link__c
        } else {
            return null;
        }
    }

    // returns true if opportunity record is available
    get isOppRecordAvailable() {
        if (this.oppRecord) {
            return true;
        }
        return false;
    }

    get opportunityName() {

        if (this.isOppRecordAvailable && this.oppRecord.Name) {
            return this.oppRecord.Name
        }
        return "";
    }

    get tempVariableToHideOrShowPaymentCreatedStatus() {
        return !this.isPaymentRecordAvailable;
    }

    // get billing street from payment record
    get billingStreet() {
        if (this.isPaymentRecordAvailable) {
            let paymentRecord = this.paymentRecord;
            return paymentRecord.BillingStreet__c;
        }
        return "";
    }

    // get postalCode from payment record
    get postalCodeFromPaymentRecord() {
        if (this.isPaymentRecordAvailable) {
            let paymentRecord = this.paymentRecord;
            return paymentRecord.Billing_PostalCode__c;
        }
        return "";
    }

    // get billing city from payment record
    get billingCityFromPaymentRecord() {
        if (this.isPaymentRecordAvailable) {
            let paymentRecord = this.paymentRecord;
            return paymentRecord.BillingCity__c;
        }
        return "";
    }

    // get payment total
    get paymentTotal() {
        if (this.isPaymentRecordAvailable) {
            return this.paymentRecord.Amount__c;
        }
        return null;
    }

    // get currency iso code to show on payment status
    get currencyIsoCodeForPaymentStatus() {
        if (this.isPaymentRecordAvailable) {
            return this.paymentRecord.CurrencyIsoCode;
        }
        return null;
    }

    // get payment link
    get paymentLinkForPaymentStatus() {
        if (this.isPaymentRecordAvailable && this.paymentRecord.Payment_link__c) {
            return this.paymentRecord.Payment_link__c
        } else {
            return null;
        }
    }

    // get payment status
    get paymentStatus() {
        if (this.isPaymentRecordAvailable) {
            if (this.paymentRecord.Status__c) {
                return this.paymentRecord.Status__c;
            }
        } else {
            return "Payment not Created."
        }
    }

    // get payment status container class
    get classOfPaymentStatusContainer() {
        let statusClass = '';
        if (this.isPaymentRecordAvailable) {
            if (this.paymentRecord.Status__c.toLowerCase() === "created" || this.paymentRecord.Status__c.toLowerCase() === "pending") {
                statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorOrange";
            } else if (this.paymentRecord.Status__c.toLowerCase() === "authorized") {
                statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorBlue";
            } else if (this.paymentRecord.Status__c.toLowerCase() === "settled") {
                statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorGreen";
            } else if (this.paymentRecord.Status__c.toLowerCase() === "failed" || this.paymentRecord.Status__c.toLowerCase() === "cancelled") {
                statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorRed";
            } else if (this.paymentRecord.Status__c.toLowerCase() === "dunning") {
                statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorGray";
            } else if (this.paymentRecord.Status__c.toLowerCase() === "refunded") {
                statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorBlue";
            }
        }
        return statusClass;
    }

    // get fixed discount value for confirm order modal
    get fixedDiscountValueForConfirmOrderModal() {
        // change kajal 14.11
        /*let result = this.subTotalForConfirmOrderPage - this.orderTotalFromOpp;
        if (result === 0) {
            return null;
        }
        return result;*/

        let result = this.oppRecord.Fixed_Discount_Type__c;
        return result;
    }

    // get order total value from opportunity record
    get orderTotalFromOpp() {
        //   change kajal 14.11
        if(this.oppRecord.Opportunity_Total__c < 0)
           return 0;
        return this.oppRecord.Opportunity_Total__c;
    }

    // returns true if payment record ( except cancelled and refunded ), is available
    get isPaymentRecordAvailable() {
        if (this.paymentRecord) {
            return true
        }
        return false;
    }

    // send payment record status message to the product selector component so that edit,delete and add product buttons are enabled/disabled dynamically
    sendPaymentRecordStatusMessage() {
        publish(this.messageContext, Update_Availability_Status_Of_Payment_Record,
            {
                isPaymentRecordAvailableInPaymentComponent: this.isPaymentRecordAvailable
            }
        )
    }

    // get data to show on confirm order modal
    async getDataToShowOnConfirmOrderModal() {
        try {

            let response = await getDataForConfirmOrderPage({recordId: this.recordId});
            console.log('recordId:' + this.recordId);
            console.log('product wrapper------------>', response);
            this.accRecord = response.accountRecordInstance;
            this.oppRecord = response.opportunityRecordInstance;
            this.oppProducts = response.opportunityProductsData;
            console.log('opp record------->',this.oppRecord);
            console.log('oppProducts above map : ' + this.oppProducts);
            
            console.log('oppProducts in Payment component : ' + JSON.stringify(this.oppProducts));

        } catch (e) {
            console.log("🚀️ Error in ~ DFJ_PaymentCreatorForOpportunity ~ getDataToShowOnConfirmOrderModal() :", JSON.stringify(e.message));
        }
    }

    // handle cancellation of payment
    async handleCancelPayment() {
        try {

            if (this.doesOppProdsContainsOneTimeProduct && this.paymentStatus === "Settled") {
                this.ShowErrorToastEvent("Error", "Invoice has active transactions.")
            } else {
                if (this.isPaymentRecordAvailable) {
                    const idOfPaymentRecord = this.paymentRecord.Id;
                    if (idOfPaymentRecord) {
                        await cancelPayment({
                            recordId: this.recordId,
                            paymentRecordId: idOfPaymentRecord
                        }).then(res => {

                            this.ShowSuccessToastEvent('Success.','success.');

                        }).catch(e => {
                            console.log("🚀️ Error in ~ DFJ_PaymentCreatorForOpportunity ~ handleCancelPayment() ~ cancelPayment :", JSON.stringify(e.message));
                        })
                    } else {
                        console.log('Unable to get `idOfPaymentRecord`');
                    }
                } else {
                    console.log('No payment record available.');
                }

                this.handleGetPaymentRecordsForStatus();
                this.refreshStandardComponents();
            }

        } catch (e) {
            console.log("🚀️ Error in ~ DFJ_PaymentForOpportunity ~ handleCancelPayment() :", JSON.stringify(e.message));
        }


    }


    // handle getting payment records
    handleGetPaymentRecordsForStatus() {
        getPaymentRecordsForStatus({recordId: this.recordId}).then(result => {

            if (result.successMessage) {
                this.paymentRecords = result.paymentList;

                if (this.paymentRecords.length > 0) {

                    for (const currentPaymentRecord of this.paymentRecords) {

                        if (currentPaymentRecord.Status__c && currentPaymentRecord.Status__c !== "Cancelled") {
                            this.paymentRecord = currentPaymentRecord;
                            this.isShowStatusPaymentNotCreated = false;


                            break;
                        }
                    }

                } else {
                    this.paymentRecord = null;
                }

                this.sendPaymentRecordStatusMessage(); // sending this message so that the product selector component can disable/enable edit/delete/'add product' button as per the payment record status
            } else {
                console.log("🚀️ ~ DFJ_PaymentForOpportunity ~ handleGetPaymentRecordsForStatus ~ getPaymentRecordsForStatus ~ result.errorMessage:", result.errorMessage);
            }


        }).catch(e => {
                console.log("🚀️ Error in ~ DFJ_PaymentForOpportunity ~ handleGetPaymentRecordsForStatus() ~ apex getPaymentRecordsForStatus() :", JSON.stringify(e.message));
            }
        );
    }

    // handler invoked when 'Create Payment' button is clicked, first it shows the confirm order modal
    handlerCreatePaymentButtonClick() {
        try {

            console.log('inside handlerCreatePaymentButtonClick ');
            this.getDataToShowOnConfirmOrderModal();
            this.toShowOrderOverviewModal = true;
            console.log('toShowOrderOverviewModal : ' + this.toShowOrderOverviewModal);


        } catch (e) {
            console.log("🚀️ Error in ~ DFJ_PaymentCreatorForOpportunity ~ handlerCreatePaymentButtonClick() :", JSON.stringify(e.message));
        }

    }

    // handler invoked when 'Confirm' button is clicked on confirm order modal
    handleConfirmButtonClick() {
        try {

            this.handleCreationOfPaymentRecord();

            this.toShowOrderOverviewModal = false;

        } catch (e) {
            console.log("🚀️ Error in ~ DFJ_PaymentCreatorForOpportunity ~ handleConfirmButtonClick() :", JSON.stringify(e.message));
        }
    }

    // handle creation of payment record
    async handleCreationOfPaymentRecord() {
        try {

            createPaymentRecord({recordId: this.recordId}).then(result => {

                if (result.successMessage) {
                    this.tempPaymentRecord = result.payment;
                    this.tempPaymentOrderLineItems = result.paymentOrderLines;

                    eval("$A.get('e.force:refreshView').fire()"); // to reflect the status of payment records in standard UI component(s)
                    this.ShowSuccessToastEvent('Success','Payment created successfully');

                    this.handleCalloutToCreateCustomerRecordAndInvoiceCreation();
                } else {
                    this.ShowErrorToastEvent(result && result.errorMessage ? result.errorMessage : 'Something went wrong', 'Error');
                }
            }).catch((e) => {
                console.log("🚀️ Error in ~ DFJ_PaymentCreatorForOpportunity ~ handleCreationOfPayment() ~ apex method createPaymentRecord :", JSON.stringify(e.body ? e.body.message : e));
            })

        } catch (e) {
            console.log("🚀️ Error in ~ DFJ_PaymentCreatorForOpportunity ~ handleCreationOfPayment() :", JSON.stringify(e.message));
        }
    }

    // get subscription opportunity products
    get subscriptionOppProds() {
        let result = [];
        if (this.oppProducts.length > 0) {
            for (const oppProduct of this.oppProducts) {
                if (oppProduct.Is_subscription__c) {
                    result.push(oppProduct);
                }
            }

            return result;
        }
        return [];
    }

    // handle callout to create customer record and invoice creation
    async handleCalloutToCreateCustomerRecordAndInvoiceCreation() {
        try {

            let result = await makeCalloutToCreateCustomerInvoiceForOppProducts({
                recordId: this.recordId,
                payment: JSON.stringify(this.tempPaymentRecord),
                paymentOrderLines: JSON.stringify(this.tempPaymentOrderLineItems),
                subscriptionProducts: this.subscriptionOppProds
            });

            if (result.successMessage) {
                this.ShowSuccessToastEvent('Success','Invoice created successfully');
                // kajal 17.11
                this.dispatchEvent(new CustomEvent('paymentcreated', { 
                detail: { 
                    recordId: this.recordId,
                    action: 'paymentCreated',
                    payment: this.payment
                },
                bubbles: true,
                composed: true
            }));
 // kajal17.11
                this.handleGetPaymentRecordsForStatus();

                this.isShowStatusPaymentNotCreated = false;


            }


        } catch (e) {
            console.log("🚀️ Error in ~ DFJ_PaymentCreatorForOpportunity ~ handleCalloutToCreateCustomerRecordAndInvoiceCreation() :", JSON.stringify(e.message));
        }
    }

    // helper method to close the confirm order modal
    closeModal() {
        this.toShowOrderOverviewModal = false;
    }

    // handle refresh icon click
    handleRefreshIconClick() {
        try {

            this.handleGetPaymentRecordsForStatus();

        } catch (e) {

        }
    }

    // used to Show success toast
    ShowSuccessToastEvent(title, message) {
        if (!title) {
            return;
        }
        if (!message) {
            message = '';
        }
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: "success",
            mode: 'pester',
        });
        this.dispatchEvent(evt);
    }

    // used to Show Error toast
    ShowErrorToastEvent(title, message) {
        if (!title) {
            return;
        }
        if (!message) {
            message = '';
        }
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: "error",
            mode: 'pester',
        });
        this.dispatchEvent(evt);
    }

    // used to refresh standard UI component(s)
    refreshStandardComponents() {
        eval("$A.get('e.force:refreshView').fire()");
    }

    @api hideCreatePaymentButton = false;

}