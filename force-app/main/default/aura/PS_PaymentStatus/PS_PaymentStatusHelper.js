({
    doInit_Helper : function(c, e, h) {
        let action = c.get("c.getPaymentRecordsForStatus");
        action.setParams({ 'recordId': c.get("v.recordId") });
        action.setCallback(this, function(response) {
            let state = response.getState();
            // Changed the result
            let result = response.getReturnValue();
            if (state === 'SUCCESS') {
                if (result && result.successMessage) {
                    c.set("v.payments",result.paymentList);
                    if (result.paymentList && result.paymentList.length > 0) {
                        c.set("v.isPaymentRecordPresnt",true);
                        result.paymentList.forEach(function(ele){
                            if (ele.Status__c) {
                                let statusClass = h.setStatusClasses(c,e,h,{"Status__c":ele.Status__c});
                                ele.statusClass = statusClass;
                            }
                        });
                        c.set("v.payments",result.paymentList);
                        // h.handlerMessageChannel_Helper(c,e,h);
                        c.set("v.showCreatePaymentButton",false);
                        let paymentList = c.get('v.payments');
                        // if(paymentList.length > 0){
                        h.handlerMessageChannel_Helper(c,e,h);
                        
                    }else if(result.paymentList){
                        c.set("v.payments",[]);
                        c.set("v.isPaymentRecordPresnt",false);
                        c.set("v.showCreatePaymentButton",true);
                    }
                }else if(result && result.errorMessage){
                    h.showToast(c,e,h,result.errorMessage,'Error');
                    h.debug_helper(c, e, h, "Loading compoenent" ,"User id : "+ c.get("v.currentUserId") + result.errorMessage, 'doinit helper PS_PaymentStatusHelper','Error');
                }
            } else {
                let errors = result.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.info('Error message' + errors[0].message);
                    }
                    h.showToast(c,e,h,errors[0].message,'Error');
                    h.debug_helper(c, e, h, " Loading compoenent" ,"User id : "+ c.get("v.currentUserId") + errors[0].message, 'doinit helper PS_PaymentStatusHelper','Error');
                }
            }
            c.set("v.logEnabledUserIds",result.logEnabledUserIds);
        });
        $A.enqueueAction(action);
    },

    getEventsFromCDC: function(c, e, h, data) {
        
        try {
            // Get the empApi component.
            let empApi = c.find("empApi");

            let channel = '/data/Payments__ChangeEvent';

            let replayId = '-1';

            // Callback function to be passed in the subscribe call.
            // After an event is received, this callback prints the event
            // payload to the console.
            let callback = function(message) {
                h.debug_helper(c, e, h,"received message CDCevent" ,"Userid: "+ c.get("v.currentUserId") + JSON.stringify(message), 'getEventsFromCDC PS_PaymentStatusHelper','Info');
                let changeType = message.data.payload.ChangeEventHeader.changeType;
                let payload = message.data.payload;
                let changedFields = message.data.payload.ChangeEventHeader.changedFields;
                let recordIds = message.data.payload.ChangeEventHeader.recordIds;
                let payments = c.get("v.payments");
                try {                
                if (changeType && (changeType === 'CREATE' || changeType === 'UPDATE')) {
                    if (changeType === 'CREATE') {
                        if ((payload.Lead__c && payload.Lead__c === c.get("v.recordId")) || (payload.Order__c && payload.Order__c === c.get("v.recordId"))) {
                            let paymentInstance = {};
                            for (const item in payload) {
                                if (item !== "ChangeEventHeader") {
                                    paymentInstance[item] = payload[item];
                                }
                            }
                            paymentInstance.Id = recordIds[0];
                            let statusClass = h.setStatusClasses(c,e,h,payload);
                            paymentInstance.statusClass = statusClass;
                            payments.push(paymentInstance);
                        }
                        c.set("v.isPaymentRecordPresnt",true);
                        c.set("v.showCreatePaymentButton",false);
                        c.set("v.payments",payments);
                    } else if (changeType === 'UPDATE') {
                        payments.forEach(function(ele){
                            if (ele.Id === recordIds[0]) {
                                changedFields.forEach(function(changedField){
                                    ele[changedField] = payload[changedField];
                                });
                                if (changedFields.includes('Status__c')) {
                                    let statusClass = h.setStatusClasses(c,e,h,payload);
                                    ele.statusClass = statusClass;
                                }
                            }
                        });
                        c.set("v.payments",payments);
                        if(payments && payments.length > 0){
                            if(payments[0].Status__c === 'Refunded'){
                                h.handlerMessageChannel_Helper(c,e,h);
                                h.doInit_Helper(c,e,h);
                            }
                        }

                    }
                } else if (changeType === 'DELETE') {
                    let filteredPayments = payments.filter(ele => recordIds[0] !== ele.Id);
                    if (filteredPayments && filteredPayments.length) {
                        payments = filteredPayments;
                    } else{
                        payments = [];
                        c.set("v.showCreatePaymentButton",true);
                    }
                    c.set("v.payments",payments);
                }
                let paymentList = c.get('v.payments');
                if(paymentList.length > 0 && paymentList[0].Status__c == 'Pending'){
                    h.handlerMessageChannel_Helper(c,e,h);
                }
            } catch (error) {
                h.debug_helper(c, e, h,"received error CDCevent" ,"Userid: "+ c.get("v.currentUserId") + error, 'getEventsFromCDC PS_PaymentStatusHelper','Error');
            }
            }.bind(this);

            // Error handler function that prints the error to the console.
            var errorHandler = function(message) {
                console.log("Received error ", JSON.stringify(message));
                let currentUserId = c.get("v.currentUserId");
                h.debug_helper(c, e, h, "received error" ,"Userid: "+currentUserId +  JSON.stringify(message), 'getEventsFromCDC PS_PaymentStatusHelper','Error');
            }.bind(this);

            // Register error listener and pass in the error handler function.
            empApi.onError(errorHandler);

            // Subscribe to the channel and save the returned subscription object.
            empApi.subscribe(channel, replayId, callback).then(function(value) {
                c.set('v.isChannelSubscribed', true);
                console.log("Subscribed to channel " + channel);
                c.set('v.subscription', value);
            });
        } catch (ex) {
            h.debug_helper(c, e, h,"Exception in CDC." ,"Userid: "+ c.get("v.currentUserId") + JSON.stringify(ex), 'getEventsFromCDC PS_PaymentStatusHelper','Error');
        }
    },

    setStatusClasses : function(c,e,h,payload){
        let statusClass = '';
        if (payload.Status__c.toLowerCase() === "created" || payload.Status__c.toLowerCase() === "pending") {// orange
            statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorOrange";
        } else if (payload.Status__c.toLowerCase() === "authorized") {// blue
            statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorBlue";
        } else if (payload.Status__c.toLowerCase() === "settled") {// green
            statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorGreen";
        } else if (payload.Status__c.toLowerCase() === "failed" || payload.Status__c.toLowerCase() === "cancelled") {
            statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorRed";
        } else if (payload.Status__c.toLowerCase() === "dunning") {
            statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorGray";
        }else if (payload.Status__c.toLowerCase() === "refunded") {
            statusClass = "slds-p-around_small slds-m-top_medium slds-align_absolute-center slds-text-heading_small slds-theme_success borderRadius statusColorBlue";
        }
        return statusClass;
    },

    // Invokes the unsubscribe method on the empApi component
    handleDestroy_Helper: function(c, e, h) {
        const empApi = c.find('empApi');
        const subscription = c.get('v.subscription');

        empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
            console.log('Unsubscribed from channel ' + unsubscribed.subscription);
            c.set('v.subscription', null);
        }));
    },

    showToast: function(c, e, h, message, title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            messageTemplate: message,
            duration: '5000',
            type: title
        });
        toastEvent.fire();
    },

    debug_helper: function(c, e, h, event, message, source, logInfo) {
        let logEnabledUserIds = c.get("v.logEnabledUserIds");
        let currentUserId = c.get("v.currentUserId");
        if (logEnabledUserIds && logEnabledUserIds.includes(currentUserId)) {        
            let action = c.get("c.handleCompoentDebugLogs");
            action.setParams({ 'event': event,'message': message ,'severity':logInfo,'source': source});
            action.setCallback(this, function(response) {
                let state = response.getState();
                let result = response.getReturnValue();
            });
            $A.enqueueAction(action);
        }
    },

    refreshPaymentStatus_Helper: function(c, e, h) {
        //c.set("v.showSpinner",true);

        let action = c.get("c.getPaymentRecordsForStatus");
        action.setParams({ 'recordId': c.get("v.recordId") });
        action.setCallback(this, function(response) {
            let state = response.getState();
            // Changed the result
            let result = response.getReturnValue();
            if (state === 'SUCCESS') {
                if (result && result.successMessage) {
                    // c.set("v.payments",result.paymentList);
                    if (result.paymentList && result.paymentList.length > 0) {
                        c.set("v.isPaymentRecordPresnt",true);
                        result.paymentList.forEach(function(ele){
                            if (ele.Status__c) {
                                let statusClass = h.setStatusClasses(c,e,h,{"Status__c":ele.Status__c});
                                ele.statusClass = statusClass;
                            }
                        });
                        c.set("v.payments",result.paymentList);

                        //Chnages DIN-330
                        //Start
                        c.set("v.showCreatePaymentButton",false);
                    }else if(result.paymentList){
                        c.set("v.payments",[]);
                        c.set("v.showCreatePaymentButton",true);
                    }
                    //End
                    let paymentList = c.get('v.payments');

                    if(paymentList.length > 0 && paymentList[0].Status__c == 'Pending'){
                        h.handlerMessageChannel_Helper(c,e,h);
                    }
                }else if(result && result.errorMessage){
                    h.debug_helper(c, e, h, "Loading compoenent refresh button " ,"User id : "+ c.get("v.currentUserId") + result.errorMessage, 'doinit helper refreshPaymentStatus_Helper','Error');
                }
            } else {
                let errors = result.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.info('Error message' + errors[0].message);
                    }
                    h.debug_helper(c, e, h, " Loading compoenent refresh button" ,"User id : "+ c.get("v.currentUserId") + errors[0].message, 'doinit helper refreshPaymentStatus_Helper','Error');
                }
            }
            //c.set("v.showSpinner",false);
        });
        $A.enqueueAction(action);
        
    },

    // DIN-344 changes
    cancelInvoiceSubscription_Helper :function(c, e, h) {
        
        const recordIdToCancel = c.get("v.payments")[0].Id;
        // console.log('recordIdToCancel >>> '+recordIdToCancel);

        let action = c.get("c.cancelPayment");
        action.setParams({ 'recordId': c.get("v.recordId"), 'paymentRecordId': recordIdToCancel});
        action.setCallback(this, function(response) {
            let state = response.getState();
            let result = response.getReturnValue();

            if (state === 'SUCCESS') {
                //console.log(result);
                if (result.includes('Success')) {
                    c.set('v.payments',[]);
                    h.showToast(c,e,h,result,'Success');
                    h.doInit_Helper(c,e,h);
                    h.handlerMessageChannel_Helper(c,e,h);

                }else{
                    h.showToast(c,e,h,result,'Error');
                }
            } else {
                let errors = result.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.info('Error message' + errors[0].message);
                    }
                    h.showToast(c,e,h,errors[0].message,'Error');
                }
            }
            c.set("v.showSpinner",false);
            c.set("v.isCancelConfirmationModalOpen",false);
        });
        $A.enqueueAction(action);
    },

    handlerMessageChannel_Helper: function(c,e,h){
        try {
            let paymentList = c.get('v.payments');
            //console.log('PaymentList>>>>>'+JSON.stringify(paymentList));
            let payload = {};
            if(paymentList.length > 0){
                 if(paymentList[0].Status__c === 'Pending'){
                    //console.log('Pending');
                    payload = {
                        recordId : paymentList[0].Id,
                        leadId : paymentList[0].Lead__c,
                        orderId : paymentList[0].Order__c,
                        source : "PS_PaymentStatus",
                        disableButton: true,
                    };
                    c.find("sampleMessageChannel").publish(payload);
                }else if(paymentList[0].Status__c === 'Refunded'){
                    //console.log('Refunded');
                    payload = {
                        recordId : paymentList[0].Id,
                        leadId : paymentList[0].Lead__c,
                        orderId : paymentList[0].Order__c,
                        source : "PS_PaymentStatus",
                        disableButton: false,
                    };
                    c.find("sampleMessageChannel").publish(payload);
                }
            }else {
                payload = {
                    recordId : '',
                    leadId : '',
                    orderId : '',
                    source : "PS_PaymentStatus",
                    disableButton: false,
                };
                c.find("sampleMessageChannel").publish(payload);
            } 
        } catch (error) {
            console.error(error);
        }
        
    }
})