// Reset Lead Fixed_discount_Type__c to 0 so payments can be created
Lead l = [SELECT Id, Name, Fixed_discount_Type__c FROM Lead WHERE Id = '00QG500000Oo0AHMAZ'];
System.debug('Before: Fixed_discount_Type__c = ' + l.Fixed_discount_Type__c);
l.Fixed_discount_Type__c = 0;
update l;
System.debug('After: Fixed_discount_Type__c = ' + l.Fixed_discount_Type__c);
System.debug('Lead discount reset successfully!');
