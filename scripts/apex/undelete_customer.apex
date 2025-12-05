// Try to update the deleted customer to undelete them
Price_Book__mdt pbConfig = [SELECT Encoded_Private_Key__c, Test_Encoded_Private_Key__c, Internal_Identifier__c 
                            FROM Price_Book__mdt 
                            WHERE Internal_Identifier__c = 'Din_Familiejurist' LIMIT 1];

// Try PUT to update/reactivate customer
HttpRequest updateReq = new HttpRequest();
updateReq.setEndpoint('https://api.reepay.com/v1/customer/awd98hawd@awd98hanwawdawd.com');
updateReq.setMethod('PUT');
updateReq.setHeader('Authorization', 'Basic ' + pbConfig.Test_Encoded_Private_Key__c);
updateReq.setHeader('Accept', 'application/json');
updateReq.setHeader('Content-Type', 'application/json');
updateReq.setTimeout(120000);

// Update body
String updateBody = '{"email":"awd98hawd@awd98hanwawdawd.com","first_name":"Mathias","last_name":"Demo Demo2"}';
updateReq.setBody(updateBody);

Http http = new Http();
HttpResponse updateResp = http.send(updateReq);
System.debug('UPDATE Customer Status: ' + updateResp.getStatusCode());
System.debug('UPDATE Customer Response: ' + updateResp.getBody());

// If update doesn't work, let's change the Lead email to something new for testing
if (updateResp.getStatusCode() != 200) {
    System.debug('Customer update did not work. Consider changing the Lead email to a new address for testing.');
}
