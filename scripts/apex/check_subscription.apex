// Check if LeadProducts have subscriptions
List<LeadProducts__c> lps = [SELECT Id, Name, Item_Price__c, Quantity__c, Discount__c, Is_subscription__c, Plan_handle__c FROM LeadProducts__c WHERE Lead__c = '00QG500000Oo0AHMAZ'];
System.debug('LeadProducts count: ' + lps.size());

for(LeadProducts__c lp : lps) {
    System.debug('Product: ' + lp.Name + ' Is_subscription__c: ' + lp.Is_subscription__c + ' Plan_handle__c: ' + lp.Plan_handle__c);
}
