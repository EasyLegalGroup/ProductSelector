import { LightningElement, api, track } from 'lwc';
import createPaymentRecord from '@salesforce/apex/PS_PaymentController.createPaymentRecord';
//DFJ-80
import createPaymentRecordOnAccount from '@salesforce/apex/PS_PaymentController.createPaymentRecordOnAccount';
import showPaymentStatusOnAccount from '@salesforce/apex/PS_PaymentController.showPaymentStatusOnAccount';

//End
import makeCalloutToCreateCustomerInvoice from '@salesforce/apex/PS_PaymentController.makeCalloutToCreateCustomerInvoice';
import getAddressInfoFromLeadOROrder from '@salesforce/apex/PS_PaymentController.getAddressInfoFromLeadOROrder';
import getAddressInfoFromAccount from '@salesforce/apex/PS_PaymentController.getAddressInfoFromAccount';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PS_EnhancedCreatePayment extends LightningElement {
    @api recordId;
    @api disableButton;// false
    @api objectApiName;
    //DFJ-80
    @api orderProducts = [];
    @api orderRecord =  {};
    openConfirmationModelOnAccount = false;
    @api orderFixedDiscount = 0;
    @api isSuccess = false;
    openPaymentStatusModalOnAccount = false;
    @api selectedJournal='';
    addressInfo = {};
    accountInfo = {};
    //End
    @track openConfirmationModelOnLead = false;
    @track isLoadedSpinner = false;
    @track openConfirmationModelOnOrder = false;
    @track buttonLabel= 'Yes';
    @track secondButtonLabel = 'No'
   
    @track modelContent = '';
    @track disableOkButton = false;
    @track makeCallOut = false;
    @track paymentOrderLines = [];
    @track subscriptionLeadProducts = [];
    @track subscriptionOrderItemProducts = [];
    @track payment = {};
    @track showCreatePaymentButton = true;
 

   
    @track buttonLabelOnOrder = 'Ok';
    @track leadAddressInfo = {};
    @track leadProducts =[]
    @track leadProductList = [];
    @track subscriptionIncluded = 'No subscription included';
    @track orderTotal = 0;
    @track totalPrice = 0;
    @track orderSubtotal = 0;
    @track proceedWithPaymentOnOrder = true;
    @track isoCode;
    

    openModel(event){
        try {
        let buttonLabal = event.target.label ;
        //Changes DIN-385 Start
        // TODO : Address not updating if lead address is already there but wants to update address
        if(buttonLabal == 'Create Payment'){ 
            if(this.objectApiName == 'Order'){
                this.openConfirmationModelOnOrder = true;
                this.modelContent = 'Click ok to create the payment and invoice record.';
            }
            else if(this.objectApiName != 'Order' && this.objectApiName != 'Account'){
                this.isLoadedSpinner = true;
                this.getAddressInfoFromLeadOROrder_helper();
                this.openConfirmationModelOnLead = true; 
            }else if(this.objectApiName == 'Account' && this.objectApiName != 'Order' && this.objectApiName != 'Lead'){
                this.isLoadedSpinner = true;
                this.getAddressInfoFromAccount_helper();
                this.openConfirmationModelOnAccount = true; 

            }
        }
        
    } catch (error) {
        console.error(error);  
    }
    
}
//Changes starts DFJ-80
getAddressInfoFromAccount_helper(){
    getAddressInfoFromAccount({recordId : this.recordId ,selectedJournal : this.selectedJournal}).then(result=>{
       

        this.addressInfo = {};
        this.accountInfo = {};
        this.leadProducts = [];
        this.orderTotal = 0;
        this.isLoadedSpinner = false;
        
        if(result && !result.errorMessage && result.accountInfo){
                this.accountInfo = result.accountInfo; 
                if(result.addressInfo){
                    if(result.sObjectName ==='df_journal_dk__c'){
                        this.addressInfo.Street = result.addressInfo.person_1_address__c;
                        this.addressInfo.City = result.addressInfo.person_1_city__c;
                        this.addressInfo.PostalCode = result.addressInfo.person_1_zip_code__c;
                    }else if(result.sObjectName ==='df_journal_se_new__c'){
                        this.addressInfo.Street = result.addressInfo.adress_person1__c;
                        this.addressInfo.City = result.addressInfo.stad_person1__c;
                        this.addressInfo.PostalCode = result.addressInfo.postnummer_person1__c;
                    }else if(result.sObjectName ==='df_160_person__c'){
                        this.addressInfo.Street = result.addressInfo.person_adresse__c;
                        this.addressInfo.City = result.addressInfo.person_by__c;
                        this.addressInfo.PostalCode = result.addressInfo.person_postnummer__c;
                    }
                    
                }
                
            
                this.leadProductList = this.orderProducts;
               
                this.isoCode = result.DefaultCurrencyIsoCode;
                this.orderProducts.forEach(element => {
                    if(element.Is_subscription__c){
                        this.subscriptionIncluded = 'Subscription product is included';
                    }
                });

                this.leadProducts =  this.orderProducts;
                this.changeQuantityOnAccount_helper();
                this.calculateOrderSubtotal();

        }else{
                this.openConfirmationModel = false; 
                this.ShowToastEvent(result && result.errorMessage ? result.errorMessage : 'Something went wrong','Error');
            }
            eval("$A.get('e.force:refreshView').fire()");
    })

}
changeQuantityOnAccount_helper() {
    try {
        let totalPrice = 0;
        let newProductList = this.leadProductList;
          //  let newProductList = this.leadProductList;
            newProductList.forEach(function(ele) {
              let  eleQuantity = parseInt(ele.Quantity);
                if (ele.Quantity <= 0) {
                    ele.Quantity = 1;
                } else if (ele.Quantity >= 999) {
                    ele.Quantity = 999;
                }
                let eleDiscount = parseFloat(ele.Discount__c);
                if (eleDiscount <= 0) {
                    eleDiscount = 0;
                } else if (eleDiscount >= 100) {
                    eleDiscount = 100;
                }
               let eleItemPrice = parseFloat(ele.UnitPrice);
                let discountedValue = parseFloat((eleDiscount / 100) * (ele.UnitPrice)).toFixed(2);
                let eleTotalPrice = parseFloat((parseFloat(eleItemPrice).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * eleQuantity).toFixed(2);
                //ele.totalPrice = eleTotalPrice;
                totalPrice = parseFloat(totalPrice) + parseFloat(eleTotalPrice);
            });
            let leadFixedDiscount = this.orderFixedDiscount;
         
            this.totalPrice = totalPrice;
            totalPrice = totalPrice >= leadFixedDiscount ? totalPrice - leadFixedDiscount : 0;
          
            this.leadProductList =  newProductList;
          
            this.orderTotal = totalPrice.toFixed(2);
          
      
    } catch (ex) {
        console.info("Error:-->" + ex.message);
    }
}

handleProceedPaymentOnAccount(){
    try{
        let orderItemsList =  this.orderProducts;
      
        const updatedOrderItemsList = orderItemsList.map((obj) => {
        const { isEditable, totalPrice, ...orderItems } = obj;
        return orderItems;
        });
  
     createPaymentRecordOnAccount({recordId : this.recordId, orderRecord :this.orderRecord, orderProductList : JSON.stringify(updatedOrderItemsList), orderFixedDisc : this.orderFixedDiscount, totalOrder : this.orderTotal, selectedJournal : this.selectedJournal }).then(result=>{
             if(result && result.successMessage && !result.errorMessage){
                 this.payment = result.payment;
                 this.paymentOrderLines = result.paymentOrderLines;
                 this.subscriptionOrderItemProducts = result.subscriptionOrderItemProducts;
                 this.makeCallOut = true;
                 this.calloutChangesHandler();
                 this.ShowToastEvent(result.successMessage,'Success');
            }else{
                this.ShowToastEvent(result && result.errorMessage ? result.errorMessage : 'Something went wrong','Error');
            }
            this.disableOkButton = false;
            this.buttonLabelOnOrder = 'Ok';
            this.openConfirmationModelOnLead = false;
            this.openConfirmationModelOnOrder = false;
           
         }) 
    } catch (error) {
        console.error(error);
    }
}
//End

getAddressInfoFromLeadOROrder_helper(){
    
    getAddressInfoFromLeadOROrder({recordId : this.recordId}).then(result=>{
        
        this.leadAddressInfo = {};
        this.leadProducts = [];
        this.orderTotal = 0;
        this.isLoadedSpinner = false;
        
        if(result && !result.errorMessage && result.leadProductsList){
            
                this.leadAddressInfo = result.leadAddressInfo;
                this.leadProductList = result.leadProductsList;
               
                this.isoCode = result.DefaultCurrencyIsoCode;
                result.leadProductsList.forEach(element => {
                    if(element.Is_subscription__c){
                        this.subscriptionIncluded = 'Subscription product is included';
                    }
                });

                this.leadProducts =  result.leadProductsList;
                this.changeQuantity_helper();
                this.calculateOrderSubtotal();

            }else{
                this.openConfirmationModel = false; 
                this.ShowToastEvent(result && result.errorMessage ? result.errorMessage : 'Something went wrong','Error');
            }
            eval("$A.get('e.force:refreshView').fire()");
        })

   }

   calculateOrderSubtotal(){
    let orderSubtotalAmount = 0;
    if (this.leadProducts && this.leadProducts.length > 0) {
        this.leadProducts.forEach(ele => {
            orderSubtotalAmount += parseFloat(ele.totalPrice);
        });
    }
    this.orderSubtotal = orderSubtotalAmount;
   }

    closeModal(){
        this.leadAddressInfo = {};
        this.leadProducts = [];
        this.orderTotal = 0;
        this.openConfirmationModelOnLead = false;
        this.openConfirmationModelOnOrder = false;
        this.openConfirmationModelOnAccount = false;
       
    }
    
    handlePaymentRecordCreation(event){
        try {
            let buttonlabel = event.target.label;
            if(buttonlabel == 'Confirm' && this.leadAddressInfo.Email && this.leadAddressInfo.Name){
               
                this.openConfirmationModelOnLead = false; 
                this.handleProceedPayment();
            
            }else if(buttonlabel == 'Ok'){
                this.buttonLabelOnOrder = 'Running...';
                this.proceedWithPaymentOnOrder = false;
                this.disableOkButton = true;
                this.handleProceedPayment();
            }else if(this.objectApiName == 'Account'){//Changes DFJ-80
                if(buttonlabel == 'Confirm'){
                    this.handleProceedPaymentOnAccount();
                }else{
                    this.openConfirmationModelOnAccount = true; 
                    this.ShowToastEvent('Please make sure both name and email is filled out','Error');
                }//End
                
            }else{
                this.openConfirmationModelOnLead = true; 
                this.ShowToastEvent('Please make sure both name and email is filled out','Error');
            }
        } catch (error) {
            console.error(error);
        }
    }

    handleProceedPayment(){
        try{
         createPaymentRecord({recordId : this.recordId}).then(result=>{
                if(result && result.successMessage && !result.errorMessage){
                    this.payment = result.payment;
                    this.paymentOrderLines = result.paymentOrderLines;
                    this.subscriptionLeadProducts = result.subscriptionLeadProducts;
                    this.subscriptionOrderItemProducts = result.subscriptionOrderItemProducts;
                    this.makeCallOut = true;
                    this.calloutChangesHandler();
                    this.ShowToastEvent(result.successMessage,'Success');
                }else{
                    this.ShowToastEvent(result && result.errorMessage ? result.errorMessage : 'Something went wrong','Error');
                }
                this.disableOkButton = false;
                this.buttonLabelOnOrder = 'Ok';
                this.openConfirmationModelOnLead = false;
                this.openConfirmationModelOnOrder = false;
               
            }) 
        } catch (error) {
            console.error(error);
        }
    }

    calloutChangesHandler(){
        let makeCallOut = this.makeCallOut;
        if(makeCallOut){
            this.handleCallouts_helper();
        }
    }
    
    handleCallouts_helper(){
        let payment = this.payment;
        let paymentOrderLines = this.paymentOrderLines;
        let subscriptionLeadProducts = this.subscriptionLeadProducts.length <= 0 ? this.subscriptionOrderItemProducts : this.subscriptionLeadProducts;
        this.buttonLabelOnOrder = 'Running...';
        this.disableOkButton = true;
        makeCalloutToCreateCustomerInvoice({recordId : this.recordId, 
            payment : JSON.stringify(payment), 
            paymentOrderLines : JSON.stringify(paymentOrderLines),
            subscriptionLeadProducts : subscriptionLeadProducts  }).then(result=>{
        try {
            if (result && result.successMessage && !result.errorMessage) {
                this.ShowToastEvent(result.successMessage,'Success');
                this.showCreatePaymentButton = false;
               // this.payment = result.payment;
                if(this.objectApiName == 'Account'){
                    this.openConfirmationModelOnAccount = false;
                    this.showPaymentStatus();
                    // this.isSuccess = true;
                    // this.sendMessageToCreateOrder();
                }
            }else{
                console.log("🚀️ ~ PS_EnhancedCreatePayment ~  ~ result.errorMessage:", result.errorMessage);
                this.ShowToastEvent(result && result.errorMessage ? result.errorMessage : 'Something went wrong','Error');

            } 

            this.makeCallOut = false;
            this.disableOkButton = false;
            this.buttonLabelOnOrder = 'Ok';
            this.openConfirmationModelOnLead = false;
            this.openConfirmationModelOnOrder = false;
            
        } catch (error) {
            console.error(error);
        }
        })
    }
//Changes DFJ-80
sendMessageToCreateOrder() {
    const successEvent = new CustomEvent('successmessage', {
        detail: this.payment
    });
    this.dispatchEvent(successEvent);
}
 showPaymentStatus(){
   // this.openPaymentStatusModalOnAccount= true;
    let paymentId = this.payment.Id;
    showPaymentStatusOnAccount({recordId : paymentId}).then(result=>{
if(result){
    this.payment = result.payment;
   // this.openPaymentStatusModalOnAccount= true;
    this.sendMessageToCreateOrder();

}
    })

 }
//End
    ShowToastEvent(message , title)
    {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            messageTemplate: message,
            variant: title,
            mode: 'pester',
            duration : 5000
        });
        this.dispatchEvent(evt);
    }

    changeQuantity_helper(event) {
        try {
            let totalPrice = 0;
            let newProductList = this.leadProductList;
            newProductList.forEach(function(ele) {
             
                ele.Quantity__c = parseInt(ele.Quantity__c);
                if (ele.Quantity__c <= 0) {
                    ele.Quantity__c = 1;
                } else if (ele.Quantity__c >= 999) {
                    ele.Quantity__c = 999;
                }

                if (ele.Discount__c <= 0) {
                    ele.Discount__c = 0;
                } else if (ele.Discount__c >= 100) {
                    ele.Discount__c = 100;
                }
               
                let discountedValue = parseFloat((ele.Discount__c / 100) * (ele.Item_Price__c)).toFixed(2);
              
                ele.totalPrice = parseFloat((parseFloat(ele.Item_Price__c).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * ele.Quantity__c).toFixed(2);
                totalPrice = parseFloat(totalPrice) + parseFloat(ele.totalPrice);
            });
            let leadFixedDiscount = this.leadAddressInfo.Fixed_discount_Type__c;
         
            this.totalPrice = totalPrice;
            totalPrice = totalPrice >= leadFixedDiscount ? totalPrice - leadFixedDiscount : 0;
          
            this.leadProductList =  newProductList;
          
            this.orderTotal = totalPrice.toFixed(2);
          
        } catch (ex) {
            console.info("Error:-->" + ex.message);
        }
    }
    //End
}