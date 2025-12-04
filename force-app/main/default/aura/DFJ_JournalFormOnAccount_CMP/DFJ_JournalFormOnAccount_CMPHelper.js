({
    doInit_Helper: function(c, e, h) {
        try {
        //Changes DFJ-77 Starts
        let relateOrderId = c.get("v.orderId");
        //console.log('relateOrderId-->'+relateOrderId);
        //End
        let recordId = c.get("v.recordId");
        let Objectname = c.get("v.sObjectName");
        c.set("v.isSpinnerOpen", true);
        c.set("v.closeModal", true);
            
        let action = c.get("c.journalAssociatedWithAccount");
            action.setParams({
                "recordId": recordId,
                //Changes DFJ-77 Starts
                "orderId": relateOrderId,
                //End
                // New parameter for two-tier selection (empty for legacy Aura component)
                "recordModelId": ""

            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse != null && storedResponse != undefined && storedResponse != '') {
                      
                        c.set("v.journalId", storedResponse[0].Id);
                        h.getJournalDetailsToOpenDocfab(c, e, h, Objectname);
                    }
                    $A.get('e.force:refreshView').fire();
                } else if (response.getState() === 'ERROR') {
                    //h.showErrorToast(c,e,h);
                    console.error("Error occurred");
                    h.sendErrorLogsToApex_Helper(c, e, h, c.get("v.recordId"), JSON.stringify(response.getError()), 'ERROR', 'DFJ_JournalForm', 'leadObject_helper');
                } else {
                    h.sendErrorLogsToApex_Helper(c, e, h, c.get("v.recordId"), JSON.stringify(response.getError()), 'ERROR', 'DFJ_JournalForm', 'leadObject_helper');
                    console.error("Error");
                    console.log(response.getError());
                }
            });
            $A.enqueueAction(action);
        } catch (ex) {
            h.sendErrorLogsToApex_Helper(c, e, h, c.get("v.recordId"), JSON.stringify(ex.message), 'ERROR', 'DFJ_JournalForm', 'leadObject_helper');
            console.error("Error" + ex.message);
        }
    },

    showJournalForm_helper: function(c, e, h) {
        c.set("v.isOpenJournalFormClicked", true);
        h.doInit_Helper(c,e,h);
        
    },


     // Send error to Salesforce log object to catch if anything happens in the lightning components.
     sendErrorLogsToApex_Helper: function(c, e, h, recordId, exceptionMessage, severity, source, event) {
        try {
            let errorObjectInstance = c.get("v.errorLog");
            errorObjectInstance.Affected_record__c = recordId;
            errorObjectInstance.Message__c = exceptionMessage;
            errorObjectInstance.Severity__c = severity;
            errorObjectInstance.Source__c = source;
            errorObjectInstance.Event__c = event;


            let action = c.get("c.addErrorLogsInSalesforce_Apex");
            action.setParams({
                "logData": JSON.stringify(errorObjectInstance)
            });
            action.setCallback(this, function(r) {
                if (r.getState() === 'SUCCESS') {
                    let storedResponse = r.getReturnValue();
                    if (storedResponse != null) {
                        h.showErrorToast(c, e, h, storedResponse.substring(storedResponse.indexOf("message") + 10, 106));
                    }

                }
            });
            $A.enqueueAction(action);
        } catch (ex) {
            console.error('Error--' + ex);
        }
    },


    getJournalDetailsToOpenDocfab : function(c,e,h,Objectname){
        let isOpenJournalFormClicked = c.get("v.isOpenJournalFormClicked");
            let action = c.get("c.getJournalData_Apex");
            action.setParams({
                'JournalId': c.get("v.journalId"),
                'objectName': Objectname,
                'leadId': '',
                'journlaFormClicked': isOpenJournalFormClicked
            });
            action.setCallback(this, function(r) {
                if (r.getState() === 'SUCCESS') {
                    let storedResponse = r.getReturnValue();
                    if (storedResponse && Object.keys(storedResponse).length > 0) {
                        c.set("v.isSpinnerOpen", false);
                        // Changes for ticket - DIN-169 : Open record content in form.
                        // Start
                        // Description : checking for the url in docFabUrl property.

                        if (isOpenJournalFormClicked) {
                            let docFabUrl = storedResponse.docFabUrl;
                           
                            if (docFabUrl) {
                                if (docFabUrl.includes("Current user with") || docFabUrl.includes("No form configuration found") || docFabUrl.includes("Can not open") || docFabUrl.includes("Can not create") || docFabUrl.includes("Error")) {
                                    // h.showErrorToast(c, e, h, docFabUrl);
                                    // Changes for ticket DIN-254 : Add "OK" button to docfab error toast and include status message from api service
                                    // Start
                                    let toastEvent = $A.get("e.force:showToast");
                                    toastEvent.setParams({
                                        title: 'Error Message',
                                        mode: 'sticky',
                                        message: docFabUrl,
                                        messageTemplate: docFabUrl,
                                        type: 'error',
                                        key: 'info_alt',
                                        duration: ' 5000',
                                    });
                                    toastEvent.fire();
                                    // End
                                } else {
                                    c.set("v.docFabFormUrl", storedResponse.docFabUrl);
                                    c.set("v.openDocFabForm", true);
                                }
                                c.set("v.closeModal", false);

                            }
                        }
                    }
                }
            })
        $A.enqueueAction(action);
    },
    

})