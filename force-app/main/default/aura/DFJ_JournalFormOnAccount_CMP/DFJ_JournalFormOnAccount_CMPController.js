({
   /* doInit: function(c, e, h ){
      
       let recordId = c.get("v.recordId");
       let sObjectName = c.get("v.sObjectName");
     
    },*/

    showJournalForm: function(c,e,h){
        c.set("v.isAddedConfirmationModalOpen", true);
        //Changes starts DFJ-77
        let recordId = c.get("v.recordId");

        // Call the Apex method to get related contacts
        let action = c.get("c.ordersAssociatedWithAccount");
        action.setParams({ recordId: recordId });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                c.set("v.relatedOrders", response.getReturnValue());
            } else if (state === "ERROR") {
                // Handle error, display an error message, etc.
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
      //  console.log('action-->'+action);
        //End
        //h.showJournalForm_helper(c,e,h);
    },

    closeModal: function(c,e,h){
        c.set("v.isAddedConfirmationModalOpen", false);
    },

    addedNewJournalButtonClicked : function(c,e,h){
        c.set("v.isAddedConfirmationModalOpen", false);
        h.showJournalForm_helper(c,e,h);
    },
    
    //Changes DFJ-77 Starts
    handleValuePassed: function(component, event, helper) {
        // Retrieve the value from the event
        
        let getorderid = event.getSource().get("v.value");
        component.set("v.orderId", getorderid);
		//console.log('c.set("v.orderId",getorderid); ' + component.get("v.orderId"));
        // Use the passed value as needed
       // console.log('Passed Value: ' + getorderid);
    }
    //End
})