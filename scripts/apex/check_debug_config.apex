System.debug('User ID: ' + UserInfo.getUserId());
Debug_log_Configuration__mdt config = Debug_log_Configuration__mdt.getInstance('Turn_Debug_On');
System.debug('User_Id_s__c: ' + config.User_Id_s__c);
System.debug('Current user in list: ' + config.User_Id_s__c.contains(UserInfo.getUserId()));
