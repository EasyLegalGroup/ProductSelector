// Check Lead Fixed_discount_Type__c value
Lead l = [SELECT Id, Name, Fixed_discount_Type__c FROM Lead WHERE Id = '00QG500000Oo0AHMAZ'];
System.debug('Lead Name: ' + l.Name);
System.debug('Fixed_discount_Type__c: ' + l.Fixed_discount_Type__c);

// Also check LeadProducts__c
List<LeadProducts__c> lps = [SELECT Id, Name, Item_Price__c, Quantity__c, Discount__c, Sub_Total__c, Is_subscription__c FROM LeadProducts__c WHERE Lead__c = '00QG500000Oo0AHMAZ'];
System.debug('LeadProducts count: ' + lps.size());

Decimal amount = 0;
for(LeadProducts__c lp : lps) {
    Decimal lineAmount = (lp.Item_Price__c - (lp.Item_Price__c * lp.Discount__c / 100)) * lp.Quantity__c;
    amount += lineAmount;
    System.debug('Product: ' + lp.Name + ' Item_Price__c: ' + lp.Item_Price__c + ' Qty: ' + lp.Quantity__c + ' Discount: ' + lp.Discount__c + ' LineAmount: ' + lineAmount);
}
System.debug('Calculated total amount: ' + amount);

// Now simulate the calculation in createPaymentAndOrderItems
Decimal fixedDiscount = l.Fixed_discount_Type__c != null ? l.Fixed_discount_Type__c : 0;
System.debug('Fixed Discount: ' + fixedDiscount);
System.debug('Condition: fixedDiscount <= amount? ' + (fixedDiscount <= amount));

Decimal finalAmount;
if (fixedDiscount <= amount) {
    finalAmount = amount - fixedDiscount;
} else if (l.Fixed_discount_Type__c == null) {
    finalAmount = amount;
} else {
    finalAmount = 0;
}
System.debug('Final Amount that would be set: ' + finalAmount);
