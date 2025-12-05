// Re-create the deleted customer in test Reepay account
Price_Book__mdt pbConfig = [SELECT Encoded_Private_Key__c, Test_Encoded_Private_Key__c, Internal_Identifier__c 
                            FROM Price_Book__mdt 
                            WHERE Internal_Identifier__c = 'Din_Familiejurist' LIMIT 1];

// Create new customer with same handle to "undelete"
HttpRequest createReq = new HttpRequest();
createReq.setEndpoint('https://api.reepay.com/v1/customer');
createReq.setMethod('POST');
createReq.setHeader('Authorization', 'Basic ' + pbConfig.Test_Encoded_Private_Key__c);
createReq.setHeader('Accept', 'application/json');
createReq.setHeader('Content-Type', 'application/json');
createReq.setTimeout(120000);

// Create customer request body - this should reactivate the deleted customer
String customerBody = '{"handle":"awd98hawd@awd98hanwawdawd.com","email":"awd98hawd@awd98hanwawdawd.com","first_name":"Mathias","last_name":"Demo Demo2","test":true}';
createReq.setBody(customerBody);

Http http = new Http();
HttpResponse createResp = http.send(createReq);
System.debug('CREATE/REACTIVATE Customer Status: ' + createResp.getStatusCode());
System.debug('CREATE/REACTIVATE Customer Response: ' + createResp.getBody());
