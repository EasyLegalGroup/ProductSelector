import {api, LightningElement, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getAllThePricebooksAndLeadProducts_Apex
    from '@salesforce/apex/DFJ_ProductSelectorController_Apex.getAllThePricebooksAndLeadProducts_Apex';
import deleteRecordOfLeadProduct_Apex
    from '@salesforce/apex/DFJ_ProductSelectorController_Apex.deleteRecordOfLeadProduct_Apex';
import changeTotalSalesValue_Apex from '@salesforce/apex/DFJ_ProductSelectorController_Apex.changeTotalSalesValue_Apex';
import insertRecords_Apex from '@salesforce/apex/DFJ_ProductSelectorController_Apex.insertRecords_Apex';
import updateRecordOfLeadProduct_Apex
    from '@salesforce/apex/DFJ_ProductSelectorController_Apex.updateRecordOfLeadProduct_Apex';
import insertFixedDiscountinLead_Apex
    from '@salesforce/apex/DFJ_ProductSelectorController_Apex.insertFixedDiscountinLead_Apex';
import returnFixedDiscountValue_Apex
    from '@salesforce/apex/DFJ_ProductSelectorController_Apex.returnFixedDiscountValue_Apex';
import {MessageContext, subscribe} from 'lightning/messageService';
import payment_Status from '@salesforce/messageChannel/payment_Status__c';
import getOrderCategorySize from '@salesforce/apex/DFJ_ProductSelectorController_Apex.getOrderCategorySize';

export default class DFJ_EnhancedProductSelector extends LightningElement {


    @track priceBooks = []; //PriceBook2
    @track leadProducts = []; //LeadProducts__c
    @track fullProductData = [];
    @track currentProductList = [];
    @track isAddProductModalOpen = false;
    @track isDeleteConfirmationModalOpen = false;
    @track currentPriceBook;
    @track deleteTabIndex;
    @track editTabIndex;
    @track selectedPriceBookName;
    @track total = 0.00;
    @track totalValues = {};
    @track isoCode;
    @track orderTotal = 0;
    @track isEditModalOpen = false;
    @track editLeadProducts = [];
    @track passEditButtonVariable;
    @track discountValue;
    @track leadRecord = {};
    @track isleadProductAvailable = false;
    @track isleadProductComboboxdisplay = true;
    @track isShowOrderTotal = false;
    @track disableButton = false;
    @track isLoadedSpinner = false;
    @track leadProducts1 = [];
    @track callProductBundleFlow = false;//DFJ-340
    @track includeBundleDiscount = false;//DFJ-340
    // DFJ-330 Changes Start
    priceBookOptionsForCombobox = [];
    selectedPriceBookIdUsingCombobox;

    get isShowComboboxToSelectPricebook(){
        return !(Array.isArray(this.leadProducts) && this.leadProducts.length >= 1)
    }

    get isShowProductsInAddProductModal(){
        return Array.isArray(this.currentProductList) && this.currentProductList.length > 0;
    }

    get isPricebookSelectionDisabled(){
        return this.priceBookOptionsForCombobox.length === 1 ||
            Array.isArray(this.leadProducts) && this.leadProducts.length >= 1;
    }
  //DFJ-340 changes start
    get flowInputVariables() {
         return [ {
            name: "recordId",
            type: "String",
            value: this.recordId
         } ];
    }
      //DFJ-340 Changes end

    // DFJ-330 Changes End

    @wire(MessageContext)
    messageContext;
    receivedMessage;
    subscription = null;

    _recordId;

    @api get recordId() {    //recordIdusedforCurrentLead
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
    }

    connectedCallback() {
        this.getLeadProductsData();
        this.handleSubscribe();
        this.getOrderCategorySize();  //DFJ-340
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
  //DFJ-340 Changes start
    getOrderCategorySize(){
        getOrderCategorySize({leadId : this._recordId}).then((data) => {
            if(data > 0){
                this.includeBundleDiscount = true;
                this.disableButton = true;
            }
        }).catch((error) => {
            console.error('Error fetching Order category definitions ' + error);
        });
    }
 //DFJ-340 Changes End

    handleMessage(message) {
        this.receivedMessage = message
            ? JSON.stringify(message, null, "\t")
            : "no message";

        let receiveData = JSON.parse(this.receivedMessage);
        //console.log('receiveData',receiveData);
        let disableButton;
        if (receiveData.leadId === this.recordId) {
            disableButton = receiveData.disableButton;
            this.disableButton = disableButton;
        }
        disableButton = receiveData.disableButton;
        this.disableButton = disableButton;
        this.getLeadProductsData();
    }

    // handleUnsubscribe() {
    //   console.log("in handle unsubscribe");

    //   unsubscribe(this.subscription);
    //   this.subscription = null;
    // }

    // DFJ-330 changes start
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

    // DFJ-330 changes end

    get isPricebookNotSelected(){
        return !this.selectedPriceBookIdUsingCombobox;
    }

    async getLeadProductsData() {
        await getAllThePricebooksAndLeadProducts_Apex({leadId: this.recordId}).then(result => {
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

                    this.leadProducts = result.leadProducts;
                    this.isoCode = result.DefaultCurrencyIsoCode;
                    this.refreshLeadProducts();//DFJ-340
                    if (result.leadProducts && result.leadProducts.length <= 0) {

                        this.disableButton = true;

                    }

                    let priceBookId = '';
                    if (result.leadProducts && result.leadProducts.length > 0) {
                        //this.disableButton = false;

                        this.isleadProductAvailable = true;
                        this.isShowOrderTotal = true;
                        priceBookId = result.leadProducts[0].Pricebook_Id__c;

                        // DFJ-330 changes start
                        this.selectedPriceBookIdUsingCombobox = priceBookId;
                        // DFJ-330 changes end


                        let fullProductData = this.fullProductData;
                        fullProductData.forEach(ele => {
                            if (priceBookId === ele.pb2.Id) {
                                this.selectedPriceBookName = ele.pb2.Name;
                                this.currentProductList = ele.pbeList;
                            }
                        });
                        this.handlerChangeQuantity();
                    } else {
                        this.isleadProductAvailable = false;

                        // DFJ-330 changes start
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


                        // DFJ-330 changes end

                    }

                }

            } catch (error) {
                console.error(error);
            }

        })

        await returnFixedDiscountValue_Apex({leadId: this.recordId}).then(result => {
            if (result) {
                if (result[0].Fixed_discount_Type__c !== undefined) {
                    this.leadRecord.Fixed_discount_Type__c = result[0].Fixed_discount_Type__c;
                } else {
                    this.leadRecord.Fixed_discount_Type__c = 0;
                }

                this.handlerChangeQuantity();
                this.handlerFixedDiscountChange();
            }

        })
    }

    /**Used method for Open Modal popUp on Pencil Icon and Edit Fields(Amount , Discount) */

    editButtonClicked(event) {
        let leadproduct = this.leadProducts;
        this.isEditModalOpen = true;
        let selectedIndex = event.target.dataset.index;
        this.editTabIndex = selectedIndex;
        leadproduct[selectedIndex];
        this.editLeadProducts = leadproduct[selectedIndex];
    }

    handlerDiscountValueChange(event) {
        let totalPrice = 0.00;
        try {
            if (event.target.name === 'quantity') {
                this.editLeadProducts.Quantity__c = !event.target.value ? 0 : event.target.value;
                this.editLeadProducts.Quantity__c = parseInt(this.editLeadProducts.Quantity__c);
                if (event.target.value <= 0) {
                    this.editLeadProducts.Quantity__c = 1;
                    event.target.value = 0;
                } else if (event.target.value >= 999) {
                    this.editLeadProducts.Quantity__c = 999;
                    event.target.value = 999;
                }
            } else {
                this.editLeadProducts.Discount__c = !event.target.value ? 0 : event.target.value;
            }

            if (!this.editLeadProducts.Discount__c || isNaN(this.editLeadProducts.Discount__c ) || this.editLeadProducts.Discount__c < 0) {
                this.editLeadProducts.Discount__c = 0;
            } else if (this.editLeadProducts.Discount__c >= 100) {
                this.editLeadProducts.Discount__c = 100;
            }

            let discountedValue = parseFloat(
                ((this.editLeadProducts.Discount__c / 100) * (this.editLeadProducts.Item_Price__c)).toString()
            ).toFixed(2);
            this.editLeadProducts.totalPrice = parseFloat(
                (
                    parseFloat(this.editLeadProducts.Item_Price__c).toFixed(2) - parseFloat(discountedValue).toFixed(2)
                ) * this.editLeadProducts.Quantity__c
            ).toFixed(2);
            totalPrice = parseFloat(totalPrice) + parseFloat(this.editLeadProducts.totalPrice);
            this.editLeadProducts.totalPrice = totalPrice.toFixed(2);


        } catch (error) {
            console.error(error);
        }

    }

    //Used for save the value of discount on click of save button of the edit modal Pop
    saveButtonClicked() {
        let changedDiscount = this.editLeadProducts;
        changedDiscount.Discount__c = parseFloat(changedDiscount.Discount__c);
        updateRecordOfLeadProduct_Apex({changedDiscount: changedDiscount}).then(result => {
            this.isEditModalOpen = false;
            this.changeTotalvalue_Helper();
            this.handlerChangeQuantity();
            this.handlerFixedDiscountChange();
            this.showSuccessToast();
        })
            .catch((error) => {
                console.error("some error in code:", error);
            });
        eval("$A.get('e.force:refreshView').fire()");

        this.leadProducts.forEach(element => {
            if (element.Id === changedDiscount.Id) {
                element = changedDiscount;
            }
        });
        this.leadProducts = [...this.leadProducts];
        //DFJ-340 Changes Start
        if(this.includeBundleDiscount){
            this.disableButton = true;
        }
        //DFJ-340 Changes End
    }

    /**Used for Delete Record when Click on Delete Action Icon Button */
    deleteRecord(event) {
        let index = event.target.dataset.index;
        this.deleteTabIndex = index;
        this.isDeleteConfirmationModalOpen = true;

    }

    deleteRecordWhenButtonClicked(event) {
        try {
            //DFJ-340 Changes Start
            if(this.includeBundleDiscount){
                this.disableButton = true;
            }
            //DFJ-340 Changes End
            this.handlerChangeQuantity();
            let productList = this.leadProducts;

            let tabindex = this.deleteTabIndex;
            let productId = productList[tabindex].Id;
            //let productId = productList[selectedIndex].id;
            let total = this.total;
            deleteRecordOfLeadProduct_Apex({productId: productId, leadId: this.recordId}).then(result => {

                if (result) {
                    this.leadProducts = result;
                    //h.showSuccessToast(c, e, h);
                    this.handlerChangeQuantity(); //get value from change quantityhelper
                    //this.total = total;
                    this.currentPriceBook = '';
                    if (productList.length === 0) {
                        this.currentProductList = [];
                    }
                    this.changeTotalvalue_Helper();
                    this.handlerFixedDiscountChange();
                    this.showSuccessToast();
                }

                this.isDeleteConfirmationModalOpen = false;
                if (this.leadProducts.length === 0) {

                    this.handlerRefershView();  //usedforhidingthetemplateoftableandselectedpricebookcombobox
                }
                eval("$A.get('e.force:refreshView').fire()");

            })
        } catch (error) {
            console.error(error);
        }

    }

    /**Used for close Modal Pop Click on Pencil Icon Button */
    closeModal(event) {
        try {
            this.isEditModalOpen = false;
            if (event.target.name === 'cancelDiscount') {
                this.getLeadProductsData();
            }
            // DFJ-330 changes start
            if (event.target.name === 'cancelButtonOnAddProductModal') {
                this.isAddProductModalOpen = false;
                this.currentProductList.forEach(item =>{
                    item.quantity = 0
                })


            }
            // DFJ-330 changes end
            this.isDeleteConfirmationModalOpen = false;
        } catch (error) {
            console.error(error);
        }

    }

    /**Used for Open Modal POP up on Click on Add Payment button */
    addProductModal() {
        this.getLeadProductsData();
        this.isAddProductModalOpen = true;

        // DFJ-330 changes start
        if ( Array.isArray(this.priceBookOptionsForCombobox) && this.priceBookOptionsForCombobox.length > 1 && Array.isArray(this.leadProducts) && this.leadProducts.length === 0) {
            this.selectedPriceBookIdUsingCombobox = null;
            this.selectedPriceBookName = null;
            this.currentProductList = [];
        }
        // DFJ-330 changes end

        let leadProducts = [...this.leadProducts];
        if (leadProducts.length === 0) {
            this.isleadProductComboboxdisplay = true;
        } else if (leadProducts && leadProducts.length > 0) {
            this.isleadProductComboboxdisplay = false;
        } else {
            this.isleadProductComboboxdisplay = true;
        }
    }

    addProductsToLeadProducts() {
        //DFJ-340 Changes Start
       if(this.includeBundleDiscount){
            this.disableButton = true;
        }
        //DFJ-340 Changes end
        this.isAddProductModalOpen = false;
        this.isLoadedSpinner = true;
        try {
            let productsList = [...this.currentProductList];

            let LeadProducts = [...this.leadProducts]; // To insert all the lead products

            let leadProductIdList = []; // To insert all the lead products

            if (LeadProducts && LeadProducts.length > 0) {
                LeadProducts.forEach(ele => {
                    leadProductIdList.push(ele.Product_Id__c);
                });
            }

            if (LeadProducts && LeadProducts.length === 0) {
                productsList.forEach(ele => {
                    if ((parseInt(ele.quantity) > 0)) {

                        let productInstance = {};
                        productInstance.Discount__c = 0;
                        productInstance.Item_Price__c = ele.UnitPrice;
                        productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                        productInstance.Product_Id__c = ele.Product2Id;
                        productInstance.PricebookEntry_Id__c = ele.Id;
                        productInstance.Lead__c = this.recordId;
                        productInstance.Product_Name__c = ele.Name;
                        productInstance.Name = ele.Name;
                        productInstance.Partner_Provision_Value__c = ele.Partner_provision_value__c;
                        productInstance.Partner_Sales_Value__c = ele.Partner_sales_value__c;
                        productInstance.Provision_Base__c = ele.Provision_base__c;
                        productInstance.Quantity__c = ele.quantity;
                        productInstance.CurrencyIsoCode = ele.Pricebook2.CurrencyIsoCode;
                        productInstance.Plan_handle__c = ele.Product2.Plan__c;
                        productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;

                        LeadProducts.push(productInstance);

                    }
                });
            } else {
                productsList.forEach(ele => {
                    let flag = 0;
                    if ((parseInt(ele.quantity) > 0)) {
                        if (leadProductIdList.includes(ele.Product2Id)) {
                            LeadProducts.forEach(eleLp => {
                                if (eleLp.Product_Id__c === ele.Product2Id) {
                                    eleLp.Quantity__c = parseInt(ele.quantity) + parseInt(eleLp.Quantity__c);
                                }
                            });
                        } else {
                            leadProductIdList.push(ele.Product2Id);
                            let productInstance = {};
                            productInstance.Discount__c = 0;
                            productInstance.Item_Price__c = ele.UnitPrice;
                            productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                            productInstance.Product_Id__c = ele.Product2Id;
                            productInstance.PricebookEntry_Id__c = ele.Id;
                            productInstance.Lead__c = this.recordId;
                            productInstance.Product_Name__c = ele.Name;
                            productInstance.Name = ele.Name;
                            productInstance.Partner_Provision_Value__c = ele.Pricebook2.partner_provision_value__c;
                            productInstance.Partner_Sales_Value__c = ele.Pricebook2.partner_sales_value__c;
                            productInstance.Provision_Base__c = ele.Pricebook2.Provision_base__c;
                            productInstance.Quantity__c = ele.quantity;
                            productInstance.CurrencyIsoCode = ele.Pricebook2.CurrencyIsoCode;
                            productInstance.Plan_handle__c = ele.Product2.Plan__c;
                            productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;
                            LeadProducts.push(productInstance);
                        }
                    }
                });
            }
            this.leadProducts = LeadProducts;
            this.handlerChangeQuantity();
            let fullProductData = this.fullProductData;
            fullProductData.forEach(ele => {
                if (this.leadProducts[0].Pricebook_Id__c === ele.pb2.Id) {
                    this.selectedPriceBookName = ele.pb2.Name;
                    this.isleadProductComboboxdisplay = false;
                }
            });
            insertRecords_Apex({
                newProductList: this.leadProducts,
                leadId: this.recordId,
                total: this.total
            }).then(result => {
                if (result) {
                    this.isLoadedSpinner = false;
                    this.leadProducts = result;
                    this.isleadProductAvailable = true;
                    this.isShowOrderTotal = true;
                    this.handlerChangeQuantity();
                    this.changeTotalvalue_Helper();
                    this.showSuccessToast();
                    this.handlerFixedDiscountChange();
                    this.disableButton = false;
                }
                //DFJ-340 changes start
                 if(this.includeBundleDiscount){
                        this.disableButton = true;
                    }
                 //DFJ-340 changes end
                eval("$A.get('e.force:refreshView').fire()");
            })
        } catch (error) {
            console.error(error);
        }
       

    }

    /**method used for set fixeddiscounttype value in Lead */
    handlerFixedDiscountInput(event) {
        try {

            this.leadRecord.Fixed_discount_Type__c = !event.target.value ? 0 : event.target.value;
            if (event.target.value <= 0) {
                event.target.value = 0;
                this.leadRecord.Fixed_discount_Type__c = 0;
            } else {
                this.leadRecord.Fixed_discount_Type__c = event.target.value;
            }
        } catch (error) {
            console.error(error);
        }

    }

    handlerFixedDiscountChange() {
        try {
            let orderTotal = 0;
            let totalValue = this.total;
            let fixedDiscount = this.leadRecord.Fixed_discount_Type__c;
            if (totalValue <= fixedDiscount) {
                this.ordertotal = orderTotal;
            } else {
                orderTotal = parseFloat((parseFloat(totalValue).toFixed(2) - parseFloat(fixedDiscount).toFixed(2))).toFixed(2);
            }

            this.orderTotal = orderTotal;
        } catch (error) {
            console.error(error);
        }

    }

    handlerFixedDiscount() {
        //DFJ-340 Changes Start
       if(this.includeBundleDiscount){
            this.disableButton = true;
        }
        //DFJ-340 Changes end
        try {
            this.leadRecord.Id = this.recordId;

            let number = this.leadRecord.Fixed_discount_Type__c;
            if (number - Math.floor(number) > 0) {
                let sepreatednumber = number.toString().replace(".", ",");
                this.leadRecord.Fixed_discount_Type__c = sepreatednumber;
            }
            insertFixedDiscountinLead_Apex({leadRecord: this.leadRecord}).then(result => {
                if (result) {
                    this.leadRecord.Fixed_discount_Type__c = result.Fixed_discount_Type__c;

                    this.handlerFixedDiscountChange();
                    this.showSuccessToast();
                    eval("$A.get('e.force:refreshView').fire()");
                }
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
            let totalProvisionBase = 0.00;
            let totalPartnerSalesValue = 0.00;
            let totalPartnerProvisionValue = 0.00;

            let newProductList = this.leadProducts;
            newProductList.forEach(function (ele) {
                // Check if the smaller than 0 change it to 1
                ele.Quantity__c = parseInt(ele.Quantity__c);
                if (ele.Quantity__c <= 0) {
                    ele.Quantity__c = 1;
                } else if (ele.Quantity__c >= 999) {
                    ele.Quantity__c = 999;
                }


                // Description : Removing = from check so value like 0.5 could be considered
                // Start
                if (!ele.Discount__c || isNaN(ele.Discount__c) || ele.Discount__c < 0) {
                    ele.Discount__c = 0;
                } else if (ele.Discount__c >= 100) {
                    ele.Discount__c = 100;
                }
                // End

                // Changes for ticket DIN-249 : Allow fractional numbers on lead products discount.
                // Description : calculating the discount value and then parse to float.
                // Start
                let discountedValue = parseFloat((ele.Discount__c / 100) * (ele.Item_Price__c)).toFixed(2);
                //console.log('discountedValue',discountedValue);
                // End

                ele.totalPrice = parseFloat((parseFloat(ele.Item_Price__c).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * ele.Quantity__c).toFixed(2);
                totalPrice = parseFloat(totalPrice) + parseFloat(ele.totalPrice);
                /*New changes*/
                /*checking whether the partner provision value is null or undefined or Nan*/
                if (ele.Partner_Provision_Value__c || isNaN(ele.Partner_Provision_Value__c)) {
                    ele.Partner_Provision_Value__c = 0;
                }
                totalPartnerProvisionValue = parseFloat(totalPartnerProvisionValue) + parseFloat(ele.Partner_Provision_Value__c);

                /*checking whether the provision base is null or undefined or Nan*/
                if (ele.Provision_Base__c || isNaN(ele.Provision_Base__c)) {
                    ele.Provision_Base__c = 0;
                }
                totalProvisionBase = parseFloat(totalProvisionBase) + parseFloat(ele.Provision_Base__c);

                /*checking whether the partner sales value is null or undefined or Nan*/
                if (ele.Partner_Sales_Value__c || isNaN(ele.Partner_Sales_Value__c)) {
                    ele.Partner_Sales_Value__c = 0;
                }
                totalPartnerSalesValue = parseFloat(totalPartnerSalesValue) + parseFloat(ele.Partner_Sales_Value__c);

            });

            let totalValues = {};
            totalValues.totalProvisionBase = totalProvisionBase;
            totalValues.totalPartnerSalesValue = totalPartnerSalesValue;
            totalValues.totalPartnerProvisionValue = totalPartnerProvisionValue;
            this.totalValues = totalValues;
            this.total = totalPrice.toFixed(2);
            this.leadProducts = newProductList;
        } catch (ex) {
            console.info("Error:-->" + ex.message);
        }
    }

    changeTotalvalue_Helper() {
        changeTotalSalesValue_Apex({leadId: this.recordId, total: this.total}).then(result => {
            if (result) {
                eval("$A.get('e.force:refreshView').fire()");
            }
            eval("$A.get('e.force:refreshView').fire()");
        })
    }

    handlerRefershView() {
        this.isleadProductAvailable = false;
        this.isShowOrderTotal = false;
        this.isleadProductComboboxdisplay = true;
        this.disableButton = true;
    }


    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Updated',
            message: 'Success',
            variant: 'success',
            mode: 'pester',
        });
        this.dispatchEvent(evt);
    }

    //DFJ-340 Changes Start
    handleCalculateBundle() {
        this.callProductBundleFlow = true;
    }
    handleStatusChange(event) {
        if(event.detail.status === 'FINISHED'){
            this.callProductBundleFlow = false;
            this.getLeadProductsData();
            this.disableButton = false;
        }
    }
    refreshLeadProducts() {
            this.leadProducts.sort((a, b) => {
            const aIsPositive = a.Item_Price__c >= 0;
            const bIsPositive = b.Item_Price__c >= 0;
            if (aIsPositive && !bIsPositive) return -1;
            if (!aIsPositive && bIsPositive) return 1;
            return a.Name.localeCompare(b.Name);
        });
    }
    //DFJ-340 Changes end

}