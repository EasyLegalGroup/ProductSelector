import { LightningElement, api, wire, track } from 'lwc';
import getPaymentRecordsForStatus from '@salesforce/apex/PS_PaymentController.getPaymentRecordsForStatus';
import cancelPayment from '@salesforce/apex/DFJ_PaymentController.cancelPayment';
import handleOfflineManualSettle from "@salesforce/apex/PS_PaymentService.handleOfflineManualSettle";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class PaymentStatusLwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @track payments = [];
    @track isPaymentRecordPresent = false;
    @track showSpinner = true;
    @track error;
    @track isPaymentLinkDisabled = true;
    @track isExpanded = false;
    @track isdeleteConfirmationModal = false;
    @track isCancelling = false;
    @track isOpenOfflineManualSettleModal = false;
    autoRefreshIntervalSeconds = 5;
    autoRefreshCountdown = 0;
    autoRefreshTimer;
    commentRelatedToManualSettle;
    referenceInputRelatedToManualSettle;
    defaultValueOfMethodForManualSettle = "bank_transfer";
    optionsForMethodOfManualSettle = [{
        label: "Bank Transfer", value: "bank_transfer"
    }];
    paymentMethodInputForManualSettle = this.defaultValueOfMethodForManualSettle;
    dateInputForManualSettle = new Date().toISOString().slice(0,10);
    wiredResult;

    @wire(getPaymentRecordsForStatus, { recordId: '$recordId' })
    wiredPayments(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            console.log('Payment data received:', JSON.stringify(data));
            console.log('Object API Name:', this.objectApiName);
            this.payments = data.paymentList ? [...data.paymentList] : [];
            this.isPaymentRecordPresent = this.payments.length > 0;
            this.error = undefined;
            this.isPaymentLinkDisabled = !this.hasPaymentLink;
            
            // Debug payment record details
            if (this.isPaymentRecordPresent) {
                console.log('First payment record:', JSON.stringify(this.payments[0]));
                console.log('Amount:', this.payments[0].Amount__c);
                console.log('Discount:', this.payments[0].Fixed_discount_Type__c);
                console.log('Calculated Total Price:', this.totalPrice);
                
                // Notify parent that payment exists
                this.dispatchEvent(new CustomEvent('paymentfound'));
            } else {
                this.dispatchEvent(new CustomEvent('paymentmissing'));
            }
        } else if (error) {
            console.error('Error fetching payment data:', error);
            this.error = error.body ? error.body.message : 'Unknown error';
            this.payments = [];
            this.isPaymentRecordPresent = false;
            this.isPaymentLinkDisabled = true;
            this.dispatchEvent(new CustomEvent('paymentmissing'));
        }
        this.syncAutoRefreshState();
        this.showSpinner = false;
    }

    get refreshButtonClass() {
        return this.isPaymentRecordPresent ? 'refresh-button-container' : 'refresh-button-container disabled-refresh';
    }

    @api
    refreshPaymentData(showSpinner = false, force = false) {
        if (!this.wiredResult) {
            return;
        }
        if (!this.isPaymentRecordPresent && !force) {
            return;
        }
        if (showSpinner) {
            this.showSpinner = true;
        }
        
        return refreshApex(this.wiredResult)
            .then(() => {
                // spinner reset happens after data rehydrates
                this.isPaymentLinkDisabled = !this.hasPaymentLink;
                if (showSpinner) {
                    this.showSpinner = false;
                }
                this.syncAutoRefreshState();
            })
            .catch(error => {
                console.error('Error refreshing payment data:', error);
                if (showSpinner) {
                    this.showSpinner = false;
                }
            });
    }

    connectedCallback() {
        console.log('recordId:', this.recordId);
        console.log('objectApiName:', this.objectApiName);
        
        if (!this.recordId) {
            this.payments = [];
            this.isPaymentRecordPresent = false;
            this.isPaymentLinkDisabled = true;
        }
        this.syncAutoRefreshState();
    }

    disconnectedCallback() {
        this.stopAutoRefresh();
    }

    get hasPaymentLink() {
        const hasLink = this.payments.length > 0 && this.payments[0].Payment_link__c;
        console.log('Has Payment Link:', hasLink);
        return hasLink;
    }

    get paymentLink() {
        return this.payments.length > 0 ? this.payments[0].Payment_link__c : '';
    }

    get normalizedStatus() {
        return (this.status || '').toLowerCase();
    }

    get isPaymentSettled() {
        const status = this.normalizedStatus;
        return status.includes('settled') || status.includes('succeeded') || status.includes('success') || status.includes('paid');
    }

    get isPaymentPending() {
        return this.normalizedStatus.includes('pending');
    }

    get showPaymentActions() {
        return this.isPaymentRecordPresent;
    }

    get isPaymentActionsDisabled() {
        return !this.isPaymentRecordPresent || this.isCancelling || this.isPaymentSettled;
    }

    get status() {
        return this.payments.length > 0 ? this.payments[0].Status__c : 'No payment created';
    }

    get statusClass() {
        const status = this.status ? this.status.toLowerCase() : '';
        if (status.includes('succeeded') || status.includes('success') || status.includes('settled') || status.includes('paid')) {
            return 'status-pill slds-theme_success';
        } else if (status.includes('canceled') || status.includes('cancelled') || status.includes('failed')) {
            return 'status-pill slds-theme_error';
        } else if (status === 'no payment created') {
            return 'status-pill status-inactive';
        } else {
            return 'status-pill slds-theme_warning'; // Pending
        }
    }

    // get statusVariant() {
    //     const status = this.status ? this.status.toLowerCase() : '';

    //     if (status.includes('pending')) {
    //         return 'background-color: #f97400; color: #000000; height: 40px; width: 100%; display: flex; justify-content: center; align-items: center; border-radius: 6px;';
    //     } else if (status.includes('canceled') || status.includes('cancelled') || status.includes('failed')) {
    //         return 'background-color: #f01a12; color: #ffffff; height: 40px; width: 100%; display: flex; justify-content: center; align-items: center; border-radius: 6px;';
    //     } else if (status.includes('succeeded') || status.includes('success') || status.includes('settled')) {
    //         return 'background-color: #02da4e; color: #ffffff; height: 40px; width: 100%; display: flex; justify-content: center; align-items: center; border-radius: 6px;';
    //     }
        
    //     // Default style for unknown status
    //     return 'background-color: #f97400; color: #000000; height: 40px; width: 100%; display: flex; justify-content: center; align-items: center; border-radius: 6px;';
    // }

    get customerName() {
        return this.payments.length > 0 ? this.payments[0].Billing_name__c || 'N/A' : '';
    }

    get totalPrice() {
       return this.payments[0].Amount__c;
    }

    get currencyCode() {
        return this.payments.length > 0 ? this.payments[0].CurrencyIsoCode || 'USD' : 'USD';
    }

    get isSubscriptionIncluded() {
        return this.payments.length > 0 && this.payments[0].Subscription_status__c === 'Subscription included' ? 'Yes' : 'No';
    }

    get showSubscriptionPill() {
        return this.isPaymentRecordPresent && this.isSubscriptionIncluded === 'Yes';
    }

    get showRefreshControls() {
        return this.isPaymentRecordPresent && this.isPaymentPending;
    }

    get countdownLabel() {
        return this.showRefreshControls && this.autoRefreshCountdown > 0 ? `Auto-refresh in ${this.autoRefreshCountdown}s` : '';
    }

    handleDeleteButton() {
        this.isdeleteConfirmationModal = true;
        console.log('Cancel payment button clicked');
    }

    handleMenuSelect(event) {
        const action = event.detail.value;
        if (action === 'cancel') {
            this.handleDeleteButton();
        } else if (action === 'bank_transfer') {
            this.handleBankTransfer();
        }
    }

    handleRefreshClick() {
        this.refreshPaymentData(false);
        this.resetAutoRefresh();
    }

    handleCloseModal() {
        this.isdeleteConfirmationModal = false;
    }

    handleCancelPayment() {
        console.log('Cancel confirmation - Yes clicked');
        console.log('Record ID:', this.recordId);
        console.log('Payment Record ID:', this.payments[0].Id);
        
        this.isCancelling = true;

        cancelPayment({ recordId: this.recordId, paymentRecordId: this.payments[0].Id })
            .then(result => {
                if (result.includes('Success')) {
                    this.showToast('Success', result, 'success');
                    this.dispatchEvent(new CustomEvent('paymentcanceled'));
                } else {
                    const errMsg = result || 'Unknown error';
                    this.showToast('Error', errMsg, 'error');
                }
                console.log('Result from cancel payment:', result);
                this.handleCloseModal();
                return refreshApex(this.wiredResult);
            })
            .then(() => {
                console.log('Payment data refreshed after cancellation');
                this.isCancelling = false;
            })
            .catch(error => {
                console.error('Error cancelling payment:', error);
                this.showToast('Error', error.body ? error.body.message : error.message || 'Unknown error', 'error');
                this.handleCloseModal();
                this.isCancelling = false;
            });
    }

    handlePaymentLinkClick() {
        if (!this.paymentLink) {
            this.showToast('Error', 'No payment link available', 'error');
            return;
        }
        
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.paymentLink
            }
        });
    }

    handleBankTransfer() {
        this.isOpenOfflineManualSettleModal = true;
    }

    handleCommentInputForManualSettle(event) {
        this.commentRelatedToManualSettle = event.target.value;
    }

    handleReferenceInputForManualSettle(event) {
        this.referenceInputRelatedToManualSettle = event.target.value;
    }

    handleCloseBankTransferModal() {
        this.isOpenOfflineManualSettleModal = false;
    }

    get isConfirmButtonDisabled(){
        return !this.paymentMethodInputForManualSettle || !this.dateInputForManualSettle
    }

    handleConfirmButtonClickForManualSettle(){
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

        let invoiceUniqueHandle = this.payments.length > 0 ? this.payments[0].Invoice_unique_handle__c : null;

        if (invoiceUniqueHandle && JSON.stringify(bodyForCallout)) {

            handleOfflineManualSettle({
                invoiceUniqueHandle: invoiceUniqueHandle,
                calloutBody: JSON.stringify(bodyForCallout)
            }).then(
                data => {
                    if (data === "200") {
                        this.showToast('Success', 'Offline manual settle successful.', 'success');
                        this.refreshPaymentData(false);
                    } else {
                        this.showToast('Error', 'Error doing offline manual settle.', 'error');
                    }

                }
            ).catch(e => {
                console.error("🚀️ Error in ~ OfflineManualSettlePayment ~ () :", JSON.stringify(e.message));
                this.showToast('Error', 'Error doing offline manual settle.', 'error');
            });
        }
        else {
            console.error('There is something wrong with invoice unique handle or stringified callout body. ');
            this.showToast('Error', 'Payment record or Invoice Handle not found.', 'error');
        }
    }

    showToast(title, message, variant = 'info', mode = 'dismissable') {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            })
        );
    }

    syncAutoRefreshState() {
        if (this.showRefreshControls) {
            this.startAutoRefresh();
        } else {
            this.stopAutoRefresh();
        }
    }

    startAutoRefresh() {
        this.stopAutoRefresh();
        if (!this.showRefreshControls) {
            return;
        }
        this.autoRefreshCountdown = this.autoRefreshIntervalSeconds;
        this.autoRefreshTimer = window.setInterval(() => {
            if (this.autoRefreshCountdown > 1) {
                this.autoRefreshCountdown -= 1;
            } else {
                this.refreshPaymentData(false);
                this.autoRefreshCountdown = this.autoRefreshIntervalSeconds;
            }
        }, 1000);
    }

    resetAutoRefresh() {
        this.syncAutoRefreshState();
    }

    stopAutoRefresh() {
        if (this.autoRefreshTimer) {
            window.clearInterval(this.autoRefreshTimer);
            this.autoRefreshTimer = null;
        }
        this.autoRefreshCountdown = 0;
    }
}