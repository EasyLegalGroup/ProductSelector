import {api, LightningElement, track, wire} from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import customStyles from '@salesforce/resourceUrl/createPaymentButton';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getAllThePricebooksAndProducts_Apex from '@salesforce/apex/DFJProductService_Class.getAllThePricebooksAndProducts_Apex';
import deleteRecord_Apex from '@salesforce/apex/DFJProductService_Class.deleteRecord_Apex';
import updateRecord_Apex from '@salesforce/apex/DFJProductService_Class.updateRecord_Apex';
import insertRecords_Apex from '@salesforce/apex/DFJProductService_Class.insertRecords_Apex';
import {MessageContext, subscribe} from 'lightning/messageService';
import payment_Status from '@salesforce/messageChannel/payment_Status__c';
import getOrderCategorySize from '@salesforce/apex/DFJProductService_Class.getOrderCategorySize'; 
import getPaymentRecords from '@salesforce/apex/PS_PaymentController.getPaymentRecordsForStatus'; // change kajal 


export default class Dfj_ProductSelectorCmp extends LightningElement {


    @track priceBooks = []; //PriceBook2
    @track productLineItems = [];
    @track fullProductData = [];
    @track currentProductList = [];
    @track isAddProductModalOpen = false;
    @track isAddDiscount=true;// change kajal 
    @track isDiscountInputVisible = false; // New track property
    @track showDiscountSuccess = false; // New track property
    @track isDeleteConfirmationModalOpen = false;
    @track deleteTabIndex;
    @track selectedPriceBookName;
    @track total = 0.00;
    @track isoCode;
    @track orderTotal = 0;
    @track fixedDiscountAmount = 0;
    @track productDiscount = 0;
    @track discountAmount = 0;
    @track isProductAvailable = false;
    @track isShowOrderTotal = false;
    @track disableButton = true; // kajal
    @track isLoadedSpinner = false;
    @track callProductBundleFlow = false;
    @track includeBundleDiscount = false;
    @track isShowDiscountModal = false;
    @track isShowDiscountCodeModal = false;
    @track isProductListDelete;
    @track isOpportunityObjectType = false;//Added by Kajal at 11.11
    isPaymentCreated = false;
    priceBookOptionsForCombobox = [];
    selectedPriceBookIdUsingCombobox;
    @track fieldApiMap = {
        Lead : {'Id':'Id','Discount':'Discount__c','UnitPrice':'Item_Price__c','Parent':'Lead__c','Name':'Name','Pricebook_Id__c':'Pricebook_Id__c','isSubscription':'Is_subscription__c','PlanHandle':'Plan_handle__c','CurrencyIsoCode':'CurrencyIsoCode','PriceBookEntry':'PricebookEntry_Id__c','ProductId':'Product_Id__c','ProductName':'Product_Name__c', 'Quantity':'Quantity__c','PartnerProvisionValue':'Partner_Provision_Value__c','PartnerSalesValue':'Partner_Sales_Value__c','ProvisionBase':'Provision_Base__c'},
        Opportunity : {'Id':'Id','TotalPrice':'TotalPrice','ListPrice':'ListPrice','UnitPrice':'UnitPrice','NetTotalPrice':'Net_Total_Price__c', 'Name':'Product2.Name','Pricebook_Id__c':'Pricebook_Id__c','isSubscription':'Is_subscription__c','PlanHandle':'Plan_handle__c','PriceBookEntry':'PricebookEntryId','ProductId':'Product2Id','Quantity':'Quantity','PartnerProvisionValue':'Partner_Provision_Value__c','PartnerSalesValue':'Partner_Sales_Value__c','ProvisionBase':'Provision_Base__c', 'CurrencyIsoCode':'Opportunity.CurrencyIsoCode'}
    }

    get isShowComboboxToSelectPricebook(){
        return !(Array.isArray(this.productLineItems) && this.productLineItems.length >= 1)
    }

    get isShowProductsInAddProductModal(){
        return Array.isArray(this.currentProductList) && this.currentProductList.length > 0;
    }

    get isPricebookSelectionDisabled(){
        return this.priceBookOptionsForCombobox.length === 1 ||
            Array.isArray(this.productLineItems) && this.productLineItems.length >= 1;
    }
    get flowInputVariables() {
         return [ {
            name: "recordId",
            type: "String",
            value: this.recordId
         } ];
    }

    @wire(MessageContext)
    messageContext;
    receivedMessage;
    subscription = null;

    _recordId;
    _objectAPIName;

    @api get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
    }
    
    @api get objectApiName(){
        return this._objectAPIName;
    }

    set objectApiName(value){
        this._objectAPIName = value;
    }

    connectedCallback() {
        loadStyle(this, customStyles)
            .then(() => {
                console.log('CSS loaded successfully');
            })
            .catch(error => {
                console.error('Error loading CSS: ', error);
            });
            //Added by Kajal at 11.11
        if(this._objectAPIName == 'Opportunity'){
            this.isOpportunityObjectType = true;
        }//End
        this.getAllProductsData();
        this.handleSubscribe();
        this.getOrderCategorySize();
        this.getPaymentRecords();//change kajal
    }

    //3. Handling the user input
    handleSubscribe() {
        if (this.subscription) {
            return;
        }
        //4. Subscribing to the message channel
        this.subscription = subscribe(
            this.messageContext,
            payment_Status,
            (message) => {
                this.handleMessage(message);
            }
        );
    }

    //change kajal
    getPaymentRecords()
    {
        console.log('--product payment fetched--');
        getPaymentRecords({recordId: this.recordId}).then((data)=>{
           console.log('--product payment fetched inside method--');
            const hasPayments = Array.isArray(data?.paymentList) && data.paymentList.length > 0;
            if(hasPayments){
                console.log('payment present, locking discount and create payment button');
                this.isAddDiscount = false;
            } else {
                this.isAddDiscount = true;
            }
            this.isPaymentCreated = hasPayments;
        }).catch((error)=>{
             console.error('Error fetching payment record--> ' + error);
        })
    }

    handlePaymentCanceled() {
    console.log('Payment canceled event received from child');
    this.isAddDiscount = true;
        this.isPaymentCreated = false;
        this.disableButton= true;
      }
    //

    getOrderCategorySize(){
        getOrderCategorySize({recordId: this.recordId, objectApiName: this._objectAPIName}).then((data) => {
            console.log('data size-->',data);
            
            if(data > 0){
                this.includeBundleDiscount = true;
                this.disableButton = true;
            }
        }).catch((error) => {
            console.error('Error fetching Order category definitions ' + error);
        });
    }

    //chnage kajal 
    handlePaymentCreated(event) {
    console.log('Payment created notification received:', event.detail);
    this.disableButton = true;
    this.isPaymentCreated = true;
    this.isAddDiscount=false;
    this.getAllProductsData();

    
    
    const paymentStatusCmp = this.template.querySelector('c-dfj_-payment-status');
    if (paymentStatusCmp) {
      paymentStatusCmp.refreshPaymentData();    }
}

    handlePaymentFound(event) {
        console.log('Payment found notification received');
        this.isPaymentCreated = true;
        this.disableButton = true;
    }

    handlePaymentMissing() {
        console.log('Payment missing notification received');
        this.isPaymentCreated = false;
    }

//change kajal 

    handleMessage(message) {
        this.receivedMessage = message
            ? JSON.stringify(message, null, "\t")
            : "no message";

        let receiveData = JSON.parse(this.receivedMessage);
        let disableButton;
        if (receiveData.leadId === this.recordId) {
            disableButton = receiveData.disableButton;
            this.disableButton = true; // kajal
        }
        disableButton = receiveData.disableButton;
        this.disableButton = true; // kajal
        this.getAllProductsData();
    }

    handleSelectionOfPricebook(event) {
        this.selectedPriceBookIdUsingCombobox = event.target.value;
        // Find the label for the selected value
        const selectedOption = this.priceBookOptionsForCombobox.find(opt => opt.value === this.selectedPriceBookIdUsingCombobox);
        this.selectedPriceBookName = selectedOption ? selectedOption.label : '';
        this.fullProductData.forEach(ele => {
            if (this.selectedPriceBookIdUsingCombobox === ele.pb2?.Id) {
                this.currentProductList = ele.pbeList;
            }
        });
    }

    get isPricebookNotSelected(){
        return !this.selectedPriceBookIdUsingCombobox;
    }

    async getAllProductsData() {
        await getAllThePricebooksAndProducts_Apex({recordId: this.recordId, objectApiName: this._objectAPIName}).then(result => {
            try {
                if (result) {
                    let priceBooks = [];
                    if(Array.isArray(result.productData) && result.productData.length > 0){
                        result.productData.forEach(element => {
                            element.pbeList && element.pbeList.forEach(elein => {
                                elein.quantity = 0;
                            })
                            priceBooks.push(element.pb2);
                        })
                        this.fullProductData = result.productData; 
                    }
                    this.priceBooks = priceBooks;
                    let objFields = this.fieldApiMap[this._objectAPIName];
                    this.productLineItems = [];
                    result.childProductData.forEach(prod=>{
                        let obj = {};
                        for (let field in objFields){
                            let innerKeys = objFields[field].split('.');
                            let currentValue = prod;
                            innerKeys.forEach(key =>{
                                currentValue = currentValue[key];
                            });
                            obj[field] = currentValue;
                        }
                        this.productLineItems.push(obj);
                    })
                    this.isoCode = result.DefaultCurrencyIsoCode;
                    this.refreshLeadProducts();
                    if (result.childProductData && result.childProductData.length <= 0) {
                        this.disableButton = true;
                    }
                    let priceBookId = '';
                    if(this._objectAPIName === 'Lead'){
                        this.fixedDiscountAmount = result.currentRecord[0].Fixed_discount_Type__c;
                    }
                    else if(this._objectAPIName === 'Opportunity'){
                        this.fixedDiscountAmount = result.currentRecord[0].Fixed_Discount_Type__c;
                    }
                    this.discountAmount = this.fixedDiscountAmount;
                    if (result.childProductData && result.childProductData.length > 0) {
                        this.isProductAvailable = true;
                        this.isShowOrderTotal = true;
                        priceBookId = result.childProductData[0].Pricebook_Id__c;
                        this.selectedPriceBookIdUsingCombobox = priceBookId;
                        let fullProductData = this.fullProductData;
                        this.currentProductList = [];
                        fullProductData.forEach(ele => {
                            if (priceBookId === ele.pb2.Id) {
                                this.selectedPriceBookName = ele.pb2.Name;
                                this.currentProductList = ele.pbeList;
                            }
                        });
                        this.handlerChangeQuantity();
                        this.handlerFixedDiscountChange();
                    } else {
                        this.whenProductLineEmpty();
                    }
                }
            } catch (error) {
                console.error('error Message-->',error);
            }
        })
    }

    whenProductLineEmpty(){
        this.isProductAvailable = false;
        this.priceBookOptionsForCombobox = this.priceBooks.map(ele => {
            return {label: ele.Name, value: ele.Id}
        });
        if (this.priceBookOptionsForCombobox.length === 1) {
            this.selectedPriceBookIdUsingCombobox = this.priceBookOptionsForCombobox[0].value;
            if (Array.isArray(this.fullProductData) && this.fullProductData.length > 0) {
                this.selectedPriceBookName = this.fullProductData[0].pb2.Name;
                this.currentProductList = this.fullProductData[0].pbeList;
            }
        }
    }

    /**Used for Delete Record when Click on Delete Action Icon or Empty Basket Button */
    deleteRecord(event) {
        let index = event.target.dataset.index;
        this.deleteTabIndex = index;
        this.isProductListDelete = index === undefined ? true : false;
        this.isDeleteConfirmationModalOpen = true;

    }

    deleteRecordWhenButtonClicked(event) {
        this.isDeleteConfirmationModalOpen = false;
        this.isLoadedSpinner = true;
        try {
            if(this.includeBundleDiscount){
                this.disableButton = true;
            }
            let productList = this.productLineItems;

            let tabindex = this.deleteTabIndex;
            let recordIds = [];
            if(this.isProductListDelete){
                productList.forEach(ele=>{
                    recordIds.push(ele.Id);
                })
            }
            else{
                recordIds.push(productList[tabindex].Id);
            }
            deleteRecord_Apex({recordIds: recordIds, objectApiName: this._objectAPIName}).then(result => {
                if (result) {
                    if(result === 'Products Deleted Successfully'){
                        if (this.isProductListDelete) {
                            productList = [];
                        } else {
                            productList.splice(tabindex, 1);
                        }
                        this.productLineItems = productList;
                        this.handlerChangeQuantity(); //get value from change quantityhelper 
                        this.changeTotalvalue_Helper();
                        this.handlerFixedDiscountChange();
                        this.showSuccessToast('Products Deleted', result, 'success');
                    }
                    else{
                        this.showSuccessToast('Something went wrong', result, 'error');
                    }
                    this.isLoadedSpinner = false;
                }
                if (this.productLineItems.length === 0) {
                    this.currentProductList = [];
                    this.whenProductLineEmpty();
                    this.handlerRefershView();
                }
                eval("$A.get('e.force:refreshView').fire()");
                this.disableButton = true; // kajal
            })
        } catch (error) {
            console.error(error);
        }
    }

    /**Used for close Modal*/
    closeModal(event) {
        try {
            if (event.target.name === 'cancelButtonOnAddProductModal') {
                this.currentProductList.forEach(item =>{
                    item.quantity = 0
                })
            }
            // Close All Product Modal
            this.isAddProductModalOpen = false;
            // Close Delete Confirmation Modal
            this.isDeleteConfirmationModalOpen = false;
            // Close Add Discount Modal
            this.isShowDiscountModal = false;
            // Close Discount Code Modal
            this.isShowDiscountCodeModal = false;
        } catch (error) {
            console.error(error);
        }
    }

    /**Used for Open Modal POP up on Click on Add Payment button */
    addProductModal() {
        this.isAddProductModalOpen = true;
        if ( Array.isArray(this.priceBookOptionsForCombobox) && this.priceBookOptionsForCombobox.length > 1 && Array.isArray(this.productLineItems) && this.productLineItems.length === 0) {
            this.selectedPriceBookIdUsingCombobox = null;
            this.selectedPriceBookName = null;
            this.currentProductList = [];
        }
    }

    addProductsToLeadProducts() {
       if(this.includeBundleDiscount){
            this.disableButton = true;
        }
        this.isAddProductModalOpen = false;
        this.isLoadedSpinner = true;
        try {
            let productsList = [...this.currentProductList];
            let productLines = [...this.productLineItems];
            let lineItemProductIdList = [];
            let finalProductsList = [];
            if (productLines && productLines.length) {
                productLines.forEach(ele => {
                    lineItemProductIdList.push(ele.ProductId);
                });
            }
            if (productLines && !productLines.length) {
                productsList.forEach(ele => {
                    if ((parseInt(ele.quantity) > 0)) {
                        let productInstance = {};
                        if(this._objectAPIName === 'Lead'){
                            productInstance.Lead__c = this.recordId;
                            productInstance.Product_Name__c = ele.Name;
                            productInstance.Quantity__c = ele.quantity;
                            productInstance.Product_Id__c = ele.Product2Id;
                            productInstance.Item_Price__c = ele.UnitPrice;
                            productInstance.Discount__c = 0;
                            productInstance.Name = ele.Name;
                        }
                        else if(this._objectAPIName === 'Opportunity'){
                             productInstance.OpportunityId = this.recordId;
                             productInstance.PricebookEntryId = ele.Id;
                             productInstance.Quantity = ele.quantity;
                             productInstance.Product2Id = ele.Product2Id;
                             productInstance.UnitPrice = ele.UnitPrice;
                             productInstance.ListPrice = ele.UnitPrice;
                             productInstance.Discount = 0;
                        }
                        productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                        productInstance.PricebookEntry_Id__c = ele.Id;
                        productInstance.Partner_Provision_Value__c = ele.Partner_provision_value__c;
                        productInstance.Partner_Sales_Value__c = ele.Partner_sales_value__c;
                        productInstance.Provision_Base__c = ele.Provision_base__c;
                        productInstance.CurrencyIsoCode = ele.Pricebook2.CurrencyIsoCode;
                        productInstance.Plan_handle__c = ele.Product2.Plan__c;
                        productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;
                        finalProductsList.push(productInstance);
                    }
                });
            } else {
                productsList.forEach(ele => {
                    let objFields = this.fieldApiMap[this._objectAPIName];
                    if ((parseInt(ele.quantity) > 0)) {
                        if (lineItemProductIdList.includes(ele.Product2Id)) {
                            let productLineItem = productLines.find(prod => prod.ProductId === ele.Product2Id);
                            productLineItem.Quantity = parseInt(ele.quantity) + parseInt(productLineItem.Quantity);
                            let obj = {};
                            for (let key in objFields){
                                obj[objFields[key]] = productLineItem[key];
                            }
                            finalProductsList.push(obj);
                        } else {
                            lineItemProductIdList.push(ele.Product2Id);
                            let productInstance = {};
                            if(this._objectAPIName === 'Lead'){
                                productInstance.Discount__c = 0;
                                productInstance.Item_Price__c = ele.UnitPrice;
                                productInstance.Product_Id__c = ele.Product2Id;
                                productInstance.Lead__c = this.recordId;
                                productInstance.Product_Name__c = ele.Name;
                                productInstance.Quantity__c = ele.quantity;
                                productInstance.Name = ele.Name;
                            }
                            else if(this._objectAPIName === 'Opportunity'){
                                productInstance.OpportunityId = this.recordId;
                                productInstance.PricebookEntryId = ele.Id;
                                productInstance.Quantity = ele.quantity;
                                productInstance.Product2Id = ele.Product2Id;
                                productInstance.UnitPrice = ele.UnitPrice;
                                productInstance.ListPrice = ele.UnitPrice;
                                productInstance.Discount = 0;
                            }
                            productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                            productInstance.PricebookEntry_Id__c = ele.Id;
                            productInstance.Partner_Provision_Value__c = ele.Pricebook2.partner_provision_value__c;
                            productInstance.Partner_Sales_Value__c = ele.Pricebook2.partner_sales_value__c;
                            productInstance.Provision_Base__c = ele.Pricebook2.Provision_base__c;
                            productInstance.CurrencyIsoCode = ele.Pricebook2.CurrencyIsoCode;
                            productInstance.Plan_handle__c = ele.Product2.Plan__c;
                            productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;
                            finalProductsList.push(productInstance);
                        }
                    }
                });
            }
            if(this.productLineItems && this.productLineItems.length){
                this.selectedPriceBookName = this.fullProductData.find(ele => ele.pb2.Id === this.productLineItems[0].Pricebook_Id__c)?.pb2.Name;
            }
            productsList && productsList.forEach(elein => {
                elein.quantity = 0;
            });
            this.currentProductList = productsList;
            

            
            insertRecords_Apex({
                newProductList: finalProductsList,
                recordId: this.recordId,
                total: this.total,
                objectApiName : this._objectAPIName
            }).then(result => {
                if (result) {
                    this.productLineItems = [];
                    let objFields = this.fieldApiMap[this._objectAPIName];
                    result.forEach(prod=>{
                        let obj = {};
                        for (let field in objFields){
                            let innerKeys = objFields[field].split('.');
                            let currentValue = prod;
                            innerKeys.forEach(key =>{
                                currentValue = currentValue[key];
                            });
                            obj[field] = currentValue;
                        }
                        this.productLineItems.push(obj);
                    })
                    this.refreshLeadProducts();
                    this.isProductAvailable = true;
                    this.isShowOrderTotal = true;
                    this.isLoadedSpinner = false;
                    this.showSuccessToast('Record Inserted', this._objectAPIName+' Product has been Inserted', 'success');
                    this.handlerChangeQuantity();
                    this.changeTotalvalue_Helper();
                    this.handlerFixedDiscountChange();
                    this.disableButton = true; // kajal
                }
                 if(this.includeBundleDiscount){
                    this.disableButton = true;
                }
                eval("$A.get('e.force:refreshView').fire()");
            })
            } catch (error) {
                console.error(error);
            }
    }

    /**method used for set fixeddiscounttype value in Lead */
    handlerFixedDiscountInput(event) {
        try {
            this.discountAmount = !event.target.value ? 0 : event.target.value;
        } catch (error) {
            console.error(error);
        }
    }

    handlerFixedDiscountChange() {
        try {
            let orderTotal = 0;
            let totalValue = this.total;
            let productDiscount = this.productDiscount;
            let fixedDiscount = this.fixedDiscountAmount;
            if (totalValue <= fixedDiscount+productDiscount ) {
                this.ordertotal = orderTotal;
            } else {
                orderTotal = parseFloat((parseFloat(totalValue).toFixed(2) - parseFloat(fixedDiscount).toFixed(2) - parseFloat(productDiscount).toFixed(2))).toFixed(2);
            }
            this.orderTotal = orderTotal;
        } catch (error) {
            console.error(error);
        }
    }

    //Fixed Discount Amount Handler
    handlerFixedDiscount(event) {
        this.isShowDiscountModal = false;
        this.isLoadedSpinner = true;
       if(this.includeBundleDiscount){
            this.disableButton = true;
        }
        try {
            let fieldValueMap;
            let fixedDiscount = Number(parseFloat(this.discountAmount).toFixed(2));
            if(this._objectAPIName === 'Lead'){
                fieldValueMap = {
                    'Fixed_discount_Type__c': fixedDiscount
                };
            }
            else if(this._objectAPIName === 'Opportunity'){
                fieldValueMap = {
                    'Fixed_Discount_Type__c': fixedDiscount
                }
            }
            updateRecord_Apex({recordId: this.recordId, fieldValuesMap: fieldValueMap, objectApiName: this._objectAPIName}).then(result => {
                if (result) {
                    this.fixedDiscountAmount = fixedDiscount;
                    console.log('fixed changed discount-->',this.fixedDiscountAmount);
                    this.handlerFixedDiscountChange();
                    this.showSuccessToast('Discount Applied', 'Fixed Amount Discount Applied Successfully', 'success');
                    eval("$A.get('e.force:refreshView').fire()");
                }
                this.isLoadedSpinner = false;
            }).catch((error) => {
                console.error("some error in code:", error);
            });
        } catch (error) {
            console.error(error);
        }
    }

    /**method used for increase and decrease the value of Amount */
    increaseDecreaseButton(event) {

        try {
            let productsList = this.currentProductList;
            let tabIndex = event.target.dataset.index;
            let buttonName = event.target.name;

            if (productsList[tabIndex].quantity < 0) {
                productsList[tabIndex].quantity = 0;
            }
            if (buttonName === 'add') {
                productsList[tabIndex].quantity = parseInt(productsList[tabIndex].quantity) + 1;
            } else if (buttonName === 'subtract') {
                if (!productsList[tabIndex].quantity < 1) {
                    productsList[tabIndex].quantity = parseInt(productsList[tabIndex].quantity) - 1;
                }
            }
            this.currentProductList = productsList;
        } catch (error) {
            console.error(error);
        }
    }

    changeIntValue(event) {
        try {
            let currentProductList = this.currentProductList;
            let tabIndex = event.target.name;
            currentProductList[tabIndex].quantity = parseInt(currentProductList[tabIndex].quantity);
            if (currentProductList[tabIndex].quantity <= 0) {
                currentProductList[tabIndex].quantity = 1;
            } else if (currentProductList[tabIndex].quantity >= 999) {
                currentProductList[tabIndex].quantity = 999;
            }
            this.currentProductList = currentProductList;
        } catch (ex) {
            console.error('Exception in changing quantity--' + ex);
        }
    }

    handlerChangeQuantity() {
        try {
            let totalPrice = 0;
            let newProductList = this.productLineItems;
            let productDiscount = 0;
            newProductList.forEach(function (ele) {
                if(ele.UnitPrice < 0){
                    productDiscount = parseFloat(productDiscount) + ele.UnitPrice.toFixed(2)*parseInt(ele.Quantity);
                }
                // Check if the smaller than 0 change it to 1
                ele.Quantity = parseInt(ele.Quantity);
                if (ele.Quantity <= 0) {
                    ele.Quantity = 1;
                } else if (ele.Quantity >= 999) {
                    ele.Quantity = 999;
                }
                // Description : Removing = from check so value like 0.5 could be considered
                if (!ele.Discount || isNaN(ele.Discount) || ele.Discount < 0) {
                    ele.Discount = 0;
                } else if (ele.Discount >= 100) {
                    ele.Discount = 100;
                }
                // Description : Allow fractional numbers on line item products discount. calculating the discount value and then parse to float.
                let discountedValue = parseFloat((ele.Discount / 100) * (ele.UnitPrice)).toFixed(2);
                ele.totalPrice = parseFloat((parseFloat(ele.UnitPrice).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * ele.Quantity).toFixed(2);
                totalPrice = parseFloat(totalPrice) + (parseFloat(ele.totalPrice) > 0 ? parseFloat(ele.totalPrice) : 0);
                /*checking whether the partner provision value is null or undefined or Nan*/
                if (ele.PartnerProvisionValue || isNaN(ele.PartnerProvisionValue)) {
                    ele.PartnerProvisionValue = 0;
                }
                /*checking whether the provision base is null or undefined or Nan*/
                if (ele.ProvisionBase || isNaN(ele.ProvisionBase)) {
                    ele.ProvisionBase = 0;
                }
                /*checking whether the partner sales value is null or undefined or Nan*/
                if (ele.PartnerSalesValue || isNaN(ele.PartnerSalesValue)) {
                    ele.PartnerSalesValue = 0;
                }
            });
            this.productDiscount = Math.abs(productDiscount);
            this.total = totalPrice.toFixed(2);
            this.productLineItems = newProductList;
        } catch (ex) {
            console.info("Error:-->" + ex.message);
        }
    }

    changeTotalvalue_Helper() {
        let fieldValueMap;
        if(this._objectAPIName === 'Lead'){
            fieldValueMap = {
                'telegenta__Forecast__c': this.total == null ? 0 : this.total
            };
        }
        else if(this._objectAPIName === 'Opportunity'){
            fieldValueMap = {
                'Order_Total__c': this.total == null ? 0 : this.total,
                'Fixed_Discount_Type__c': this.discountedValue ? 0 : this.discountedValue
            };
        }
        updateRecord_Apex({recordId: this.recordId, fieldValuesMap: fieldValueMap, objectApiName: this._objectApiName}).then(result => {
            if (result) {
                eval("$A.get('e.force:refreshView').fire()");
            }
            eval("$A.get('e.force:refreshView').fire()");
        })
    }

    handlerRefershView() {
        this.isProductAvailable = false;
        this.isShowOrderTotal = false;
        this.disableButton = true;
    }

    // Show Toast Message
    showSuccessToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        });
        this.dispatchEvent(evt);
    }

    // Handle Add Discount Modal
    handleAddDicountModal(){
        // this.isShowDiscountModal = true; // Old logic
        this.isDiscountInputVisible = true; // New logic
        this.disableButton= true; // kajal
        this.discountAmount = null; // Clear the input value
        console.log('fixedDiscountAmount-->',this.fixedDiscountAmount);
        // Focus logic can be handled in renderedCallback if needed, or just rely on autofocus
        setTimeout(() => {
            const input = this.template.querySelector('.discount-input');
            if (input) {
                input.focus();
            }
        }, 0);
    }

    handleDiscountInputKeydown(event) {
        if (event.keyCode === 13) { // Enter key
            this.saveDiscount();
        }
    }

    @track discountButtonClass = 'slds-m-right_medium fixed-button gray-button';

    saveDiscount() {
        this.isLoadedSpinner = true;
        if(this.includeBundleDiscount){
             this.disableButton = true;
         }
         try {
             let fieldValueMap;
             let fixedDiscount = Number(parseFloat(this.discountAmount).toFixed(2));
             if(this._objectAPIName === 'Lead'){
                 fieldValueMap = {
                     'Fixed_discount_Type__c': fixedDiscount
                 };
             }
             else if(this._objectAPIName === 'Opportunity'){
                 fieldValueMap = {
                     'Fixed_Discount_Type__c': fixedDiscount
                 }
             }
             updateRecord_Apex({recordId: this.recordId, fieldValuesMap: fieldValueMap, objectApiName: this._objectAPIName}).then(result => {
                 if (result) {
                     this.fixedDiscountAmount = fixedDiscount;
                     console.log('fixed changed discount-->',this.fixedDiscountAmount);
                     this.handlerFixedDiscountChange();
                     
                     // Success Indicator Logic
                     this.isDiscountInputVisible = false;
                     this.showDiscountSuccess = true;
                     
                     // Add fade animation class
                     this.discountButtonClass = 'slds-m-right_medium fixed-button gray-button fade-success';
                     
                     setTimeout(() => {
                         this.showDiscountSuccess = false;
                         this.discountButtonClass = 'slds-m-right_medium fixed-button gray-button';
                     }, 1500); // Increased timeout for better visibility

                     eval("$A.get('e.force:refreshView').fire()");
                 }
                 this.isLoadedSpinner = false;
             }).catch((error) => {
                 console.error("some error in code:", error);
                 this.isLoadedSpinner = false;
             });
         } catch (error) {
             console.error(error);
             this.isLoadedSpinner = false;
         }
    }

    //Handle Add Discount Code Modal
    handleAdddiscountCodeModal(){
        this.isShowDiscountCodeModal = true;
    }

    // Handle Calculate Discount Flow
    handleCalculateBundle() {
        this.callProductBundleFlow = true;
        this.disableButton = true; // kajal
    }

    // Handle Calculate Discount Flow Stage Change
    handleStatusChange(event) {
        if(event.detail.status === 'FINISHED'){
            this.callProductBundleFlow = false;
            this.getAllProductsData();
            this.disableButton = false; // kajal
        }
    }

    refreshLeadProducts() {
            this.productLineItems.sort((a, b) => {
            const aIsPositive = a.UnitPrice >= 0;
            const bIsPositive = b.UnitPrice >= 0;
            if (aIsPositive && !bIsPositive) return -1;
            if (!aIsPositive && bIsPositive) return 1;
            return a.Name.localeCompare(b.Name);
        });
    }

}