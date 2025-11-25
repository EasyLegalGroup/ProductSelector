({
    doInit : function(c, e, h) {
        c.set("v.currentUserId", $A.get("$SObjectType.CurrentUser.Id"));
        h.doInit_Helper(c, e, h);
        //h.getEventsFromCDC(c,e,h);
    },

    handleDestroy: function(c, e, h) {
        h.handleDestroy_Helper(c, e, h);
    },

    refreshPaymentStatus :function(c, e, h) {
        h.refreshPaymentStatus_Helper(c, e, h);
    },

    // DIN-344 changes
    cancelInvoiceSubscription :function(c, e, h) {
        c.set("v.isCancelConfirmationModalOpen",true);
        //h.cancelInvoiceSubscription_Helper(c, e, h);
    },

    cancelPaymentWhenButtonClicked :function(c, e, h) {
        h.cancelInvoiceSubscription_Helper(c, e, h);
    },

    closeCancelModal :function(c, e, h) {
        c.set("v.isCancelConfirmationModalOpen",false);
    },
})