import {api, LightningElement} from 'lwc';
import handleOfflineManualSettle from "@salesforce/apex/PS_PaymentService.handleOfflineManualSettle";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class Dfj_OfflineManualSettlePayment extends LightningElement {

    @api invoiceUniqueHandle;
    @api subscriptionStatus;

    get isShowOfflineSettleButton(){
        return !this.isSubscriptionStatusIncluded;
    }

    get isSubscriptionStatusIncluded(){
        return this.subscriptionStatus.toLowerCase() === 'subscription included';
    }
    isOpenOfflineManualSettleModal;

    commentRelatedToManualSettle;
    referenceInputRelatedToManualSettle;

    buttonLabel='Bank Transfer';

    defaultValueOfMethodForManualSettle = "bank_transfer";
    optionsForMethodOfManualSettle = [{
        label: "Bank Transfer", value: "bank_transfer"
    }];

    paymentMethodInputForManualSettle = this.defaultValueOfMethodForManualSettle;

    get defaultValueOfPaymentDate() {
        let dt = new Date();
        return dt.toISOString().slice(0,10)
    }

    dateInputForManualSettle = this.defaultValueOfPaymentDate;

    handleSettleButtonClick(){
        this.isOpenOfflineManualSettleModal = true;
    }

    handleCancelButtonClick() {
        this.isOpenOfflineManualSettleModal = false;
    }

    get isConfirmButtonDisabled(){
        return !this.paymentMethodInputForManualSettle || !this.dateInputForManualSettle
    }



    handleCommentInputForManualSettle(event) {
        this.commentRelatedToManualSettle = event.target.value;
    }

    handleReferenceInputForManualSettle(event) {
        this.referenceInputRelatedToManualSettle = event.target.value;
    }

    handleConfirmButtonClick(){

        this.callApexMethodForOfflineManualSettleOfPayment();
        this.isOpenOfflineManualSettleModal = false;
    }

    callApexMethodForOfflineManualSettleOfPayment(){
        const bodyForCallout = {
            method : this.paymentMethodInputForManualSettle,
            comment : this.commentRelatedToManualSettle,
            reference : this.referenceInputRelatedToManualSettle,
            payment_date: this.dateInputForManualSettle
        }


        if (this.invoiceUniqueHandle && JSON.stringify(bodyForCallout)) {

            handleOfflineManualSettle({
                invoiceUniqueHandle: this.invoiceUniqueHandle,
                calloutBody: JSON.stringify(bodyForCallout)
            }).then(
                data => {
                    if (data === "200") {
                        this.customShowToastHelper('success', 'Success', 'Offline manual settle successful.');
                    } else {
                        this.customShowToastHelper('error', 'Error', 'Error doing offline manual settle.');
                    }

                }
            ).catch(e => {
                console.error("🚀️ Error in ~ OfflineManualSettlePayment ~ () :", JSON.stringify(e.message));
                this.customShowToastHelper('error', 'Error', 'Error doing offline manual settle.');
            });
        }
        else {
            console.error('There is something wrong with invoice unique handle or stringified callout body. ');
        }
    }

    customShowToastHelper(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant, title: title, message: message
        });

        this.dispatchEvent(event);
    }

}